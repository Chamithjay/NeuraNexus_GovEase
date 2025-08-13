from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import connect_to_mongo, close_mongo_connection
from routes.citizen_routes import router as citizen_router
from routes.teacher_routes import router as teacher_router

app = FastAPI(
    title="GovEase API",
    description="Government Services Made Easy - Backend API",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(citizen_router)
app.include_router(teacher_router)

# Connect on startup
@app.on_event("startup")
async def startup_db_client():
    await connect_to_mongo()

# Close on shutdown
@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()

@app.get("/")
async def root():
    return {"message": "Welcome to GovEase API", "status": "running"}
