from motor.motor_asyncio import AsyncIOMotorClient
from backend.config import MONGO_URI, DB_NAME

client = AsyncIOMotorClient(MONGO_URI)
db = client[DB_NAME]
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

async def get_database():
    """Get database instance"""
    global db
    if db is None:
        await connect_to_mongo()
    return db