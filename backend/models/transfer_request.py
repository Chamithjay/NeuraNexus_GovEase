from datetime import datetime
from enum import Enum
from typing import Optional

from bson import ObjectId
from pydantic import BaseModel, Field


class PyObjectId(ObjectId):
    @classmethod
    def __get_pydantic_core_schema__(cls, source_type, handler):
        return handler(str)


class RequestStatus(str, Enum):
    PENDING = "Pending"
    APPROVED = "Approved"
    REJECTED = "Rejected"
    WAITING_LIST = "Waiting List"


class TransferRequestModel(BaseModel):
    id: Optional[PyObjectId] = Field(default_factory=PyObjectId, alias="_id")
    request_id: Optional[str] = Field(default=None, description="Auto-generated request ID, e.g., REQ00001")
    teacher_id: str
    from_district: str
    to_district: str
    status: RequestStatus = Field(default=RequestStatus.PENDING)
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)

    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {ObjectId: str},
        "json_schema_extra": {
            "example": {
                "teacher_id": "TEA12345678",
                "from_district": "Kandy",
                "to_district": "Colombo",
            }
        },
    }


class TransferRequestCreate(BaseModel):
    teacher_id: str
    from_district: str
    to_district: str


class TransferRequestResponse(BaseModel):
    id: str = Field(..., alias="_id")
    request_id: str
    teacher_id: str
    from_district: str
    to_district: str
    status: RequestStatus
    created_at: datetime

    @classmethod
    def from_mongo(cls, data: dict):
        if "_id" in data:
            data["_id"] = str(data["_id"])
        return cls(**data)

    model_config = {"populate_by_name": True}
