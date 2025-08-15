from backend.database import get_database
from backend.models.grade1_admission import Grade1Admission
from bson import ObjectId

# Save a new Grade 1 admission application
async def create_grade1_admission(data: dict) -> Grade1Admission:
    # Get database instance (ensures connection is active)
    db = await get_database()
    
    # Insert the document
    result = await db.grade1_admission.insert_one(data)
    
    # Fetch the inserted document to return
    new_doc = await db.grade1_admission.find_one({"_id": result.inserted_id})
    
    if not new_doc:
        raise Exception("Failed to fetch the inserted application")
    
    # Convert Mongo document to Pydantic model
    return Grade1Admission(**new_doc)


# Retrieve admission status by reference number
async def get_admission_status(reference_number: str) -> Grade1Admission:
    db = await get_database()
    
    admission = await db.grade1_admission.find_one({"reference_number": reference_number})
    
    if not admission:
        return None
    
    return Grade1Admission(**admission)
