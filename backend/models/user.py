from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime, timedelta
from bson import ObjectId
from enum import Enum


class PyObjectId(ObjectId):
    @classmethod
    def __get_pydantic_core_schema__(cls, source_type, handler):
        from pydantic_core import core_schema
        return core_schema.with_info_plain_validator_function(
            cls.validate,
            serialization=core_schema.to_string_ser_schema(),
        )

    @classmethod
    def validate(cls, v, info):
        if isinstance(v, ObjectId):
            return v
        if isinstance(v, str) and ObjectId.is_valid(v):
            return ObjectId(v)
        raise ValueError("Invalid ObjectId")

    def __str__(self):
        return str(super())


class RoleEnum(str, Enum):
    CITIZEN = "Citizen"
    SCHOOL_ADMIN = "SchoolAdmin"
    ZONAL_ADMIN = "ZonalAdmin"


class UserModel(BaseModel):
    id: Optional[PyObjectId] = Field(default_factory=PyObjectId, alias="_id")
    email: EmailStr = Field(..., description="Unique email for login")
    password_hash: str = Field(..., description="Hashed password")
    role: RoleEnum = Field(..., description="User role for access control")
    linked_citizen_id: Optional[str] = Field(None, description="Optional link to Citizen")
    linked_admin_id: Optional[str] = Field(None, description="Optional link to Admin")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    is_active: bool = Field(default=True)

    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {ObjectId: str},
    }


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
    role: RoleEnum
    linked_citizen_id: Optional[str] = None
    linked_admin_id: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: str = Field(..., alias="_id")
    email: EmailStr
    role: RoleEnum
    linked_citizen_id: Optional[str] = None
    linked_admin_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    is_active: bool

    @classmethod
    def from_mongo(cls, data: dict):
        if "_id" in data:
            data["_id"] = str(data["_id"])
        return cls(**data)

    model_config = {"populate_by_name": True}
