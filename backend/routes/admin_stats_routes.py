from fastapi import APIRouter
from services.stats_service import get_stats, get_peak_hours

router = APIRouter(prefix="/admin/stats", tags=["Admin Stats"])

@router.get("/")
def stats():
    return get_stats()

@router.get("/peak-hours")
def peak_hours():
    return get_peak_hours()