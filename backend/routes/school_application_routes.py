from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional

from database import get_database
from models.school_application import SchoolApplicationCreate, SchoolApplicationResponse, ApplicationGrade, ApplicationStatus
from services.school_application_service import SchoolApplicationService

router = APIRouter(prefix="/api/school-applications", tags=["School Applications"])


async def get_application_service():
    db = await get_database()
    return SchoolApplicationService(db)


@router.post("/", response_model=SchoolApplicationResponse, status_code=201)
async def create_application(
    payload: SchoolApplicationCreate,
    service: SchoolApplicationService = Depends(get_application_service)
):
    try:
        return await service.create_application(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to create application")


@router.get("/{application_id}", response_model=SchoolApplicationResponse)
async def get_application(
    application_id: str,
    service: SchoolApplicationService = Depends(get_application_service)
):
    application = await service.get_by_application_id(application_id)
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")
    return application


@router.get("/school/{school_id}", response_model=List[SchoolApplicationResponse])
async def list_school_applications(
    school_id: str,
    grade: Optional[ApplicationGrade] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    service: SchoolApplicationService = Depends(get_application_service)
):
    return await service.list_by_school(school_id, grade, skip, limit)


@router.get("/school/{school_id}/stats")
async def get_school_stats(
    school_id: str,
    service: SchoolApplicationService = Depends(get_application_service)
):
    stats = await service.get_school_stats(school_id)
    return {"school_id": school_id, "grade_stats": stats}


@router.put("/{application_id}/status")
async def update_application_status(
    application_id: str,
    status: ApplicationStatus,
    service: SchoolApplicationService = Depends(get_application_service)
):
    success = await service.update_status(application_id, status)
    if not success:
        raise HTTPException(status_code=404, detail="Application not found")
    return {"message": "Status updated successfully"}
