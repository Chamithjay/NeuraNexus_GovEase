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
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to create transfer request")


@router.get("/match/{request_id}")
async def check_match(
    request_id: str,
    t_service: TransferRequestService = Depends(get_transfer_service),
    teacher_service: TeacherService = Depends(get_teacher_service),
    match_service: TransferMatchService = Depends(get_match_service),
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
    notify: CitizenNotificationService = Depends(get_notification_service),
    citizen_service: CitizenService = Depends(get_citizen_service_dep),
):
    tm = await match_service.agree(matching_id, request_id)
    if not tm:
        raise HTTPException(status_code=404, detail="Match not found or request not part of match")
    # Send notifications to both citizens (if linked)
    try:
        reqA = await t_service.get_by_request_id(tm.request_a_id)
        reqB = await t_service.get_by_request_id(tm.request_b_id)
        if reqA:
            citizenA = await citizen_service.get_citizen_by_teacher_id(reqA.teacher_id)
            if citizenA:
                await notify.create(citizenA.citizen_id, NotificationType.TRANSFER_AGREEMENT, f"Transfer match {matching_id} updated: {tm.match_status}")
        if reqB:
            citizenB = await citizen_service.get_citizen_by_teacher_id(reqB.teacher_id)
            if citizenB:
                await notify.create(citizenB.citizen_id, NotificationType.TRANSFER_AGREEMENT, f"Transfer match {matching_id} updated: {tm.match_status}")
    except Exception:
        # Notifications are best-effort; ignore failures for now
        pass
    return tm
