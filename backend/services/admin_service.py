import uuid
from datetime import datetime
from typing import List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import DuplicateKeyError

from models.admin import AdminModel, AdminCreate, AdminUpdate, AdminResponse
from models.transfer_match import TransferMatchResponse
from models.transfer_request import RequestStatus


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

    async def list_matches_for_zones(self, zones: list[str], limit: int = 100, skip: int = 0) -> list[TransferMatchResponse]:
        """List recent transfer matches involving teachers from any of the given zones.
        A match is included if either request's teacher currently belongs to one of the zones.
        """
        matches_col = self.database["transfer_matches"]
        reqs_col = self.database["transfer_requests"]
        teachers_col = self.database["teachers"]

        cursor = matches_col.find({}).sort("updated_at", -1).skip(skip).limit(limit)
        results: list[dict] = []
        async for m in cursor:
            # Load requests
            reqA = await reqs_col.find_one({"request_id": m.get("request_a_id")})
            reqB = await reqs_col.find_one({"request_id": m.get("request_b_id")})
            if not reqA or not reqB:
                continue
            # Load teachers
            tA = await teachers_col.find_one({"teacher_id": reqA.get("teacher_id")})
            tB = await teachers_col.find_one({"teacher_id": reqB.get("teacher_id")})
            # Filter by zones participation
            zoneA = (tA or {}).get("current_district")
            zoneB = (tB or {}).get("current_district")
            if zones and (zoneA not in zones and zoneB not in zones):
                continue
            # Build a public payload
            results.append({
                "matching_id": m.get("matching_id"),
                "match_status": m.get("match_status"),
                "updated_at": m.get("updated_at"),
                "request_a": {
                    "request_id": reqA.get("request_id"),
                    "from_district": reqA.get("from_district"),
                    "to_district": reqA.get("to_district"),
                    "status": reqA.get("status"),
                    "teacher": {
                        "teacher_name": (tA or {}).get("teacher_name"),
                        "current_district": (tA or {}).get("current_district"),
                        "years_in_service_district": (tA or {}).get("years_in_service_district"),
                        "subjects": (tA or {}).get("subjects", []),
                        "school_id": (tA or {}).get("school_id"),
                    }
                },
                "request_b": {
                    "request_id": reqB.get("request_id"),
                    "from_district": reqB.get("from_district"),
                    "to_district": reqB.get("to_district"),
                    "status": reqB.get("status"),
                    "teacher": {
                        "teacher_name": (tB or {}).get("teacher_name"),
                        "current_district": (tB or {}).get("current_district"),
                        "years_in_service_district": (tB or {}).get("years_in_service_district"),
                        "subjects": (tB or {}).get("subjects", []),
                        "school_id": (tB or {}).get("school_id"),
                    }
                },
            })
        return results

    async def district_flow_stats(self, district: str) -> dict:
        """Compute counts of transfer requests to and from the given district, per counterparty district.
        Returns: { incoming: {fromDistrict: count}, outgoing: {toDistrict: count}, totals: {...} }
        """
        reqs_col = self.database["transfer_requests"]

        # Incoming: to_district == district
        incoming_pipeline = [
            {"$match": {"to_district": district}},
            {"$group": {"_id": "$from_district", "count": {"$sum": 1}}},
            {"$sort": {"count": -1}},
        ]
        outgoing_pipeline = [
            {"$match": {"from_district": district}},
            {"$group": {"_id": "$to_district", "count": {"$sum": 1}}},
            {"$sort": {"count": -1}},
        ]

        incoming: dict[str, int] = {}
        outgoing: dict[str, int] = {}

        async for row in reqs_col.aggregate(incoming_pipeline):
            incoming[str(row["_id"]) if row.get("_id") is not None else "Unknown"] = int(row.get("count", 0))
        async for row in reqs_col.aggregate(outgoing_pipeline):
            outgoing[str(row["_id"]) if row.get("_id") is not None else "Unknown"] = int(row.get("count", 0))

        return {
            "district": district,
            "incoming": incoming,
            "outgoing": outgoing,
            "totals": {
                "incoming": sum(incoming.values()),
                "outgoing": sum(outgoing.values()),
            },
        }
