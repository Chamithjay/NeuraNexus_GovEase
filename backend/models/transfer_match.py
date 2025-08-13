from datetime import datetime
from enum import Enum
from typing import Optional

from bson import ObjectId
from pydantic import BaseModel, Field


class PyObjectId(ObjectId):
    @classmethod
    def __get_pydantic_core_schema__(cls, source_type, handler):
        return handler(str)


class MatchStatus(str, Enum):
    PENDING = "PENDING"  # record exists but no agreement yet
    PENDING_AGREED = "PENDING-AGREED"  # one party agreed
    AGREED = "AGREED"  # both parties agreed


class TransferMatchModel(BaseModel):
    id: Optional[PyObjectId] = Field(default_factory=PyObjectId, alias="_id")
    matching_id: Optional[str] = Field(default=None, description="Auto-generated, e.g., TM00001")
    request_a_id: str
    request_b_id: str
    agree_a: bool = False
    agree_b: bool = False
    match_status: MatchStatus = MatchStatus.PENDING
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    pair_key: str = Field(..., description="Normalized key 'A|B' for the two requests")

    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {ObjectId: str},
    }


class TransferMatchResponse(BaseModel):
    id: str = Field(..., alias="_id")
    matching_id: str
    request_a_id: str
    request_b_id: str
    agree_a: bool
    agree_b: bool
    match_status: MatchStatus
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_mongo(cls, data: dict):
        if "_id" in data:
            data["_id"] = str(data["_id"])
        return cls(**data)

    model_config = {"populate_by_name": True}
