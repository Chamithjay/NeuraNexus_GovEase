from pydantic import BaseModel, Field, EmailStr, field_validator
from typing import Optional, Annotated, List
from datetime import datetime
from bson import ObjectId
from enum import Enum
import uuid


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
        if isinstance(v, str):
            if ObjectId.is_valid(v):
                return ObjectId(v)
        raise ValueError("Invalid ObjectId")

    def __str__(self):
        return str(super())


class GenderEnum(str, Enum):
    MALE = "Male"
    FEMALE = "Female"
    OTHER = "Other"


class CitizenTypeEnum(str, Enum):
    CITIZEN = "Citizen"
    TEACHER = "Teacher"


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


class CitizenModel(BaseModel):
    id: Optional[PyObjectId] = Field(default_factory=PyObjectId, alias="_id")
    citizen_id: Optional[str] = Field(None, description="Auto-generated citizen ID")
    nic: str = Field(..., description="National Identity Card number (Unique)", min_length=10, max_length=12)
    full_name: str = Field(..., description="Full name of the citizen", min_length=2, max_length=100)
    date_of_birth: datetime = Field(..., description="Date of birth")
    gender: GenderEnum = Field(..., description="Gender")
    address: str = Field(..., description="Full address", min_length=10, max_length=500)
    contact_number: str = Field(..., description="Contact phone number", min_length=10, max_length=15)
    email: EmailStr = Field(..., description="Email address")
    
    # Citizen type and link to teacher
    citizen_type: CitizenTypeEnum = Field(default=CitizenTypeEnum.CITIZEN, description="Type of citizen")
    teacher_id: Optional[str] = Field(None, description="Linked Teacher ID if citizen is a teacher")
    
    # Common fields
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    is_active: bool = Field(default=True, description="Account status")

    @field_validator('nic')
    @classmethod
    def validate_nic(cls, v):
        # Sri Lankan NIC validation (basic)
        if len(v) == 10:
            if not (v[:9].isdigit() and v[9].upper() in ['V', 'X']):
                raise ValueError('Invalid NIC format for old format')
        elif len(v) == 12:
            if not v.isdigit():
                raise ValueError('Invalid NIC format for new format')
        else:
            raise ValueError('NIC must be 10 or 12 characters')
        return v.upper()

    @field_validator('contact_number')
    @classmethod
    def validate_contact_number(cls, v):
        # Remove any spaces or special characters and validate
        cleaned = ''.join(filter(str.isdigit, v))
        if len(cleaned) < 10:
            raise ValueError('Contact number must be at least 10 digits')
        return v

    @field_validator('date_of_birth')
    @classmethod
    def validate_date_of_birth(cls, v):
        # Ensure aware vs naive comparison is handled
        now = datetime.now(tz=v.tzinfo) if getattr(v, 'tzinfo', None) else datetime.utcnow()
        if v > now:
            raise ValueError('Date of birth cannot be in the future')
        return v


    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {ObjectId: str},
        "json_schema_extra": {
            "examples": [
                {
                    "nic": "200012345678",
                    "full_name": "John Doe Silva",
                    "date_of_birth": "1990-05-15T00:00:00",
                    "gender": "Male",
                    "address": "123 Main Street, Colombo 03, Sri Lanka",
                    "contact_number": "+94771234567",
                    "email": "john.doe@email.com",
                    "citizen_type": "Citizen"
                },
                {
                    "nic": "198567890123",
                    "full_name": "Jane Smith Teacher",
                    "date_of_birth": "1985-08-20T00:00:00",
                    "gender": "Female",
                    "address": "456 School Road, Kandy, Sri Lanka",
                    "contact_number": "+94771234568",
                    "email": "jane.teacher@email.com",
                    "citizen_type": "Teacher",
                    "teacher_id": "TEA123456"
                }
            ]
        }
    }


class CitizenCreate(BaseModel):
    nic: str = Field(..., description="National Identity Card number (Unique)")
    full_name: str = Field(..., description="Full name of the citizen")
    date_of_birth: datetime = Field(..., description="Date of birth")
    gender: GenderEnum = Field(..., description="Gender")
    address: str = Field(..., description="Full address")
    contact_number: str = Field(..., description="Contact phone number")
    email: EmailStr = Field(..., description="Email address")
    password: Optional[str] = Field(None, description="Optional password to create login user")
    
    # Optional link to teacher
    citizen_type: CitizenTypeEnum = Field(default=CitizenTypeEnum.CITIZEN, description="Type of citizen")
    teacher_id: Optional[str] = Field(None, description="Linked Teacher ID if applicable")


class CitizenUpdate(BaseModel):
    full_name: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    gender: Optional[GenderEnum] = None
    address: Optional[str] = None
    contact_number: Optional[str] = None
    email: Optional[EmailStr] = None
    citizen_type: Optional[CitizenTypeEnum] = None
    teacher_id: Optional[str] = None
    is_active: Optional[bool] = None


class CitizenResponse(BaseModel):
    id: str = Field(..., alias="_id")
    citizen_id: str
    nic: str
    full_name: str
    date_of_birth: datetime
    gender: str
    address: str
    contact_number: str
    email: str
    citizen_type: str
    teacher_id: Optional[str] = None
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
