import uuid
from datetime import datetime
from typing import List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import DuplicateKeyError

from models.admin import AdminModel, AdminCreate, AdminUpdate, AdminResponse


class AdminService:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.database = database
        self.collection = database["admins"]

    async def create_indexes(self):
        await self.collection.create_index("admin_id", unique=True)
        await self.collection.create_index("admin_email", unique=True)
        await self.collection.create_index("admin_type")
        await self.collection.create_index("controlling_zones")

    async def generate_admin_id(self) -> str:
        while True:
            admin_id = f"ADM{uuid.uuid4().hex[:8].upper()}"
            existing = await self.collection.find_one({"admin_id": admin_id})
            if not existing:
                return admin_id

    async def create_admin(self, payload: AdminCreate) -> AdminResponse:
        try:
            admin_id = await self.generate_admin_id()
            data = payload.dict()
            data.update({
                "admin_id": admin_id,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow(),
            })
            result = await self.collection.insert_one(data)
            doc = await self.collection.find_one({"_id": result.inserted_id})
            return AdminResponse.from_mongo(doc)
        except DuplicateKeyError as e:
            if "admin_email" in str(e):
                raise ValueError("Admin email already exists")
            raise ValueError("Duplicate admin record")

    async def get_admin_by_id(self, admin_id: str) -> Optional[AdminResponse]:
        doc = await self.collection.find_one({"admin_id": admin_id})
        return AdminResponse.from_mongo(doc) if doc else None

    async def list_admins(self, skip: int = 0, limit: int = 100, active_only: bool = True) -> List[AdminResponse]:
        query = {"is_active": True} if active_only else {}
        cursor = self.collection.find(query).skip(skip).limit(limit)
        out: List[AdminResponse] = []
        async for d in cursor:
            out.append(AdminResponse.from_mongo(d))
        return out

    async def update_admin(self, admin_id: str, update: AdminUpdate) -> Optional[AdminResponse]:
        upd = {k: v for k, v in update.dict().items() if v is not None}
        if not upd:
            return await self.get_admin_by_id(admin_id)
        upd["updated_at"] = datetime.utcnow()
        res = await self.collection.update_one({"admin_id": admin_id}, {"$set": upd})
        if res.matched_count:
            return await self.get_admin_by_id(admin_id)
        return None

    async def delete_admin(self, admin_id: str) -> bool:
        res = await self.collection.update_one({"admin_id": admin_id}, {"$set": {"is_active": False, "updated_at": datetime.utcnow()}})
        return res.matched_count > 0

    async def get_zonal_admins_for_zone(self, zone: str) -> List[AdminResponse]:
        cursor = self.collection.find({
            "admin_type": "ZonalAdmin",
            "is_active": True,
            "controlling_zones": {"$in": [zone]}
        })
        out: List[AdminResponse] = []
        async for d in cursor:
            out.append(AdminResponse.from_mongo(d))
        return out
