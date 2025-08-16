# backend/services/al_school_service.py
from backend.models.al_school import ALSchool
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv

load_dotenv()
MONGO_URI = os.getenv("MONGO_URI")
DB_NAME = os.getenv("DB_NAME", "GovEase")

# Use Motor async client
client = AsyncIOMotorClient(MONGO_URI)
db = client[DB_NAME]

# Collections
al_schools_collection = db["al_schools"]
al_applications_collection = db["al_applications"]


# Search schools by district and stream
async def search_schools(district: str = None, stream: str = None):
    query = {}
    if district:
        query["district"] = {"$regex": district, "$options": "i"}
    if stream:
        query["streams"] = {"$in": [stream]}

    # Motor async cursor
    cursor = al_schools_collection.find(query)
    schools_list = await cursor.to_list(length=100)

    # Convert to ALSchool Pydantic models
    return [ALSchool(**{k: v for k, v in school.items() if k != "_id"}) for school in schools_list]


# Submit AL application
async def submit_al_application(data: dict):
    result = await al_applications_collection.insert_one(data)
    # Optionally add the inserted_id
    data["_id"] = str(result.inserted_id)
    return data
