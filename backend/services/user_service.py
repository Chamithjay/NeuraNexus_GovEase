from datetime import datetime, timedelta
from typing import Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import DuplicateKeyError
from passlib.context import CryptContext
from jose import jwt

from models.user import UserModel, UserCreate, UserResponse
from config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class UserService:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.database = database
        self.collection = database["users"]

    async def create_indexes(self):
        await self.collection.create_index("email", unique=True)

    def hash_password(self, password: str) -> str:
        return pwd_context.hash(password)

    def verify_password(self, plain_password: str, password_hash: str) -> bool:
        return pwd_context.verify(plain_password, password_hash)

    async def get_by_email(self, email: str) -> Optional[dict]:
        return await self.collection.find_one({"email": email.lower()})

    async def register(self, data: UserCreate) -> UserResponse:
        await self.create_indexes()
        user_dict = {
            "email": data.email.lower(),
            "password_hash": self.hash_password(data.password),
            "role": data.role,
            "linked_citizen_id": data.linked_citizen_id,
            "linked_admin_id": data.linked_admin_id,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "is_active": True,
        }
        try:
            result = await self.collection.insert_one(user_dict)
            created = await self.collection.find_one({"_id": result.inserted_id})
            return UserResponse.from_mongo(created)
        except DuplicateKeyError:
            raise ValueError("Email already registered")

    def create_access_token(self, subject: str, role: str) -> str:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode = {"sub": subject, "role": role, "exp": expire}
        return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

    async def login(self, email: str, password: str) -> Optional[dict]:
        user = await self.get_by_email(email)
        if not user or not user.get("is_active", True):
            return None
        if not self.verify_password(password, user["password_hash"]):
            return None
        token = self.create_access_token(user["email"], user["role"])  # type: ignore
        return {
            "access_token": token,
            "token_type": "bearer",
            "user": UserResponse.from_mongo(user).dict(by_alias=True),
        }
