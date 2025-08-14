from datetime import datetime
from typing import Optional

from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from models.transfer_request import (
    TransferRequestCreate,
    TransferRequestModel,
    TransferRequestResponse,
    RequestStatus,
)


class TransferRequestService:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.database = database
        self.collection = database["transfer_requests"]
        self.counter_collection = database["counters"]

    async def _next_request_sequence(self) -> int:
        # Use a counters collection to generate sequential numbers
        doc = await self.counter_collection.find_one_and_update(
            {"_id": "transfer_request_seq"},
            {"$inc": {"seq": 1}},
            upsert=True,
            return_document=ReturnDocument.AFTER,
        )
        return doc.get("seq", 1)

    def _format_request_id(self, n: int) -> str:
        # REQ00001 style (5 digits, padded)
        return f"REQ{n:05d}"

    async def create_request(self, payload: TransferRequestCreate) -> TransferRequestResponse:
        # Validate teacher eligibility (>=5 years in current district)
        teacher = await self.database["teachers"].find_one({"teacher_id": payload.teacher_id})
        if not teacher:
            raise ValueError("Teacher not found")
        years = teacher.get("years_in_service_district", 0)
        if years is None:
            years = 0
        if int(years) < 5:
            raise ValueError("Teacher is not eligible for transfer (requires at least 5 years in current district)")

        # Prepare model and generate request id
        next_seq = await self._next_request_sequence()
        request_id = self._format_request_id(next_seq)

        data = TransferRequestModel(
            request_id=request_id,
            teacher_id=payload.teacher_id,
            from_district=payload.from_district,
            to_district=payload.to_district,
            created_at=datetime.utcnow(),
        ).model_dump(by_alias=True)

        result = await self.collection.insert_one(data)
        created = await self.collection.find_one({"_id": result.inserted_id})
        return TransferRequestResponse.from_mongo(created)

    async def get_by_request_id(self, req_id: str) -> Optional[TransferRequestResponse]:
        doc = await self.collection.find_one({"request_id": req_id})
        return TransferRequestResponse.from_mongo(doc) if doc else None

    async def find_exact_match(self, *, from_district: str, to_district: str, subjects: list[str]) -> Optional[dict]:
        """Find a transfer request in the opposite direction with same subject set.
        Opposite means someone requested from to_district -> from_district.
        """
        # Find candidate requests in opposite direction still pending/waiting
        cursor = self.collection.find({
            "from_district": to_district,
            "to_district": from_district,
            "status": {"$in": [RequestStatus.PENDING.value, RequestStatus.WAITING_LIST.value]},
        })
        async for req in cursor:
            # Load the teacher to compare subjects
            teacher = await self.database["teachers"].find_one({"teacher_id": req["teacher_id"]})
            if not teacher:
                continue
            t_subjects = set([s.strip().title() for s in teacher.get("subjects", [])])
            if set([s.strip().title() for s in subjects]) == t_subjects:
                return req
        return None

    async def get_teacher_public_details(self, teacher_id: str) -> Optional[dict]:
        """Return limited public details for a teacher to share in match results."""
        teacher = await self.database["teachers"].find_one({"teacher_id": teacher_id})
        if not teacher:
            return None
        return {
            "teacher_name": teacher.get("teacher_name"),
            "current_district": teacher.get("current_district"),
            "years_in_service_district": teacher.get("years_in_service_district"),
            "phone": teacher.get("phone"),
        }

    async def approve_bilateral(self, request_id_a: str, request_id_b: str) -> bool:
        """Mark both requests as Approved. Returns True if both updated."""
        res1 = await self.collection.update_one({"request_id": request_id_a}, {"$set": {"status": RequestStatus.APPROVED.value}})
        res2 = await self.collection.update_one({"request_id": request_id_b}, {"$set": {"status": RequestStatus.APPROVED.value}})
        return res1.matched_count > 0 and res2.matched_count > 0

    async def update_status(self, request_id: str, status: RequestStatus) -> bool:
        result = await self.collection.update_one(
            {"request_id": request_id},
            {"$set": {"status": status.value}},
        )
        return result.matched_count > 0

    async def list_by_teacher(self, teacher_id: str) -> list[TransferRequestResponse]:
        cursor = self.collection.find({"teacher_id": teacher_id}).sort("created_at", -1)
        out: list[TransferRequestResponse] = []
        async for doc in cursor:
            out.append(TransferRequestResponse.from_mongo(doc))
        return out
