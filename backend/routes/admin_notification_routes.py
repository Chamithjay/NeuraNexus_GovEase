from fastapi import APIRouter
from services.notification_service import send_notification

router = APIRouter(prefix="/admin/notification", tags=["Admin Notification"])

@router.post("/")
def notify(clinic_id: str, message: str):
    return send_notification(clinic_id, message)