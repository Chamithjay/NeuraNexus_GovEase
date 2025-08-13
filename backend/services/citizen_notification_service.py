from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument
from datetime import datetime

from models.citizen_notification import CitizenNotificationModel, CitizenNotificationResponse, NotificationType


class CitizenNotificationService:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.database = database
        self.collection = database["citizen_notifications"]
        self.counter_collection = database["counters"]

    async def create_indexes(self):
        await self.collection.create_index("notification_id", unique=True)
        await self.collection.create_index("citizen_id")

    async def _next_notification_sequence(self) -> int:
        doc = await self.counter_collection.find_one_and_update(
            {"_id": "citizen_notification_seq"},
            {"$inc": {"seq": 1}},
            upsert=True,
            return_document=ReturnDocument.AFTER,
        )
        return doc.get("seq", 1)

    def _format_notification_id(self, n: int) -> str:
        return f"NOT{n:05d}"

    async def create(self, citizen_id: str, type: NotificationType, description: str) -> CitizenNotificationResponse:
        seq = await self._next_notification_sequence()
        nid = self._format_notification_id(seq)
        data = CitizenNotificationModel(
            notification_id=nid,
            citizen_id=citizen_id,
            type=type,
            description=description,
            created_at=datetime.utcnow(),
        ).model_dump(by_alias=True)
        res = await self.collection.insert_one(data)
        doc = await self.collection.find_one({"_id": res.inserted_id})
        return CitizenNotificationResponse.from_mongo(doc)
