from motor.motor_asyncio import AsyncIOMotorClient
from config import MONGO_URI, DB_NAME

client = None
db = None

async def connect_to_mongo():
    global client, db
    if not MONGO_URI:
        raise ValueError("MONGO_URI is not set in environment variables")
    client = AsyncIOMotorClient(MONGO_URI)
    db = client[DB_NAME]
    try:
        await client.admin.command('ping')  # This actually tests the connection
        print("Connected to MongoDB")
    except Exception as e:
        print(" Failed to connect to MongoDB:", e)
        raise e


async def close_mongo_connection():
    global client
    if client:
        client.close()
        print("MongoDB connection closed")

def get_clinic_details_collection():
    if db is None:
        raise Exception("Database connection is not established. Call connect_to_mongo() first.")
    return db["clinic_details"]
