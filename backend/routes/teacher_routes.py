from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List
from datetime import datetime

from models.teacher import TeacherCreate, TeacherUpdate, TeacherResponse
from services.teacher_service import TeacherService
from database import get_database

router = APIRouter(prefix="/api/teachers", tags=["Teachers"])


async def get_teacher_service():
    """Dependency to get teacher service"""
    db = await get_database()
    return TeacherService(db)


@router.post("/", response_model=TeacherResponse, status_code=201)
async def create_teacher(
    teacher_data: TeacherCreate,
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Create a new teacher"""
    try:
        return await teacher_service.create_teacher(teacher_data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")


@router.get("/", response_model=List[TeacherResponse])
async def get_all_teachers(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    active_only: bool = Query(True, description="Return only active teachers"),
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Get all teachers with pagination"""
    return await teacher_service.get_all_teachers(skip=skip, limit=limit, active_only=active_only)


@router.get("/search", response_model=List[TeacherResponse])
async def search_teachers(
    q: str = Query(..., min_length=2, description="Search term"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Search teachers by name, subjects, or school ID"""
    return await teacher_service.search_teachers(q, skip=skip, limit=limit)


@router.get("/count")
async def get_teacher_count(
    active_only: bool = Query(True, description="Count only active teachers"),
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Get total count of teachers"""
    count = await teacher_service.get_teacher_count(active_only=active_only)
    return {"count": count}


@router.get("/{teacher_id}", response_model=TeacherResponse)
async def get_teacher_by_id(
    teacher_id: str,
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Get teacher by teacher ID"""
    teacher = await teacher_service.get_teacher_by_id(teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return teacher


@router.get("/district/{district}", response_model=List[TeacherResponse])
async def get_teachers_by_district(
    district: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Get teachers by district"""
    return await teacher_service.get_teachers_by_district(district, skip=skip, limit=limit)


@router.get("/subject/{subject}", response_model=List[TeacherResponse])
async def get_teachers_by_subject(
    subject: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Get teachers by subject"""
    return await teacher_service.get_teachers_by_subject(subject, skip=skip, limit=limit)


@router.get("/school/{school_id}", response_model=List[TeacherResponse])
async def get_teachers_by_school(
    school_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Get teachers by school ID"""
    return await teacher_service.get_teachers_by_school(school_id, skip=skip, limit=limit)


@router.put("/{teacher_id}", response_model=TeacherResponse)
async def update_teacher(
    teacher_id: str,
    update_data: TeacherUpdate,
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Update teacher information"""
    try:
        updated_teacher = await teacher_service.update_teacher(teacher_id, update_data)
        if not updated_teacher:
            raise HTTPException(status_code=404, detail="Teacher not found")
        return updated_teacher
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")


@router.delete("/{teacher_id}")
async def delete_teacher(
    teacher_id: str,
    hard_delete: bool = Query(False, description="Permanently delete the teacher"),
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Delete teacher (soft delete by default, hard delete if specified)"""
    if hard_delete:
        success = await teacher_service.hard_delete_teacher(teacher_id)
        message = "Teacher permanently deleted"
    else:
        success = await teacher_service.delete_teacher(teacher_id)
        message = "Teacher deactivated"
    
    if not success:
        raise HTTPException(status_code=404, detail="Teacher not found")
    
    return {"message": message}


@router.get("/analytics/statistics")
async def get_teacher_statistics(
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Get teacher statistics"""
    stats = await teacher_service.get_teacher_statistics()
    return stats


@router.post("/initialize-indexes")
async def initialize_teacher_indexes(
    teacher_service: TeacherService = Depends(get_teacher_service)
):
    """Initialize database indexes for teachers collection"""
    try:
        await teacher_service.create_indexes()
        return {"message": "Teacher indexes created successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create indexes: {str(e)}")
