from pydantic import BaseModel, Field, EmailStr, field_validator
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum


class PyObjectId(ObjectId):
    @classmethod
    def __get_pydantic_core_schema__(cls, source_type, handler):
        return handler(str)


class AdminType(str, Enum):
    ZONAL_ADMIN = "ZonalAdmin"
    SCHOOL_ADMIN = "SchoolAdmin"


class AdminModel(BaseModel):
    id: Optional[PyObjectId] = Field(default_factory=PyObjectId, alias="_id")
    admin_id: Optional[str] = Field(None, description="Auto-generated Admin ID")
    admin_type: AdminType = Field(..., description="Type of admin account")
    admin_name: str = Field(..., min_length=2, max_length=100)
    admin_email: EmailStr = Field(...)
    role: str = Field(..., min_length=2, max_length=50)
    is_active: bool = Field(default=True)

    # Type-specific optional fields
    controlling_zones: Optional[List[str]] = Field(default=None, description="Zones controlled by a Zonal Admin")
    grade_access: Optional[List[str]] = Field(default=None, description="Grades accessible to a School Admin")

    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)

    @field_validator("controlling_zones")
    @classmethod
    def validate_zonal_fields(cls, v, info):
        admin_type = info.data.get("admin_type")
        if admin_type == AdminType.ZONAL_ADMIN:
            # For Zonal Admin, allow empty list, but ensure it's a list when provided
            if v is None:
                return []
            return [str(z).strip() for z in v if str(z).strip()]
        return v

    @field_validator("grade_access")
    @classmethod
    def validate_school_fields(cls, v, info):
        admin_type = info.data.get("admin_type")
        if admin_type == AdminType.SCHOOL_ADMIN:
            if v is None:
                return []
            return [str(g).strip() for g in v if str(g).strip()]
        return v

    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {ObjectId: str},
    }


class AdminCreate(BaseModel):
    admin_type: AdminType
    admin_name: str
    admin_email: EmailStr
    role: str
    is_active: bool = True
    controlling_zones: Optional[List[str]] = None
    grade_access: Optional[List[str]] = None


class AdminUpdate(BaseModel):
    admin_type: Optional[AdminType] = None
    admin_name: Optional[str] = None
    admin_email: Optional[EmailStr] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    controlling_zones: Optional[List[str]] = None
    grade_access: Optional[List[str]] = None


class AdminResponse(BaseModel):
    id: str = Field(..., alias="_id")
    admin_id: str
    admin_type: str
    admin_name: str
    admin_email: str
    role: str
    is_active: bool
    controlling_zones: Optional[List[str]] = None
    grade_access: Optional[List[str]] = None
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_mongo(cls, data: dict):
        if "_id" in data:
            data["_id"] = str(data["_id"])
        return cls(**data)

    model_config = {"populate_by_name": True}
