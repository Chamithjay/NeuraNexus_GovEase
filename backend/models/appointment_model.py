from pydantic import BaseModel
from datetime import datetime

class AppointmentModel(BaseModel):
    clinic_id: str
    user_id: str
    token_number: int
    status: str
    created_at: datetime
