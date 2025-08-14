from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List

from database import get_database
from services.citizen_notification_service import CitizenNotificationService
from models.citizen_notification import CitizenNotificationResponse

router = APIRouter(prefix="/api/notifications", tags=["Citizen Notifications"])


async def get_notification_service():
    db = await get_database()
    return CitizenNotificationService(db)


@router.get("/citizen/{citizen_id}", response_model=List[CitizenNotificationResponse])
async def list_notifications_for_citizen(
    citizen_id: str,
    only_unread: bool = Query(False),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    service: CitizenNotificationService = Depends(get_notification_service),
):
    return await service.list_by_citizen(citizen_id, only_unread=only_unread, skip=skip, limit=limit)


@router.post("/citizen/{citizen_id}/read-all")
async def mark_all_read(
    citizen_id: str,
    service: CitizenNotificationService = Depends(get_notification_service),
):
    try:
        count = await service.mark_all_read(citizen_id)
        return {"updated": count}
    except Exception:
        raise HTTPException(status_code=500, detail="Failed to mark all as read")


@router.post("/citizen/{citizen_id}/read/{notification_id}")
async def mark_single_read(
    citizen_id: str,
    notification_id: str,
    service: CitizenNotificationService = Depends(get_notification_service),
):
    ok = await service.mark_read(citizen_id, notification_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"status": "ok"}
