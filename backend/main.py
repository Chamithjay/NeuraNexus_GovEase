from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import connect_to_mongo, close_mongo_connection
from routes.admin_clinic_routes import router as admin_clinic_router
from routes.hotel_routes import router as hotel_router

app = FastAPI()

# Enable CORS
origins = [
    "http://localhost:5173",  # Flutter web dev server
    "http://localhost:8000",  # backend itself
    "http://127.0.0.1:5173", 
    "http://127.0.0.1:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Connect on startup
@app.on_event("startup")
async def startup_db_client():
    await connect_to_mongo()

# Close on shutdown
@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()

# Include routers
app.include_router(admin_clinic_router)
app.include_router(hotel_router)
