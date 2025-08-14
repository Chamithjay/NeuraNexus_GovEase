from fastapi import APIRouter, HTTPException
from services.stats_service import get_peak_booking_hours, get_booking_statistics
from database import get_clinic_appointments_collection

router = APIRouter(prefix="/admin/stats", tags=["Admin Statistics"])

@router.get("/peak-hours")
async def get_peak_hours():
    """
    Get peak booking hours data for the last 7 days.
    Returns hourly booking counts for chart visualization.
    """
    try:
        data = await get_peak_booking_hours()
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching peak hours data: {str(e)}")

@router.get("/booking-statistics")
async def get_stats():
    """
    Get comprehensive booking statistics including:
    - Today's stats
    - Week's stats  
    - Month's stats
    - All-time stats
    """
    try:
        data = await get_booking_statistics()
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching booking statistics: {str(e)}")

@router.get("/summary")
async def get_dashboard_summary():
    """
    Get a summary of key metrics for the admin dashboard.
    """
    try:
        booking_stats = await get_booking_statistics()
        peak_hours = await get_peak_booking_hours()
        
        # Calculate summary metrics
        today_stats = booking_stats["today"]
        week_stats = booking_stats["week"]
        
        # Find peak hour
        peak_hour_data = max(peak_hours["peak_hours_data"], key=lambda x: x["total_bookings"])
        
        summary = {
            "today_total": sum(today_stats.values()),
            "week_total": sum(week_stats.values()),
            "today_booked": today_stats["booked"],
            "today_arrived": today_stats["arrived"],
            "today_no_show": today_stats["no_show"],
            "peak_hour": peak_hour_data["hour"],
            "peak_hour_bookings": peak_hour_data["total_bookings"]
        }
        
        return summary
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching dashboard summary: {str(e)}")

@router.get("/debug/collection-info")
async def debug_collection_info():
    """
    Debug endpoint to check collection data.
    """
    try:
        collection = get_clinic_appointments_collection()
        
        # Count total documents
        total_count = await collection.count_documents({})
        
        # Get sample documents
        sample_docs = []
        cursor = collection.find({}).limit(5)
        async for doc in cursor:
            doc["_id"] = str(doc["_id"])
            sample_docs.append(doc)
        
        # Get distinct statuses
        distinct_statuses = await collection.distinct("status")
        
        # Get date range of existing data
        pipeline = [
            {
                "$group": {
                    "_id": None,
                    "min_date": {"$min": "$created_at"},
                    "max_date": {"$max": "$created_at"}
                }
            }
        ]
        date_range_cursor = collection.aggregate(pipeline)
        date_range = await date_range_cursor.to_list(length=1)
        
        return {
            "total_documents": total_count,
            "sample_documents": sample_docs,
            "distinct_statuses": distinct_statuses,
            "date_range": date_range[0] if date_range else None
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error debugging collection: {str(e)}")