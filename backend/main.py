from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.database import connect_to_mongo, close_mongo_connection
from backend.routes.grade1_admission import router as grade1_admission_router

from backend.routes.paypal_payment import router as paypal_payment_router
from backend.routes.school_routes import router as school_routes_router


app = FastAPI(
    title="GovEase API",
    description="Government Services Made Easy - Backend API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(grade1_admission_router)
app.include_router(paypal_payment_router)
app.include_router(school_routes_router)
# Connect on startup
@app.on_event("startup")
async def startup_db_client():
    await connect_to_mongo()

# Close on shutdown
@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()

