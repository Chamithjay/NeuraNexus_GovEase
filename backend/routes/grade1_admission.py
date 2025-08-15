# backend/routes/grade1_admission.py
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from typing import List, Optional
from datetime import datetime
import uuid

from backend.services.grade1_admission_service import create_grade1_admission, get_admission_status
from backend.models.grade1_admission import Grade1Admission

router = APIRouter(prefix="/grade1_admission", tags=["Grade 1 Admission"])

# POST endpoint to submit a new application
@router.post("/apply", response_model=Grade1Admission)
async def apply_grade1_admission(
    child_full_name: str = Form(...),
    date_of_birth: str = Form(...),
    parent_name: str = Form(...),
    guardian_nic: str = Form(...),
    contact_number: str = Form(...),
    school_name: str = Form(...),
    files: Optional[List[UploadFile]] = File(None)
):
    try:
        # Handle uploaded files
        file_names = []
        if files:
            for file in files:
                content = await file.read()
                # TODO: save files to disk or cloud if needed
                file_names.append(file.filename)

        # Generate a unique reference number
        reference_number = str(uuid.uuid4())[:8]  # short 8-character ref

        # Prepare data
        data = {
            "reference_number": reference_number,
            "child_full_name": child_full_name,
            "date_of_birth": date_of_birth,
            "parent_name": parent_name,
            "guardian_nic": guardian_nic,
            "contact_number": contact_number,
            "school_name": school_name,
            "uploaded_files": file_names,
            "status": "submitted",
            "created_at": datetime.utcnow()
        }

        # Save to MongoDB
        admission = await create_grade1_admission(data)

        return admission

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# GET endpoint to check status by reference number
@router.get("/status/{reference_number}", response_model=Grade1Admission)
async def check_status(reference_number: str):
    try:
        admission = await get_admission_status(reference_number)
        if not admission:
            raise HTTPException(status_code=404, detail="Application not found")
        return admission
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
