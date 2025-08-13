from fastapi import APIRouter, HTTPException
from models.clinic_model import ClinicModel
from services.clinic_service import (
    add_clinic, update_clinic, delete_clinic, get_clinic, get_all_clinics
)

router = APIRouter(prefix="/admin/clinic", tags=["Admin Clinic"])

@router.post("/", response_model=ClinicModel)
async def create_clinic(clinic: ClinicModel):
    created = await add_clinic(clinic)
    if not created:
        raise HTTPException(status_code=400, detail="Clinic creation failed")
    return created

@router.get("/", response_model=list[ClinicModel])
async def get_clinics():
    clinics = await get_all_clinics()
    return clinics

@router.get("/{clinic_id}", response_model=ClinicModel)
async def read_clinic(clinic_id: str):
    clinic = await get_clinic(clinic_id)
    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found")
    return clinic

@router.put("/{clinic_id}")
async def modify_clinic(clinic_id: str, clinic: ClinicModel):
    updated = await update_clinic(clinic_id, clinic)
    if not updated:
        raise HTTPException(status_code=404, detail="Clinic not found")
    return {"message": "Clinic updated successfully"}

@router.delete("/{clinic_id}")
async def remove_clinic(clinic_id: str):
    deleted = await delete_clinic(clinic_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Clinic not found")
    return {"message": "Clinic deleted successfully"}