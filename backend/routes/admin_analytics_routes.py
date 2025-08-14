from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional

from database import get_database
from services.admin_service import AdminService

router = APIRouter(prefix="/api/admin-analytics", tags=["Admin Analytics"])


async def get_admin_service():
    db = await get_database()
    return AdminService(db)


@router.get("/matches")
async def list_matches(
    zones: Optional[str] = Query(None, description="Comma-separated list of zones/districts to include"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    svc: AdminService = Depends(get_admin_service),
):
    zone_list: list[str] = []
    if zones:
        zone_list = [z.strip() for z in zones.split(",") if z.strip()]
    data = await svc.list_matches_for_zones(zone_list, limit=limit, skip=skip)
    return {"items": data, "count": len(data), "skip": skip, "limit": limit}


@router.get("/district-flow/{district}")
async def district_flow(district: str, svc: AdminService = Depends(get_admin_service)):
    if not district:
        raise HTTPException(status_code=400, detail="District is required")
    stats = await svc.district_flow_stats(district)
    return stats
