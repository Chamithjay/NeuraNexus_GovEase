# Clinic CRUD service functions
from models.clinic_model import ClinicModel
from database import get_clinic_details_collection


async def add_clinic(clinic: ClinicModel):
    collection = get_clinic_details_collection()
    clinic_dict = clinic.dict()
    result = await collection.insert_one(clinic_dict)
    if result.inserted_id:
        clinic_dict["_id"] = str(result.inserted_id)
        return ClinicModel(**clinic_dict)
    return None

async def get_clinic(clinic_id: str):
    collection = get_clinic_details_collection()
    from bson import ObjectId
    doc = await collection.find_one({"_id": ObjectId(clinic_id)})
    if doc:
        doc["_id"] = str(doc["_id"])
        return ClinicModel(**doc)
    return None

async def update_clinic(clinic_id: str, clinic: ClinicModel):
    collection = get_clinic_details_collection()
    from bson import ObjectId
    clinic_dict = clinic.dict()
    result = await collection.update_one({"_id": ObjectId(clinic_id)}, {"$set": clinic_dict})
    return result.modified_count > 0

async def delete_clinic(clinic_id: str):
    collection = get_clinic_details_collection()
    from bson import ObjectId
    result = await collection.delete_one({"_id": ObjectId(clinic_id)})
    return result.deleted_count > 0
async def get_all_clinics():
    collection = get_clinic_details_collection()
    cursor = collection.find({})
    clinics = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        clinics.append(ClinicModel(**doc))
    return clinics