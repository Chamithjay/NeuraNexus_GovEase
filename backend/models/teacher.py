from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum
import uuid

class PyObjectId(ObjectId):
    @classmethod
    def __get_pydantic_core_schema__(cls, source_type, handler):
        return handler(str)

class DistrictEnum(str, Enum):
    COLOMBO = "Colombo"
    GAMPAHA = "Gampaha"
    KALUTARA = "Kalutara"
    KANDY = "Kandy"
    MATALE = "Matale"
    NUWARA_ELIYA = "Nuwara Eliya"
    GALLE = "Galle"
    MATARA = "Matara"
    HAMBANTOTA = "Hambantota"
    JAFFNA = "Jaffna"
    KILINOCHCHI = "Kilinochchi"
    MANNAR = "Mannar"
    VAVUNIYA = "Vavuniya"
    MULLAITIVU = "Mullaitivu"
    BATTICALOA = "Batticaloa"
    AMPARA = "Ampara"
    TRINCOMALEE = "Trincomalee"
    KURUNEGALA = "Kurunegala"
    PUTTALAM = "Puttalam"
    ANURADHAPURA = "Anuradhapura"
    POLONNARUWA = "Polonnaruwa"
    BADULLA = "Badulla"
    MONARAGALA = "Monaragala"
    RATNAPURA = "Ratnapura"
    KEGALLE = "Kegalle"

class TeacherModel(BaseModel):
    id: Optional[PyObjectId] = Field(default_factory=PyObjectId, alias="_id")
    teacher_id: Optional[str] = Field(None, description="Auto-generated Teacher ID")
    teacher_name: str = Field(..., description="Full name of the teacher", min_length=2, max_length=100)
    current_district: DistrictEnum = Field(..., description="Current district of service")
    subjects: List[str] = Field(..., description="Subjects taught by teacher (multi-valued)")
    years_in_service_district: int = Field(..., description="Years in service in current district", ge=0, le=50)
    school_id: str = Field(..., description="School ID (string, reference only)")
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    is_active: bool = Field(default=True, description="Teacher status")

    @field_validator('subjects')
    @classmethod
    def validate_subjects(cls, v):
        if not v or len(v) == 0:
            raise ValueError('Teacher must have at least one subject')
        # Remove duplicates and validate
        unique_subjects = list(set([subject.strip().title() for subject in v if subject.strip()]))
        if len(unique_subjects) == 0:
            raise ValueError('Teacher must have at least one valid subject')
        return unique_subjects

    @field_validator('teacher_name')
    @classmethod
    def validate_teacher_name(cls, v):
        if not v.strip():
            raise ValueError('Teacher name cannot be empty')
        return v.strip().title()

    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {ObjectId: str},
        "json_schema_extra": {
            "example": {
                "teacher_name": "Amal Perera",
                "current_district": "Kandy",
                "subjects": ["Mathematics", "Science"],
                "years_in_service_district": 5,
                "school_id": "SCH98765432"
            }
        }
    }


class TeacherCreate(BaseModel):
    teacher_name: str = Field(..., description="Full name of the teacher")
    current_district: DistrictEnum = Field(..., description="Current district of service")
    subjects: List[str] = Field(..., description="Subjects taught by teacher")
    years_in_service_district: int = Field(..., description="Years in service in current district", ge=0, le=50)
    school_id: str = Field(..., description="School ID")


class TeacherUpdate(BaseModel):
    teacher_name: Optional[str] = None
    current_district: Optional[DistrictEnum] = None
    subjects: Optional[List[str]] = None
    years_in_service_district: Optional[int] = None
    school_id: Optional[str] = None
    is_active: Optional[bool] = None


class TeacherResponse(BaseModel):
    id: str = Field(..., alias="_id")
    teacher_id: str
    teacher_name: str
    current_district: str
    subjects: List[str]
    years_in_service_district: int
    school_id: str
    created_at: datetime
    updated_at: datetime
    is_active: bool

    @classmethod
    def from_mongo(cls, data: dict):
        """Convert MongoDB document to response model"""
        if "_id" in data:
            data["_id"] = str(data["_id"])
        return cls(**data)

    model_config = {"populate_by_name": True}
