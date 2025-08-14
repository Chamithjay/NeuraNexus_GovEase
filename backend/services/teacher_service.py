import uuid
from datetime import datetime
from typing import List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from pymongo.errors import DuplicateKeyError

from models.teacher import TeacherModel, TeacherCreate, TeacherUpdate, TeacherResponse


class TeacherService:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.database = database
        self.collection = database["teachers"]
        
    async def create_indexes(self):
        """Create database indexes for the teacher collection"""
        await self.collection.create_index("teacher_id", unique=True)
        await self.collection.create_index("school_id")
        await self.collection.create_index("current_district")
        
    async def generate_teacher_id(self) -> str:
        """Generate a unique teacher ID"""
        while True:
            teacher_id = f"TEA{uuid.uuid4().hex[:8].upper()}"
            existing = await self.collection.find_one({"teacher_id": teacher_id})
            if not existing:
                return teacher_id

    async def create_teacher(self, teacher_data: TeacherCreate) -> TeacherResponse:
        """Create a new teacher"""
        try:
            # Generate unique teacher ID
            teacher_id = await self.generate_teacher_id()
            
            # Create teacher document
            teacher_dict = teacher_data.dict()
            teacher_dict["teacher_id"] = teacher_id
            teacher_dict["created_at"] = datetime.utcnow()
            teacher_dict["updated_at"] = datetime.utcnow()
            teacher_dict["is_active"] = True
            
            # Insert into database
            result = await self.collection.insert_one(teacher_dict)
            
            # Retrieve and return the created teacher
            created_teacher = await self.collection.find_one({"_id": result.inserted_id})
            return TeacherResponse.from_mongo(created_teacher)
            
        except DuplicateKeyError as e:
            if "teacher_id" in str(e):
                raise ValueError("Teacher ID already exists in the system")
            else:
                raise ValueError("Duplicate entry found")

    async def get_teacher_by_id(self, teacher_id: str) -> Optional[TeacherResponse]:
        """Get teacher by teacher ID"""
        teacher = await self.collection.find_one({"teacher_id": teacher_id})
        if teacher:
            return TeacherResponse.from_mongo(teacher)
        return None

    async def get_all_teachers(self, skip: int = 0, limit: int = 100, active_only: bool = True) -> List[TeacherResponse]:
        """Get all teachers with pagination"""
        query = {"is_active": True} if active_only else {}
        cursor = self.collection.find(query).skip(skip).limit(limit)
        teachers = []
        async for teacher in cursor:
            teachers.append(TeacherResponse.from_mongo(teacher))
        return teachers

    async def get_teachers_by_district(self, district: str, skip: int = 0, limit: int = 100) -> List[TeacherResponse]:
        """Get teachers by district"""
        query = {
            "current_district": district,
            "is_active": True
        }
        cursor = self.collection.find(query).skip(skip).limit(limit)
        teachers = []
        async for teacher in cursor:
            teachers.append(TeacherResponse.from_mongo(teacher))
        return teachers

    async def get_teachers_by_subject(self, subject: str, skip: int = 0, limit: int = 100) -> List[TeacherResponse]:
        """Get teachers by subject"""
        query = {
            "subjects": {"$regex": subject, "$options": "i"},
            "is_active": True
        }
        cursor = self.collection.find(query).skip(skip).limit(limit)
        teachers = []
        async for teacher in cursor:
            teachers.append(TeacherResponse.from_mongo(teacher))
        return teachers

    async def get_teachers_by_school(self, school_id: str, skip: int = 0, limit: int = 100) -> List[TeacherResponse]:
        """Get teachers by school ID"""
        query = {
            "school_id": school_id,
            "is_active": True
        }
        cursor = self.collection.find(query).skip(skip).limit(limit)
        teachers = []
        async for teacher in cursor:
            teachers.append(TeacherResponse.from_mongo(teacher))
        return teachers

    async def update_teacher(self, teacher_id: str, update_data: TeacherUpdate) -> Optional[TeacherResponse]:
        """Update teacher information"""
        update_dict = {k: v for k, v in update_data.dict().items() if v is not None}
        
        if not update_dict:
            # No fields to update
            return await self.get_teacher_by_id(teacher_id)
        
        update_dict["updated_at"] = datetime.utcnow()
        
        result = await self.collection.update_one(
            {"teacher_id": teacher_id},
            {"$set": update_dict}
        )
        
        if result.matched_count:
            return await self.get_teacher_by_id(teacher_id)
        return None

    async def delete_teacher(self, teacher_id: str) -> bool:
        """Soft delete a teacher (mark as inactive)"""
        result = await self.collection.update_one(
            {"teacher_id": teacher_id},
            {"$set": {"is_active": False, "updated_at": datetime.utcnow()}}
        )
        return result.matched_count > 0

    async def hard_delete_teacher(self, teacher_id: str) -> bool:
        """Permanently delete a teacher"""
        result = await self.collection.delete_one({"teacher_id": teacher_id})
        return result.deleted_count > 0

    async def search_teachers(self, search_term: str, skip: int = 0, limit: int = 100) -> List[TeacherResponse]:
        """Search teachers by name, subjects, or school ID"""
        query = {
            "$and": [
                {"is_active": True},
                {
                    "$or": [
                        {"teacher_name": {"$regex": search_term, "$options": "i"}},
                        {"subjects": {"$regex": search_term, "$options": "i"}},
                        {"school_id": {"$regex": search_term, "$options": "i"}}
                    ]
                }
            ]
        }
        
        cursor = self.collection.find(query).skip(skip).limit(limit)
        teachers = []
        async for teacher in cursor:
            teachers.append(TeacherResponse.from_mongo(teacher))
        return teachers

    async def get_teacher_count(self, active_only: bool = True) -> int:
        """Get total count of teachers"""
        query = {"is_active": True} if active_only else {}
        return await self.collection.count_documents(query)

    async def get_teacher_statistics(self):
        """Get teacher statistics"""
        pipeline = [
            {"$match": {"is_active": True}},
            {"$group": {
                "_id": None,
                "total_teachers": {"$sum": 1},
                "avg_experience": {"$avg": "$years_in_service_district"},
                "districts": {"$addToSet": "$current_district"},
                "schools": {"$addToSet": "$school_id"},
                "all_subjects": {"$push": "$subjects"}
            }},
            {"$project": {
                "_id": 0,
                "total_teachers": 1,
                "avg_experience": {"$round": ["$avg_experience", 1]},
                "total_districts": {"$size": "$districts"},
                "total_schools": {"$size": "$schools"},
                "districts": 1,
                "unique_subjects": {
                    "$size": {
                        "$setUnion": {
                            "$reduce": {
                                "input": "$all_subjects",
                                "initialValue": [],
                                "in": {"$setUnion": ["$$value", "$$this"]}
                            }
                        }
                    }
                }
            }}
        ]
        
        result = await self.collection.aggregate(pipeline).to_list(1)
        return result[0] if result else {}
