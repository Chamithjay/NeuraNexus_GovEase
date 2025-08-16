from datetime import datetime, time
from database import get_hotel_collection, get_booking_collection
from typing import Dict
from bson import ObjectId
from models.hotel import Bungalow
import os


#get available bungalows based on district adults, and children

async def get_available_bungalows(district: str, checkin, checkout, adults: int, children: int):
    bungalow_collection = get_hotel_collection()
    booking_collection = get_booking_collection()

    # Normalize checkin/checkout times
    if isinstance(checkin, datetime):
        checkin = checkin.replace(hour=14, minute=0, second=0, microsecond=0)
    else:
        checkin = datetime.combine(checkin, time(hour=14, minute=0))

    if isinstance(checkout, datetime):
        checkout = checkout.replace(hour=10, minute=0, second=0, microsecond=0)
    else:
        checkout = datetime.combine(checkout, time(hour=10, minute=0))

    requested_people = adults + children

    # Find bungalows with enough total capacity
    matching_bungalows = await bungalow_collection.find({
        "district": district,
        "capacity": {"$gte": requested_people}
    }).to_list(None)

    available_bungalows = []

    for bungalow in matching_bungalows:
        capacity = bungalow.get("capacity", 0)

        # Find overlapping bookings
        overlapping_bookings = await booking_collection.find({
            "bungalow_id": str(bungalow["_id"]),
            "checkin": {"$lt": checkout},
            "checkout": {"$gt": checkin}
        }).to_list(None)

        # Calculate booked people (adults + children)
        booked_people = sum(
            int(b.get("adults", 0)) + int(b.get("children", 0))
            for b in overlapping_bookings
        )

        remaining_capacity = capacity - booked_people

        # Include bungalow if enough remaining capacity
        if remaining_capacity >= requested_people:
            bungalow["_id"] = str(bungalow["_id"])
            available_bungalows.append(bungalow)

    return available_bungalows




#upload new bungalows with images

UPLOAD_DIR = "uploads/"
os.makedirs(UPLOAD_DIR, exist_ok=True)

async def create_bungalow_with_files(name, district, capacity, price_per_night, description, facilities, photos):
    bungalow_collection = get_hotel_collection()
    photo_paths = []
    for photo in photos:
        file_location = os.path.join(UPLOAD_DIR, photo.filename)
        with open(file_location, "wb") as f:
            f.write(await photo.read())
        photo_paths.append(file_location)
    
    bungalow_data = {
        "name": name,
        "district": district,
        "capacity": capacity,
        "price_per_night": price_per_night,
        "description": description,
        "facilities": facilities,
        "photos": photo_paths
    }
    
    result = await bungalow_collection.insert_one(bungalow_data)
    created_bungalow = await bungalow_collection.find_one({"_id": result.inserted_id})
    created_bungalow["_id"] = str(created_bungalow["_id"])
    return created_bungalow