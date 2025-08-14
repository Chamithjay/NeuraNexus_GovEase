from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List

from database import get_database
from models.admin import AdminCreate, AdminUpdate, AdminResponse
from services.admin_service import AdminService

router = APIRouter(prefix="/api/admins", tags=["Admins"])


async def get_admin_service():
    db = await get_database()
    return AdminService(db)


@router.post("/", response_model=AdminResponse, status_code=201)
async def create_admin(payload: AdminCreate, svc: AdminService = Depends(get_admin_service)):
    try:
        return await svc.create_admin(payload)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))


@router.get("/", response_model=List[AdminResponse])
async def list_admins(skip: int = Query(0, ge=0), limit: int = Query(100, ge=1, le=1000), active_only: bool = Query(True), svc: AdminService = Depends(get_admin_service)):
    return await svc.list_admins(skip=skip, limit=limit, active_only=active_only)


@router.get("/{admin_id}", response_model=AdminResponse)
async def get_admin(admin_id: str, svc: AdminService = Depends(get_admin_service)):
    admin = await svc.get_admin_by_id(admin_id)
    if not admin:
        raise HTTPException(status_code=404, detail="Admin not found")
    return admin


@router.put("/{admin_id}", response_model=AdminResponse)
async def update_admin(admin_id: str, payload: AdminUpdate, svc: AdminService = Depends(get_admin_service)):
    admin = await svc.update_admin(admin_id, payload)
    if not admin:
        raise HTTPException(status_code=404, detail="Admin not found")
    return admin


@router.delete("/{admin_id}")
async def delete_admin(admin_id: str, svc: AdminService = Depends(get_admin_service)):
    ok = await svc.delete_admin(admin_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Admin not found")
    return {"message": "Admin deactivated"}
