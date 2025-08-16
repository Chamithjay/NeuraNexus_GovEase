# # backend/routes/al_schools.py
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from typing import List, Optional
from datetime import datetime
import uuid
from pydantic import BaseModel

from backend.services.al_school_service import search_schools, submit_al_application
from backend.models.al_school import ALSchool, ALApplication

router = APIRouter(prefix="/al_schools", tags=["Advanced Level Schools"])

# Pydantic model for JSON application submission
class ApplicationSubmission(BaseModel):
    full_name: str
    nic: str
    preferred_stream: str
    selected_school: str
    files: Optional[List[str]] = []

# Payment confirmation model
class PaymentConfirmation(BaseModel):
    application_id: str
    payment_method: str
    amount: float
    status: str

# GET endpoint: fetch schools by district + stream
@router.get("/search", response_model=List[ALSchool])
async def search_al_schools(district: Optional[str] = None, stream: Optional[str] = None):
    try:
        schools = await search_schools(district=district, stream=stream)
        return schools
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# POST endpoint: submit AL application (JSON version)
@router.post("/apply", response_model=dict)
async def apply_al_school_json(application: ApplicationSubmission):
    try:
        application_data = {
            "application_id": str(uuid.uuid4())[:8],
            "full_name": application.full_name,
            "nic": application.nic,
            "preferred_stream": application.preferred_stream,
            "selected_school": application.selected_school,
            "uploaded_files": application.files or [],
            "status": "submitted",
            "created_at": datetime.utcnow()
        }

        app = await submit_al_application(application_data)
        
        # Return the response in a format that matches what Flutter expects
        return {
            "application_id": application_data["application_id"],
            "status": "success",
            "message": "Application submitted successfully"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# POST endpoint: submit AL application with file upload (Form version - keep for file uploads)
@router.post("/apply-with-files", response_model=dict)
async def apply_al_school_with_files(
    full_name: str = Form(...),
    nic: str = Form(...),
    preferred_stream: str = Form(...),
    selected_school: str = Form(...),
    files: Optional[List[UploadFile]] = File(None)
):
    try:
        # Handle uploaded files
        file_names = []
        if files:
            for file in files:
                content = await file.read()  # Read file content
                # TODO: Save files to storage (S3, local storage, etc.)
                file_names.append(file.filename)

        application_data = {
            "application_id": str(uuid.uuid4())[:8],
            "full_name": full_name,
            "nic": nic,
            "preferred_stream": preferred_stream,
            "selected_school": selected_school,
            "uploaded_files": file_names,
            "status": "submitted",
            "created_at": datetime.utcnow()
        }

        app = await submit_al_application(application_data)
        
        return {
            "application_id": application_data["application_id"],
            "status": "success",
            "message": "Application with files submitted successfully"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# POST endpoint: confirm payment
@router.post("/payment/confirm", response_model=dict)
async def confirm_payment(payment: PaymentConfirmation):
    try:
        from backend.services.al_school_service import db
        
        # Create payment record
        payment_data = {
            "application_id": payment.application_id,
            "payment_method": payment.payment_method,
            "amount": payment.amount,
            "status": payment.status,
            "payment_date": datetime.utcnow(),
            "transaction_id": f"TXN{uuid.uuid4().hex[:8].upper()}"
        }
        
        # Insert payment record
        await db["al_payments"].insert_one(payment_data)
        
        # Update application status
        al_applications_collection = db["al_applications"]
        await al_applications_collection.update_one(
            {"application_id": payment.application_id},
            {
                "$set": {
                    "payment_status": payment.status,
                    "payment_date": datetime.utcnow(),
                    "status": "payment_completed" if payment.status == "completed" else "payment_pending"
                }
            }
        )
        
        return {
            "message": "Payment confirmed successfully",
            "transaction_id": payment_data["transaction_id"],
            "status": "success"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))