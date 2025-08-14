from fastapi import APIRouter, Depends, HTTPException

from database import get_database
from models.transfer_request import TransferRequestCreate, TransferRequestResponse, RequestStatus
from services.transfer_request_service import TransferRequestService
from services.transfer_match_service import TransferMatchService
from models.transfer_match import TransferMatchResponse
from services.citizen_notification_service import CitizenNotificationService
from models.citizen_notification import NotificationType
from services.citizen_service import CitizenService
from services.teacher_service import TeacherService
from realtime.websocket_manager import manager
from services.admin_service import AdminService
from config import SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, SMTP_FROM
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

router = APIRouter(prefix="/api/transfer-requests", tags=["Transfer Requests"])


async def get_transfer_service():
    db = await get_database()
    return TransferRequestService(db)


async def get_teacher_service():
    db = await get_database()
    return TeacherService(db)


async def get_match_service():
    db = await get_database()
    return TransferMatchService(db)


async def get_notification_service():
    db = await get_database()
    return CitizenNotificationService(db)


async def get_citizen_service_dep():
    db = await get_database()
    return CitizenService(db)


@router.post("/", response_model=TransferRequestResponse, status_code=201)
async def create_transfer_request(
    payload: TransferRequestCreate,
    service: TransferRequestService = Depends(get_transfer_service),
):
    try:
        return await service.create_request(payload)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to create transfer request")


@router.get("/match/{request_id}")
async def check_match(
    request_id: str,
    t_service: TransferRequestService = Depends(get_transfer_service),
    teacher_service: TeacherService = Depends(get_teacher_service),
    match_service: TransferMatchService = Depends(get_match_service),
    notify: CitizenNotificationService = Depends(get_notification_service),
    citizen_service: CitizenService = Depends(get_citizen_service_dep),
):
    """Given a request_id, try to find an exact match in the opposite direction with same subjects."""
    req = await t_service.get_by_request_id(request_id)
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")

    # Get subjects for the current teacher
    teacher = await teacher_service.get_teacher_by_id(req.teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found for request")

    match = await t_service.find_exact_match(
        from_district=req.from_district,
        to_district=req.to_district,
        subjects=teacher.subjects,
    )
    if match:
        # ensure JSON serializable response and include limited teacher details (no teacher_id exposure)
        public = await t_service.get_teacher_public_details(match["teacher_id"])
        # create/get a TransferMatch record for this pair
        tm = await match_service.get_or_create(request_id, match["request_id"])
        # Notify both linked citizens that a match is found
        try:
            # current requester citizen (the one who just made the request - gets actionable notification)
            citizen_curr = await citizen_service.get_citizen_by_teacher_id(req.teacher_id)
            if citizen_curr:
                await notify.create(
                    citizen_curr.citizen_id,
                    NotificationType.TRANSFER,
                    f"Transfer match found pairing with request {match['request_id']}. Open to agree/disagree.",
                    matching_id=tm.matching_id,
                    request_id=request_id,
                )
            # matched requester citizen (the one who made the original request - gets informational notification)
            citizen_other = await citizen_service.get_citizen_by_teacher_id(match["teacher_id"])
            if citizen_other:
                await notify.create(
                    citizen_other.citizen_id,
                    NotificationType.GENERAL,
                    f"Transfer match found for your request {match['request_id']}. Waiting for the other party to respond.",
                    matching_id=tm.matching_id,
                    request_id=match["request_id"],
                )
        except Exception:
            pass
        return {
            "matched": True,
            "match_request": TransferRequestResponse.from_mongo(match),
            "matched_teacher": public,
            "transfer_match": tm,
        }
    return {"matched": False}


@router.post("/{request_id}/waiting-list")
async def add_to_waiting_list(
    request_id: str,
    service: TransferRequestService = Depends(get_transfer_service),
):
    ok = await service.update_status(request_id, RequestStatus.WAITING_LIST)
    if not ok:
        raise HTTPException(status_code=404, detail="Request not found")
    return {"message": "Added to waiting list", "request_id": request_id}


@router.get("/teacher/{teacher_id}", response_model=list[TransferRequestResponse])
async def list_requests_for_teacher(
    teacher_id: str,
    service: TransferRequestService = Depends(get_transfer_service),
):
    return await service.list_by_teacher(teacher_id)


@router.post("/match/{matching_id}/agree")
async def agree_transfer(
    matching_id: str,
    request_id: str,
    match_service: TransferMatchService = Depends(get_match_service),
    t_service: TransferRequestService = Depends(get_transfer_service),
    teacher_service: TeacherService = Depends(get_teacher_service),
    notify: CitizenNotificationService = Depends(get_notification_service),
    citizen_service: CitizenService = Depends(get_citizen_service_dep),
):
    tm = await match_service.agree(matching_id, request_id)
    if not tm:
        raise HTTPException(status_code=404, detail="Match not found or request not part of match")
    # Notify: on intermediate agreement notify only the non-acting party; on final AGREED notify both
    try:
        reqA = await t_service.get_by_request_id(tm.request_a_id)
        reqB = await t_service.get_by_request_id(tm.request_b_id)
        citizenA = await citizen_service.get_citizen_by_teacher_id(reqA.teacher_id) if reqA else None
        citizenB = await citizen_service.get_citizen_by_teacher_id(reqB.teacher_id) if reqB else None
        actor_is_a = request_id == tm.request_a_id
        # Final state: both agreed
        if tm.match_status == "AGREED":
            if citizenA:
                await notify.create(citizenA.citizen_id, NotificationType.GENERAL, f"Transfer match {matching_id} is AGREED. Processing will begin soon.", matching_id=matching_id, request_id=tm.request_a_id)
            if citizenB:
                await notify.create(citizenB.citizen_id, NotificationType.GENERAL, f"Transfer match {matching_id} is AGREED. Processing will begin soon.", matching_id=matching_id, request_id=tm.request_b_id)
        else:
            # One-sided agree reached (e.g., PENDING-AGREED): notify only the other party
            if actor_is_a:
                if citizenB:
                    await notify.create(citizenB.citizen_id, NotificationType.TRANSFER, f"Counterparty agreed to transfer match {matching_id}. Please review.", matching_id=matching_id, request_id=tm.request_b_id)
            else:
                if citizenA:
                    await notify.create(citizenA.citizen_id, NotificationType.TRANSFER, f"Counterparty agreed to transfer match {matching_id}. Please review.", matching_id=matching_id, request_id=tm.request_a_id)
    except Exception:
        # Notifications are best-effort; ignore failures for now
        pass
    # If both agreed, email zonal admins for both districts
    try:
        if tm.match_status == "AGREED" and SMTP_USERNAME and SMTP_PASSWORD:
            reqA = await t_service.get_by_request_id(tm.request_a_id)
            reqB = await t_service.get_by_request_id(tm.request_b_id)
            teacherA = await teacher_service.get_teacher_by_id(reqA.teacher_id) if reqA else None
            teacherB = await teacher_service.get_teacher_by_id(reqB.teacher_id) if reqB else None
            zones: set[str] = set()
            if teacherA and teacherA.current_district:
                zones.add(teacherA.current_district)
            if teacherB and teacherB.current_district:
                zones.add(teacherB.current_district)
            admin_service = AdminService(await get_database())
            for zone in zones:
                zonals = await admin_service.get_zonal_admins_for_zone(zone)
                if not zonals:
                    continue
                details = []
                if teacherA:
                    details.append(f"Teacher A: {teacherA.teacher_name} ({teacherA.teacher_id})\nDistrict: {teacherA.current_district}\nSubjects: {', '.join(teacherA.subjects)}\nYears in district: {teacherA.years_in_service_district}\nSchool ID: {teacherA.school_id}")
                if teacherB:
                    details.append(f"Teacher B: {teacherB.teacher_name} ({teacherB.teacher_id})\nDistrict: {teacherB.current_district}\nSubjects: {', '.join(teacherB.subjects)}\nYears in district: {teacherB.years_in_service_district}\nSchool ID: {teacherB.school_id}")
                body = "\n\n".join(details) + f"\n\nMatching ID: {tm.matching_id}"
                subject = f"GovEase - Transfer Match AGREED ({tm.matching_id})"
                for admin in zonals:
                    try:
                        msg = MIMEMultipart()
                        msg["From"] = SMTP_FROM or SMTP_USERNAME
                        msg["To"] = admin.admin_email
                        msg["Subject"] = subject
                        msg.attach(MIMEText(body, "plain"))
                        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
                            server.starttls()
                            server.login(SMTP_USERNAME, SMTP_PASSWORD)
                            server.sendmail(SMTP_FROM or SMTP_USERNAME, [admin.admin_email], msg.as_string())
                    except Exception:
                        continue
    except Exception:
        pass
    return tm


@router.post("/match/{matching_id}/disagree")
async def disagree_transfer(
    matching_id: str,
    request_id: str,
    match_service: TransferMatchService = Depends(get_match_service),
    t_service: TransferRequestService = Depends(get_transfer_service),
    notify: CitizenNotificationService = Depends(get_notification_service),
    citizen_service: CitizenService = Depends(get_citizen_service_dep),
):
    tm = await match_service.disagree(matching_id, request_id)
    if not tm:
        raise HTTPException(status_code=404, detail="Match not found or request not part of match")
    try:
        reqA = await t_service.get_by_request_id(tm.request_a_id)
        reqB = await t_service.get_by_request_id(tm.request_b_id)
        citizenA = await citizen_service.get_citizen_by_teacher_id(reqA.teacher_id) if reqA else None
        citizenB = await citizen_service.get_citizen_by_teacher_id(reqB.teacher_id) if reqB else None
        actor_is_a = request_id == tm.request_a_id
        # Notify only the counterparty that a disagreement occurred and match reset
        if actor_is_a:
            if citizenB:
                await notify.create(citizenB.citizen_id, NotificationType.TRANSFER, f"Counterparty disagreed. Transfer match {matching_id} reset to PENDING.", matching_id=matching_id, request_id=tm.request_b_id)
        else:
            if citizenA:
                await notify.create(citizenA.citizen_id, NotificationType.TRANSFER, f"Counterparty disagreed. Transfer match {matching_id} reset to PENDING.", matching_id=matching_id, request_id=tm.request_a_id)
    except Exception:
        pass
    return tm


@router.delete("/{request_id}")
async def cancel_transfer_request(
    request_id: str,
    t_service: TransferRequestService = Depends(get_transfer_service),
    match_service: TransferMatchService = Depends(get_match_service),
    notify: CitizenNotificationService = Depends(get_notification_service),
    citizen_service: CitizenService = Depends(get_citizen_service_dep),
):
    """Cancel a transfer request and clean up any associated matches"""
    req = await t_service.get_by_request_id(request_id)
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    
    # Check if request is part of any match and clean up
    try:
        # Find matches involving this request
        matches_col = (await get_database())["transfer_matches"]
        matches = await matches_col.find({
            "$or": [
                {"request_a_id": request_id},
                {"request_b_id": request_id}
            ]
        }).to_list(None)
        
        for match in matches:
            # Notify the other party if match exists
            other_request_id = match["request_b_id"] if match["request_a_id"] == request_id else match["request_a_id"]
            other_req = await t_service.get_by_request_id(other_request_id)
            if other_req:
                citizen = await citizen_service.get_citizen_by_teacher_id(other_req.teacher_id)
                if citizen:
                    await notify.create(
                        citizen.citizen_id,
                        NotificationType.GENERAL,
                        f"Transfer match {match['matching_id']} was cancelled because the other party withdrew their request.",
                        matching_id=match["matching_id"],
                        request_id=other_request_id
                    )
            
            # Delete the match
            await matches_col.delete_one({"_id": match["_id"]})
    except Exception:
        pass  # Best effort cleanup
    
    # Delete the request
    success = await t_service.delete_request(request_id)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to cancel request")
    
    return {"message": "Transfer request cancelled successfully", "request_id": request_id}
