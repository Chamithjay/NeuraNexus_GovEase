from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List
from datetime import datetime

from models.citizen import CitizenCreate, CitizenUpdate, CitizenResponse
from services.citizen_service import CitizenService
from database import get_database

router = APIRouter(prefix="/api/citizens", tags=["Citizens"])


async def get_citizen_service():
    """Dependency to get citizen service"""
    db = await get_database()
    return CitizenService(db)


@router.post("/", response_model=CitizenResponse, status_code=201)
async def create_citizen(
    citizen_data: CitizenCreate,
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Create a new citizen"""
    try:
        return await citizen_service.create_citizen(citizen_data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")


@router.get("/", response_model=List[CitizenResponse])
async def get_all_citizens(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    active_only: bool = Query(True, description="Return only active citizens"),
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get all citizens with pagination"""
    return await citizen_service.get_all_citizens(skip=skip, limit=limit, active_only=active_only)


@router.get("/search", response_model=List[CitizenResponse])
async def search_citizens(
    q: str = Query(..., min_length=2, description="Search term"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Search citizens by name, NIC, or email"""
    return await citizen_service.search_citizens(q, skip=skip, limit=limit)


@router.get("/count")
async def get_citizen_count(
    active_only: bool = Query(True, description="Count only active citizens"),
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get total count of citizens"""
    count = await citizen_service.get_citizen_count(active_only=active_only)
    return {"count": count}


@router.get("/{citizen_id}", response_model=CitizenResponse)
async def get_citizen_by_id(
    citizen_id: str,
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get citizen by citizen ID"""
    citizen = await citizen_service.get_citizen_by_id(citizen_id)
    if not citizen:
        raise HTTPException(status_code=404, detail="Citizen not found")
    return citizen


@router.get("/nic/{nic}", response_model=CitizenResponse)
async def get_citizen_by_nic(
    nic: str,
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get citizen by NIC"""
    citizen = await citizen_service.get_citizen_by_nic(nic)
    if not citizen:
        raise HTTPException(status_code=404, detail="Citizen not found")
    return citizen


@router.get("/email/{email}", response_model=CitizenResponse)
async def get_citizen_by_email(
    email: str,
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get citizen by email"""
    citizen = await citizen_service.get_citizen_by_email(email)
    if not citizen:
        raise HTTPException(status_code=404, detail="Citizen not found")
    return citizen


@router.put("/{citizen_id}", response_model=CitizenResponse)
async def update_citizen(
    citizen_id: str,
    update_data: CitizenUpdate,
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Update citizen information"""
    try:
        updated_citizen = await citizen_service.update_citizen(citizen_id, update_data)
        if not updated_citizen:
            raise HTTPException(status_code=404, detail="Citizen not found")
        return updated_citizen
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")


@router.delete("/{citizen_id}")
async def delete_citizen(
    citizen_id: str,
    hard_delete: bool = Query(False, description="Permanently delete the citizen"),
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Delete citizen (soft delete by default, hard delete if specified)"""
    if hard_delete:
        success = await citizen_service.hard_delete_citizen(citizen_id)
        message = "Citizen permanently deleted"
    else:
        success = await citizen_service.delete_citizen(citizen_id)
        message = "Citizen deactivated"
    
    if not success:
        raise HTTPException(status_code=404, detail="Citizen not found")
    
    return {"message": message}


@router.post("/initialize-indexes")
async def initialize_citizen_indexes(
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Initialize database indexes for citizens collection"""
    try:
        await citizen_service.create_indexes()
        return {"message": "Citizen indexes created successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create indexes: {str(e)}")


# Teacher-specific endpoints
@router.get("/teachers", response_model=List[CitizenResponse])
async def get_all_teachers(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get all teachers"""
    return await citizen_service.get_all_teachers(skip=skip, limit=limit)


@router.get("/teachers/subject/{subject}", response_model=List[CitizenResponse])
async def get_teachers_by_subject(
    subject: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get teachers by subject"""
    return await citizen_service.get_teachers_by_subject(subject, skip=skip, limit=limit)


@router.get("/teachers/district/{district}", response_model=List[CitizenResponse])
async def get_teachers_by_district(
    district: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get teachers by district"""
    return await citizen_service.get_teachers_by_district(district, skip=skip, limit=limit)


@router.get("/teachers/experience", response_model=List[CitizenResponse])
async def get_teachers_by_experience(
    min_years: int = Query(..., ge=0, description="Minimum years of experience"),
    max_years: int = Query(None, ge=0, description="Maximum years of experience"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get teachers by years of experience"""
    return await citizen_service.get_teachers_by_experience(min_years, max_years, skip=skip, limit=limit)


@router.get("/teachers/statistics")
async def get_teacher_statistics(
    citizen_service: CitizenService = Depends(get_citizen_service)
):
    """Get teacher statistics"""
    stats = await citizen_service.get_teacher_statistics()
    return stats
