from fastapi import APIRouter
from services.token_service import (
    scan_token, get_tokens, reserve_token
)

router = APIRouter(prefix="/admin/token", tags=["Admin Token"])

@router.post("/scan")
def scan_token_route(qr_data: str):
    return scan_token(qr_data)

@router.get("/{clinic_id}")
def get_tokens_route(clinic_id: str):
    return get_tokens(clinic_id)