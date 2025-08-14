from fastapi import APIRouter, Depends, HTTPException
from models.user import UserCreate, UserLogin, UserResponse
from services.user_service import UserService
from database import get_database

router = APIRouter(prefix="/api/auth", tags=["Auth"]) 


async def get_user_service():
    db = await get_database()
    return UserService(db)


@router.post("/register", response_model=UserResponse, status_code=201)
async def register(user: UserCreate, user_service: UserService = Depends(get_user_service)):
    try:
        return await user_service.register(user)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login")
async def login(payload: UserLogin, user_service: UserService = Depends(get_user_service)):
    result = await user_service.login(payload.email, payload.password)
    if not result:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return result
