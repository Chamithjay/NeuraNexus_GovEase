import uuid
from datetime import datetime
import re
from typing import List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from pymongo.errors import DuplicateKeyError

from models.citizen import CitizenModel, CitizenCreate, CitizenUpdate, CitizenResponse
from models.user import RoleEnum
from services.user_service import UserService


class CitizenService:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.database = database
        self.collection = database["citizens"]
        
    async def create_indexes(self):
        """Create database indexes for the citizen collection"""
        await self.collection.create_index("nic", unique=True)
        await self.collection.create_index("email", unique=True)
        await self.collection.create_index("citizen_id", unique=True)
        
    async def generate_citizen_id(self) -> str:
        """Generate a unique citizen ID"""
        while True:
            citizen_id = f"CIT{uuid.uuid4().hex[:8].upper()}"
            existing = await self.collection.find_one({"citizen_id": citizen_id})
            if not existing:
                return citizen_id

    async def create_citizen(self, citizen_data: CitizenCreate) -> CitizenResponse:
        """Create a new citizen"""
        try:
            # Generate unique citizen ID
            citizen_id = await self.generate_citizen_id()
            
            # Create citizen document
            citizen_dict = citizen_data.dict()
            # Normalize for uniqueness checks
            if citizen_dict.get("email"):
                citizen_dict["email"] = str(citizen_dict["email"]).strip().lower()
            if citizen_dict.get("nic"):
                citizen_dict["nic"] = str(citizen_dict["nic"]).strip().upper()

            print(f"[CitizenService] Incoming create: email={citizen_dict.get('email')} nic={citizen_dict.get('nic')}")

            # Pre-check duplicates within the citizens collection only (skip email pre-check; rely on DB unique index)
            if citizen_dict.get("nic"):
                exists_nic = await self.collection.find_one({"nic": citizen_dict["nic"]})
                if exists_nic:
                    print(f"[CitizenService] Duplicate NIC detected: {citizen_dict['nic']}")
                    raise ValueError("NIC already exists in the system")
            citizen_dict["citizen_id"] = citizen_id
            citizen_dict["created_at"] = datetime.utcnow()
            citizen_dict["updated_at"] = datetime.utcnow()
            citizen_dict["is_active"] = True
            
            # Insert into database
            result = await self.collection.insert_one(citizen_dict)
            
            # Retrieve and return the created citizen
            created_citizen = await self.collection.find_one({"_id": result.inserted_id})
            response = CitizenResponse.from_mongo(created_citizen)

            # If password provided, create a corresponding User for login
            if citizen_data.password:
                user_service = UserService(self.database)
                from models.user import UserCreate
                try:
                    await user_service.register(
                        UserCreate(
                            email=citizen_dict["email"],
                            password=citizen_data.password,
                            role=RoleEnum.CITIZEN,
                            linked_citizen_id=response.citizen_id,
                        )
                    )
                except ValueError:
                    # If user already exists, ignore; citizen creation should not fail
                    pass

            return response
            
        except DuplicateKeyError as e:
            if "nic" in str(e):
                raise ValueError("NIC already exists in the system")
            elif "email" in str(e):
                raise ValueError("Email already exists in the system")
            else:
                raise ValueError("Duplicate entry found")

    async def get_citizen_by_id(self, citizen_id: str) -> Optional[CitizenResponse]:
        """Get citizen by citizen ID"""
        citizen = await self.collection.find_one({"citizen_id": citizen_id})
        if citizen:
            return CitizenResponse.from_mongo(citizen)
        return None

    async def get_citizen_by_nic(self, nic: str) -> Optional[CitizenResponse]:
        """Get citizen by NIC"""
        citizen = await self.collection.find_one({"nic": nic.upper()})
        if citizen:
            return CitizenResponse.from_mongo(citizen)
        return None

    async def get_citizen_by_email(self, email: str) -> Optional[CitizenResponse]:
        """Get citizen by email"""
        # Use case-insensitive exact match to align with duplicate checks during create
        citizen = await self.collection.find_one({
            "$expr": {"$eq": [{"$toLower": "$email"}, email.lower()]}
        })
        if citizen:
            return CitizenResponse.from_mongo(citizen)
        return None

    async def check_availability(self, *, email: Optional[str] = None, nic: Optional[str] = None) -> dict:
        """Check if provided email or NIC already exist in citizens collection."""
        email_exists = False
        nic_exists = False
        if email:
            email_norm = str(email).strip().lower()
            email_exists = await self.collection.find_one({
                "$expr": {"$eq": [{"$toLower": "$email"}, email_norm]}
            }) is not None
        if nic:
            nic_norm = str(nic).strip().upper()
            nic_exists = await self.collection.find_one({"nic": nic_norm}) is not None
        return {
            "email_exists": email_exists,
            "nic_exists": nic_exists,
        }

    async def get_all_citizens(self, skip: int = 0, limit: int = 100, active_only: bool = True) -> List[CitizenResponse]:
        """Get all citizens with pagination"""
        query = {"is_active": True} if active_only else {}
        cursor = self.collection.find(query).skip(skip).limit(limit)
        citizens = []
        async for citizen in cursor:
            citizens.append(CitizenResponse.from_mongo(citizen))
        return citizens

    async def link_teacher_to_citizen(self, *, citizen_id: Optional[str] = None, nic: Optional[str] = None, teacher_id: str = "") -> Optional[CitizenResponse]:
        """Link a citizen to a teacher_id using citizen_id or NIC."""
        if not teacher_id:
            return None
        query = {"citizen_id": citizen_id} if citizen_id else ({"nic": nic.upper()} if nic else None)
        if not query:
            return None
        result = await self.collection.find_one_and_update(
            query,
            {"$set": {"teacher_id": teacher_id, "citizen_type": "Teacher", "updated_at": datetime.utcnow()}},
            return_document=True,
        )
        return CitizenResponse.from_mongo(result) if result else None

    async def get_citizen_by_teacher_id(self, teacher_id: str) -> Optional[CitizenResponse]:
        doc = await self.collection.find_one({"teacher_id": teacher_id})
        return CitizenResponse.from_mongo(doc) if doc else None

    async def update_citizen(self, citizen_id: str, update_data: CitizenUpdate) -> Optional[CitizenResponse]:
        """Update citizen information"""
        update_dict = {k: v for k, v in update_data.dict().items() if v is not None}
        
        if not update_dict:
            # No fields to update
            return await self.get_citizen_by_id(citizen_id)
        
        update_dict["updated_at"] = datetime.utcnow()
        
        result = await self.collection.update_one(
            {"citizen_id": citizen_id},
            {"$set": update_dict}
        )
        
        if result.matched_count:
            return await self.get_citizen_by_id(citizen_id)
        return None

    async def delete_citizen(self, citizen_id: str) -> bool:
        """Soft delete a citizen (mark as inactive)"""
        result = await self.collection.update_one(
            {"citizen_id": citizen_id},
            {"$set": {"is_active": False, "updated_at": datetime.utcnow()}}
        )
        return result.matched_count > 0

    async def hard_delete_citizen(self, citizen_id: str) -> bool:
        """Permanently delete a citizen"""
        result = await self.collection.delete_one({"citizen_id": citizen_id})
        return result.deleted_count > 0

    async def search_citizens(self, search_term: str, skip: int = 0, limit: int = 100) -> List[CitizenResponse]:
        """Search citizens by name, NIC, or email"""
        query = {
            "$and": [
                {"is_active": True},
                {
                    "$or": [
                        {"full_name": {"$regex": search_term, "$options": "i"}},
                        {"nic": {"$regex": search_term, "$options": "i"}},
                        {"email": {"$regex": search_term, "$options": "i"}}
                    ]
                }
            ]
        }
        
        cursor = self.collection.find(query).skip(skip).limit(limit)
        citizens = []
        async for citizen in cursor:
            citizens.append(CitizenResponse.from_mongo(citizen))
        return citizens

    async def get_citizen_count(self, active_only: bool = True) -> int:
        """Get total count of citizens"""
        query = {"is_active": True} if active_only else {}
        return await self.collection.count_documents(query)

    # Teacher-centric queries removed from citizen service; use teacher_service and teacher routes.
