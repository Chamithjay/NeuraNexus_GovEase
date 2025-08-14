from database import get_clinic_appointments_collection
from datetime import datetime, timedelta
from typing import Dict


async def get_peak_booking_hours() -> Dict:
    """
    Analyze booking patterns to identify peak hours.
    Returns data grouped by hour of day with booking counts.
    """
    collection = get_clinic_appointments_collection()
    
    # Get current date and calculate 7 days ago for recent data
    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)
    
    # Aggregation pipeline to group by hour
    pipeline = [
        {
            "$match": {
                "created_at": {
                    "$gte": start_date.isoformat(),
                    "$lte": end_date.isoformat()
                },
                "status": {"$in": ["booked", "arrived", "no-show"]}
            }
        },
        {
            "$project": {
                "hour": {
                    "$hour": {
                        "$dateFromString": {
                            "dateString": "$created_at"
                        }
                    }
                },
                "status": 1
            }
        },
        {
            "$group": {
                "_id": "$hour",
                "total_bookings": {"$sum": 1},
                "booked": {
                    "$sum": {"$cond": [{"$eq": ["$status", "booked"]}, 1, 0]}
                },
                "arrived": {
                    "$sum": {"$cond": [{"$eq": ["$status", "arrived"]}, 1, 0]}
                },
                "no_show": {
                    "$sum": {"$cond": [{"$eq": ["$status", "no-show"]}, 1, 0]}
                }
            }
        },
        {
            "$sort": {"_id": 1}
        }
    ]
    
    cursor = collection.aggregate(pipeline)
    hourly_data = []
    
    async for doc in cursor:
        hourly_data.append({
            "hour": doc["_id"],
            "total_bookings": doc["total_bookings"],
            "booked": doc["booked"],
            "arrived": doc["arrived"],
            "no_show": doc["no_show"]
        })
    
    # Fill in missing hours with 0 counts
    complete_hourly_data = []
    for hour in range(24):
        found = next((item for item in hourly_data if item["hour"] == hour), None)
        if found:
            complete_hourly_data.append(found)
        else:
            complete_hourly_data.append({
                "hour": hour,
                "total_bookings": 0,
                "booked": 0,
                "arrived": 0,
                "no_show": 0
            })
    
    return {
        "peak_hours_data": complete_hourly_data,
        "date_range": {
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat()
        }
    }

async def get_booking_statistics() -> Dict:
    """
    Get comprehensive booking statistics for admin dashboard.
    """
    collection = get_clinic_appointments_collection()
    
    # Get stats for different time periods
    now = datetime.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=7)
    month_start = today_start - timedelta(days=30)
    
    # Aggregation pipeline for overall stats
    pipeline = [
        {
            "$facet": {
                "today_stats": [
                    {
                        "$match": {
                            "created_at": {"$gte": today_start.isoformat()}
                        }
                    },
                    {
                        "$group": {
                            "_id": "$status",
                            "count": {"$sum": 1}
                        }
                    }
                ],
                "week_stats": [
                    {
                        "$match": {
                            "created_at": {"$gte": week_start.isoformat()}
                        }
                    },
                    {
                        "$group": {
                            "_id": "$status",
                            "count": {"$sum": 1}
                        }
                    }
                ],
                "month_stats": [
                    {
                        "$match": {
                            "created_at": {"$gte": month_start.isoformat()}
                        }
                    },
                    {
                        "$group": {
                            "_id": "$status",
                            "count": {"$sum": 1}
                        }
                    }
                ],
                "all_time_stats": [
                    {
                        "$group": {
                            "_id": "$status",
                            "count": {"$sum": 1}
                        }
                    }
                ]
            }
        }
    ]
    
    cursor = collection.aggregate(pipeline)
    result = await cursor.to_list(length=1)
    
    def format_stats(stats_list):
        formatted = {
            "booked": 0,
            "arrived": 0,
            "no_show": 0
        }
        for stat in stats_list:
            status = stat["_id"]
            if status in formatted:
                formatted[status] = stat["count"]
        return formatted
    
    if result:
        data = result[0]
        return {
            "today": format_stats(data.get("today_stats", [])),
            "week": format_stats(data.get("week_stats", [])),
            "month": format_stats(data.get("month_stats", [])),
            "all_time": format_stats(data.get("all_time_stats", []))
        }
    
    return {
        "today": {"booked": 0, "arrived": 0, "no_show": 0},
        "week": {"booked": 0, "arrived": 0, "no_show": 0},
        "month": {"booked": 0, "arrived": 0, "no_show": 0},
        "all_time": {"booked": 0, "arrived": 0, "no_show": 0}
    }