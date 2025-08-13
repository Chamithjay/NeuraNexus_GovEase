from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class NotificationModel(BaseModel):
    id: Optional[str]
    clinic_id: str
    message: str
    sent_at: datetime
    user_id: Optional[str]