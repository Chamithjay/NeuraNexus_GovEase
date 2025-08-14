from datetime import datetime
from enum import Enum
from typing import Optional

from bson import ObjectId
from pydantic import BaseModel, Field


class PyObjectId(ObjectId):
    @classmethod
    def __get_pydantic_core_schema__(cls, source_type, handler):
        return handler(str)


class NotificationType(str, Enum):
    GENERAL = "GENERAL"
    TRANSFER = "TRANSFER"


class CitizenNotificationModel(BaseModel):
    id: Optional[PyObjectId] = Field(default_factory=PyObjectId, alias="_id")
    notification_id: Optional[str] = Field(None, description="Auto-generated, e.g., NOT00001")
    citizen_id: str
    type: NotificationType
    description: str
    is_read: bool = False
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    # Actionable metadata for transfer-related notifications
    matching_id: Optional[str] = None
    request_id: Optional[str] = None

    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {ObjectId: str},
    }


class CitizenNotificationResponse(BaseModel):
    id: str = Field(..., alias="_id")
    notification_id: str
    citizen_id: str
    type: NotificationType
    description: str
    is_read: bool
    created_at: datetime
    matching_id: Optional[str] = None
    request_id: Optional[str] = None

    @classmethod
    def from_mongo(cls, data: dict):
        if "_id" in data:
            data["_id"] = str(data["_id"])
        # Backward compatibility: map old enum values to new ones
        t = data.get("type")
        if isinstance(t, str):
            if t in {"TRANSFER_MATCH", "TRANSFER_AGREEMENT"}:
                data["type"] = NotificationType.TRANSFER
        return cls(**data)

    model_config = {"populate_by_name": True}
