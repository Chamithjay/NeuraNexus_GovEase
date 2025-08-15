from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class Grade1Admission(BaseModel):
    reference_number: str
    child_full_name: str
    date_of_birth: str  # Keep as string unless you want datetime validation
    parent_name: str
    guardian_nic: str
    contact_number: str
    school_name: str
    uploaded_files: Optional[List[str]] = None
    status: str = "submitted"
    created_at: Optional[datetime] = None

    class Config:
        orm_mode = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
