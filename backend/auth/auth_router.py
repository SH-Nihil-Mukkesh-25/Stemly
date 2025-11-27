from fastapi import APIRouter, Depends

from auth.auth_middleware import require_firebase_user

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.get("/me")
async def read_current_user(user=Depends(require_firebase_user)):
    return {"user": user}

