from fastapi import FastAPI
from database import connect_to_mongo, close_mongo_connection

app = FastAPI()

# Connect on startup
@app.on_event("startup")
async def startup_db_client():
    await connect_to_mongo()

# Close on shutdown
@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()
