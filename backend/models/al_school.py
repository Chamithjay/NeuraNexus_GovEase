# backend/models/al_school.py
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class ALSchool(BaseModel):
    school_name: str
    province: str
    district: str
    streams: List[str]
    total_students: Optional[int]
    total_teachers: Optional[int]

class ALApplication(BaseModel):
    application_id: str
    full_name: str
    nic: str
    preferred_stream: str
    selected_school: str
    uploaded_files: List[str]
    status: str
    created_at: datetime
