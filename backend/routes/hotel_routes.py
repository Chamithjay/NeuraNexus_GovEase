from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from models.hotel import Bungalow
from typing import List
from services.hotel_service import create_bungalow_with_files
from models.hotel import AvailabilityRequest
from services.hotel_service import get_available_bungalows
# from services.hotel_service import create_bungalow

router = APIRouter()

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

 

# @router.post("/", response_model=Bungalow)
# async def add_bungalow(bungalow: Bungalow):
#     created = await create_bungalow(bungalow)
#     if not created:
#         raise HTTPException(status_code=500, detail="Failed to create bungalow")
#     return created


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