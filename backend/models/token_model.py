from pydantic import BaseModel
from typing import Optional

class TokenModel(BaseModel):
    id: Optional[str]
    clinic_id: str
    token_number: int
    is_reserved: bool = False
    is_scanned: bool = False
    user_id: Optional[str]