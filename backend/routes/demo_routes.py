from fastapi import APIRouter, Depends
from typing import Dict, Any
import random
from datetime import datetime, timedelta

router = APIRouter(prefix="/api/demo", tags=["Demo Data"])


@router.post("/seed-school-data/{school_id}")
async def seed_school_applications(school_id: str):
    """Create demo school application data for testing"""
    # This would normally use the database, but for demo purposes we'll return structured data
    grades = ["Grade 1", "Grade 5", "A/L"]
    statuses = ["Pending", "Approved", "Rejected", "Waiting List"]
    
    # Generate random stats
    demo_stats = {}
    for grade in grades:
        total = random.randint(20, 100)
        grade_stats = {
            "total": total,
            "by_status": {}
        }
        
        # Distribute applications across statuses
        remaining = total
        for i, status in enumerate(statuses):
            if i == len(statuses) - 1:  # Last status gets remaining
                count = remaining
            else:
                count = random.randint(0, remaining // 2)
            
            grade_stats["by_status"][status] = count
            remaining -= count
            
            if remaining <= 0:
                break
    
        demo_stats[grade] = grade_stats
    
    return {
        "school_id": school_id,
        "grade_stats": demo_stats,
        "message": f"Demo data generated for school {school_id}"
    }


@router.get("/school-stats/{school_id}")
async def get_demo_school_stats(school_id: str):
    """Get demo school statistics"""
    # Generate consistent demo data based on school_id
    random.seed(hash(school_id) % (2**32))
    
    demo_stats = {}
    grades = ["Grade 1", "Grade 5", "A/L"]
    
    for grade in grades:
        base_total = {"Grade 1": 80, "Grade 5": 60, "A/L": 40}[grade]
        total = base_total + random.randint(-20, 20)
        
        # Create realistic distribution
        approved = int(total * random.uniform(0.3, 0.6))
        pending = int(total * random.uniform(0.2, 0.4))
        rejected = int(total * random.uniform(0.05, 0.15))
        waiting = total - approved - pending - rejected
        
        demo_stats[grade] = {
            "total": total,
            "by_status": {
                "Approved": approved,
                "Pending": pending,
                "Rejected": rejected,
                "Waiting List": max(0, waiting)
            }
        }
    
    return {
        "school_id": school_id,
        "grade_stats": demo_stats
    }
