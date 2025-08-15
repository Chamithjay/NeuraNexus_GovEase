from pydantic import BaseModel, Field
from datetime import date
from typing import Optional

from typing import List, Optional
from pydantic import BaseModel, Field

class Bungalow(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    name: str
    district: str
    capacity: int
    price_per_night: float
    description: str
    facilities: List[str] = []  # e.g., ["WiFi", "Pool"]
    photos: List[str] = Field(..., min_items=4, max_items=4)  # Exactly 4 photos

    class Config:
        orm_mode = True
        allow_population_by_field_name = True


class AvailabilityRequest(BaseModel):
    district: str
    checkin: date
    checkout: date
    adults: int
    children: int
