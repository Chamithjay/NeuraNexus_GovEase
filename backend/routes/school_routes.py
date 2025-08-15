from fastapi import APIRouter, Query
import requests
import os
from dotenv import load_dotenv

# Load env variables
load_dotenv()

router = APIRouter()
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

@router.get("/schools")
def get_schools(city: str):
    if not GOOGLE_API_KEY:
        return {"error": "Google API key not set"}

    # Step 1: Get city coordinates
    geo_url = f"https://maps.googleapis.com/maps/api/geocode/json?address={city}&key={GOOGLE_API_KEY}"
    geo_resp = requests.get(geo_url).json()

    if not geo_resp.get("results"):
        return {"error": "City not found"}

    location = geo_resp["results"][0]["geometry"]["location"]
    lat, lng = location["lat"], location["lng"]

    # Step 2: Get schools near that location
    places_url = (
        f"https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        f"location={lat},{lng}&radius=5000&type=school&key={GOOGLE_API_KEY}"
    )
    places_resp = requests.get(places_url).json()

    schools = [
        {
            "name": place.get("name", ""),
            "address": place.get("vicinity", ""),
            "latitude": place["geometry"]["location"]["lat"],
            "longitude": place["geometry"]["location"]["lng"]
        }
        for place in places_resp.get("results", [])
    ]

    return {"schools": schools}
