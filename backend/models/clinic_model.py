from pydantic import BaseModel
from datetime import datetime

class ClinicModel(BaseModel):
    clinic_date: datetime
    doctor: str
    hospital_name: str
    clinic_type: str
    max_tokens: int