from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from models.hotel import Bungalow
from typing import List
from services.hotel_service import create_bungalow_with_files
from models.hotel import AvailabilityRequest
from services.hotel_service import get_available_bungalows
# from services.hotel_service import create_bungalow

router = APIRouter()

#get available bungalows based on district adults, and children
@router.post("/bungalows/available")
async def fetch_available_bungalows(request: AvailabilityRequest):
    available = await get_available_bungalows(
        district=request.district,
        checkin=request.checkin,
        checkout=request.checkout,
        adults=request.adults,      # pass adults
        children=request.children   # pass children
    )
    return available

 
# upload a new bungalow details with images
@router.post("/")
async def add_bungalow(
    name: str = Form(...),
    district: str = Form(...),
    capacity: int = Form(...),
    price_per_night: float = Form(...),
    description: str = Form(...),
    facilities: List[str] = Form([]),
    photos: List[UploadFile] = File(...)
):
    if len(photos) != 4:
        raise HTTPException(status_code=400, detail="Exactly 4 photos required")
    
    created = await create_bungalow_with_files(
        name, district, capacity, price_per_night, description, facilities, photos
    )
    return created