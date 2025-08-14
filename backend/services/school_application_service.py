from datetime import datetime
from typing import Optional, List
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument
import uuid

from models.school_application import SchoolApplicationModel, SchoolApplicationCreate, SchoolApplicationResponse, ApplicationStatus, ApplicationGrade


class SchoolApplicationService:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.database = database
        self.collection = database["school_applications"]
        self.counter_collection = database["counters"]

    async def create_indexes(self):
        await self.collection.create_index("application_id", unique=True)
        await self.collection.create_index("school_id")
        await self.collection.create_index("grade")
        await self.collection.create_index("district")

    async def _next_application_sequence(self) -> int:
        doc = await self.counter_collection.find_one_and_update(
            {"_id": "school_application_seq"},
            {"$inc": {"seq": 1}},
            upsert=True,
            return_document=ReturnDocument.AFTER,
        )
        return doc.get("seq", 1)

    def _format_application_id(self, n: int) -> str:
        return f"APP{n:05d}"

    async def create_application(self, payload: SchoolApplicationCreate) -> SchoolApplicationResponse:
        seq = await self._next_application_sequence()
        application_id = self._format_application_id(seq)

        data = SchoolApplicationModel(
            application_id=application_id,
            student_name=payload.student_name,
            student_nic=payload.student_nic,
            parent_name=payload.parent_name,
            parent_contact=payload.parent_contact,
            grade=payload.grade,
            school_id=payload.school_id,
            district=payload.district,
            priority_score=payload.priority_score or 0.0,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        ).model_dump(by_alias=True)

        result = await self.collection.insert_one(data)
        created = await self.collection.find_one({"_id": result.inserted_id})
        return SchoolApplicationResponse.from_mongo(created)

    async def get_by_application_id(self, application_id: str) -> Optional[SchoolApplicationResponse]:
        doc = await self.collection.find_one({"application_id": application_id})
        return SchoolApplicationResponse.from_mongo(doc) if doc else None

    async def list_by_school(self, school_id: str, grade: Optional[ApplicationGrade] = None, skip: int = 0, limit: int = 100) -> List[SchoolApplicationResponse]:
        query = {"school_id": school_id}
        if grade:
            query["grade"] = grade.value
        
        cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
        results: List[SchoolApplicationResponse] = []
        async for doc in cursor:
            results.append(SchoolApplicationResponse.from_mongo(doc))
        return results

    async def get_school_stats(self, school_id: str) -> dict:
        """Get application statistics for a school by grade"""
        pipeline = [
            {"$match": {"school_id": school_id}},
            {"$group": {
                "_id": {"grade": "$grade", "status": "$status"},
                "count": {"$sum": 1}
            }},
            {"$group": {
                "_id": "$_id.grade",
                "statuses": {
                    "$push": {
                        "status": "$_id.status",
                        "count": "$count"
                    }
                },
                "total": {"$sum": "$count"}
            }}
        ]
        
        stats = {}
        async for doc in self.collection.aggregate(pipeline):
            grade = doc["_id"]
            grade_stats = {"total": doc["total"], "by_status": {}}
            for status_info in doc["statuses"]:
                grade_stats["by_status"][status_info["status"]] = status_info["count"]
            stats[grade] = grade_stats
        
        return stats

    async def update_status(self, application_id: str, status: ApplicationStatus) -> bool:
        result = await self.collection.update_one(
            {"application_id": application_id},
            {"$set": {"status": status.value, "updated_at": datetime.utcnow()}},
        )
        return result.matched_count > 0
