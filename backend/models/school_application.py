from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from bson import ObjectId
from enum import Enum


class PyObjectId(ObjectId):
    @classmethod
    def __get_pydantic_core_schema__(cls, source_type, handler):
        return handler(str)


class ApplicationGrade(str, Enum):
    GRADE_1 = "Grade 1"
    GRADE_5 = "Grade 5"
    AL = "A/L"


class ApplicationStatus(str, Enum):
    PENDING = "Pending"
    APPROVED = "Approved"
    REJECTED = "Rejected"
    WAITING_LIST = "Waiting List"


class SchoolApplicationModel(BaseModel):
    id: Optional[PyObjectId] = Field(default_factory=PyObjectId, alias="_id")
    application_id: Optional[str] = Field(None, description="Auto-generated Application ID")
    student_name: str = Field(..., min_length=2, max_length=100)
    student_nic: Optional[str] = Field(None, description="Student NIC if applicable")
    parent_name: str = Field(..., min_length=2, max_length=100)
    parent_contact: str = Field(..., min_length=10, max_length=15)
    grade: ApplicationGrade = Field(..., description="Grade applying for")
    school_id: str = Field(..., description="School ID where application is submitted")
    district: str = Field(..., description="District of the school")
    status: ApplicationStatus = Field(default=ApplicationStatus.PENDING)
    priority_score: Optional[float] = Field(default=0.0, description="Priority score for admission")
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)

    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {ObjectId: str},
    }


class SchoolApplicationCreate(BaseModel):
    student_name: str
    student_nic: Optional[str] = None
    parent_name: str
    parent_contact: str
    grade: ApplicationGrade
    school_id: str
    district: str
    priority_score: Optional[float] = 0.0


class SchoolApplicationResponse(BaseModel):
    id: str = Field(..., alias="_id")
    application_id: str
    student_name: str
    student_nic: Optional[str] = None
    parent_name: str
    parent_contact: str
    grade: ApplicationGrade
    school_id: str
    district: str
    status: ApplicationStatus
    priority_score: float
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_mongo(cls, data: dict):
        if "_id" in data:
            data["_id"] = str(data["_id"])
        return cls(**data)

    model_config = {"populate_by_name": True}
