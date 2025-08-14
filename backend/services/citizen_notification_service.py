from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument
from datetime import datetime

from models.citizen_notification import (
    CitizenNotificationModel,
    CitizenNotificationResponse,
    NotificationType,
)
from realtime.websocket_manager import manager
from services.citizen_service import CitizenService
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from config import SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD


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

    async def create(self, citizen_id: str, type: NotificationType, description: str, *, matching_id: str | None = None, request_id: str | None = None) -> CitizenNotificationResponse:
        # Deduplicate: if a notification with the same citizen, type, matching_id, request_id and description exists, return it
        try:
            dedupe_query = {
                "citizen_id": citizen_id,
                "type": type.value if hasattr(type, "value") else str(type),
                "matching_id": matching_id,
                "request_id": request_id,
                "description": description,
            }
            # Only run dedupe when we have actionable metadata; otherwise allow repeated GENERAL messages
            if matching_id or request_id:
                existing = await self.collection.find_one(dedupe_query)
                if existing:
                    return CitizenNotificationResponse.from_mongo(existing)
        except Exception:
            # best-effort dedupe; ignore errors
            pass
        seq = await self._next_notification_sequence()
        nid = self._format_notification_id(seq)
        data = CitizenNotificationModel(
            notification_id=nid,
            citizen_id=citizen_id,
            type=type,
            description=description,
            matching_id=matching_id,
            request_id=request_id,
            created_at=datetime.utcnow(),
        ).model_dump(by_alias=True)
        res = await self.collection.insert_one(data)
        doc = await self.collection.find_one({"_id": res.inserted_id})
        resp = CitizenNotificationResponse.from_mongo(doc)
        # best-effort websocket push
        try:
            await manager.send_to(
                citizen_id,
                {
                    "kind": "notification",
                    "notification_id": resp.notification_id,
                    "type": resp.type.value if hasattr(resp.type, 'value') else str(resp.type),
                    "description": resp.description,
                    "created_at": resp.created_at.isoformat(),
                    "is_read": resp.is_read,
                    "matching_id": resp.matching_id,
                    "request_id": resp.request_id,
                },
            )
        except Exception:
            pass
        # best-effort email send
        try:
            citizen_service = CitizenService(self.database)
            citizen = await citizen_service.get_citizen_by_id(citizen_id)
            if citizen and citizen.email:
                subject = "GovEase - Notification"
                if type == NotificationType.TRANSFER:
                    subject = "GovEase - Transfer Update"
                msg = MIMEMultipart()
                msg["From"] = SMTP_USERNAME
                msg["To"] = citizen.email
                msg["Subject"] = subject
                body = f"Hello {citizen.full_name},\n\n{description}\n\nThank you,\nGovEase"
                msg.attach(MIMEText(body, "plain"))
                with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
                    server.starttls()
                    server.login(SMTP_USERNAME, SMTP_PASSWORD)
                    server.sendmail(SMTP_USERNAME, [citizen.email], msg.as_string())
        except Exception:
            # ignore email failures in main flow
            pass
        return resp

    async def list_by_citizen(
        self,
        citizen_id: str,
        only_unread: bool = False,
        skip: int = 0,
        limit: int = 100,
    ) -> list[CitizenNotificationResponse]:
        query = {"citizen_id": citizen_id}
        if only_unread:
            query["is_read"] = False
        cursor = (
            self.collection.find(query)
            .sort("created_at", -1)
            .skip(int(skip))
            .limit(int(limit))
        )
        results: list[CitizenNotificationResponse] = []
        async for doc in cursor:
            results.append(CitizenNotificationResponse.from_mongo(doc))
        return results

    async def mark_all_read(self, citizen_id: str) -> int:
        res = await self.collection.update_many(
            {"citizen_id": citizen_id, "is_read": False}, {"$set": {"is_read": True}}
        )
        return res.modified_count or 0

    async def mark_read(self, citizen_id: str, notification_id: str) -> bool:
        doc = await self.collection.find_one_and_update(
            {"citizen_id": citizen_id, "notification_id": notification_id},
            {"$set": {"is_read": True}},
            return_document=ReturnDocument.AFTER,
        )
        return doc is not None
