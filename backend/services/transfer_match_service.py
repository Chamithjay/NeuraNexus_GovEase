from datetime import datetime
from typing import Optional

from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from models.transfer_match import TransferMatchModel, TransferMatchResponse, MatchStatus
from realtime.websocket_manager import manager
from services.citizen_service import CitizenService
from services.citizen_notification_service import CitizenNotificationService
from models.citizen_notification import NotificationType


class TransferMatchService:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.database = database
        self.collection = database["transfer_matches"]
        self.counter_collection = database["counters"]

    async def create_indexes(self):
        await self.collection.create_index("matching_id", unique=True)
        await self.collection.create_index("pair_key", unique=True)

    async def _next_match_sequence(self) -> int:
        doc = await self.counter_collection.find_one_and_update(
            {"_id": "transfer_match_seq"},
            {"$inc": {"seq": 1}},
            upsert=True,
            return_document=ReturnDocument.AFTER,
        )
        return doc.get("seq", 1)

    def _format_matching_id(self, n: int) -> str:
        return f"TM{n:05d}"

    def _pair_key(self, a: str, b: str) -> str:
        return "|".join(sorted([a, b]))

    async def get_or_create(self, request_a_id: str, request_b_id: str) -> TransferMatchResponse:
        key = self._pair_key(request_a_id, request_b_id)
        existing = await self.collection.find_one({"pair_key": key})
        if existing:
            return TransferMatchResponse.from_mongo(existing)
        seq = await self._next_match_sequence()
        matching_id = self._format_matching_id(seq)
        data = TransferMatchModel(
            matching_id=matching_id,
            request_a_id=request_a_id,
            request_b_id=request_b_id,
            pair_key=key,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        ).model_dump(by_alias=True)
        res = await self.collection.insert_one(data)
        doc = await self.collection.find_one({"_id": res.inserted_id})
        return TransferMatchResponse.from_mongo(doc)

    async def get_by_matching_id(self, matching_id: str) -> Optional[TransferMatchResponse]:
        doc = await self.collection.find_one({"matching_id": matching_id})
        return TransferMatchResponse.from_mongo(doc) if doc else None

    async def agree(self, matching_id: str, request_id: str) -> Optional[TransferMatchResponse]:
        match = await self.collection.find_one({"matching_id": matching_id})
        if not match:
            return None
        agree_a = match.get("agree_a", False)
        agree_b = match.get("agree_b", False)
        if request_id == match["request_a_id"]:
            agree_a = True
        elif request_id == match["request_b_id"]:
            agree_b = True
        else:
            return None

        status = MatchStatus.AGREED if (agree_a and agree_b) else (MatchStatus.PENDING_AGREED if (agree_a or agree_b) else MatchStatus.PENDING)

        updated = await self.collection.find_one_and_update(
            {"matching_id": matching_id},
            {"$set": {"agree_a": agree_a, "agree_b": agree_b, "match_status": status.value, "updated_at": datetime.utcnow()}},
            return_document=ReturnDocument.AFTER,
        )
        return TransferMatchResponse.from_mongo(updated) if updated else None

    async def disagree(self, matching_id: str, request_id: str) -> Optional[TransferMatchResponse]:
        match = await self.collection.find_one({"matching_id": matching_id})
        if not match:
            return None
        # A disagreement resets the match to PENDING (no agreement) and flags both agrees false
        if request_id not in (match.get("request_a_id"), match.get("request_b_id")):
            return None
        updated = await self.collection.find_one_and_update(
            {"matching_id": matching_id},
            {"$set": {"agree_a": False, "agree_b": False, "match_status": MatchStatus.PENDING.value, "updated_at": datetime.utcnow()}},
            return_document=ReturnDocument.AFTER,
        )
        return TransferMatchResponse.from_mongo(updated) if updated else None
