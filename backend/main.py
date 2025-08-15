from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import connect_to_mongo, close_mongo_connection
from routes.citizen_routes import router as citizen_router
from routes.teacher_routes import router as teacher_router
from routes.transfer_request_routes import router as transfer_router
from routes.admin_routes import router as admin_router
from routes.admin_analytics_routes import router as admin_analytics_router
from routes.school_application_routes import router as school_application_router
from routes.demo_routes import router as demo_router
from routes.citizen_notification_routes import router as notification_router
from routes.auth_routes import router as auth_router
from routes.websocket_routes import ws_router

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
app.include_router(transfer_router)
app.include_router(admin_router)
app.include_router(admin_analytics_router)
app.include_router(school_application_router)
app.include_router(demo_router)
app.include_router(notification_router)
app.include_router(ws_router)
app.include_router(auth_router)

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
