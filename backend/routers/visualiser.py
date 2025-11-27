from fastapi import APIRouter, Depends, Request

from auth.auth_middleware import require_firebase_user
from database.visualiser_model import (
    get_visualiser_entries,
    save_visualiser_entry,
)
from models.visualiser_models import VisualiserSaveRequest

router = APIRouter(
    prefix="/visualiser",
    tags=["Visualiser"],
    dependencies=[Depends(require_firebase_user)],
)


@router.post("/states")
async def save_visualiser_state(payload: VisualiserSaveRequest, request: Request):
    user_id = request.state.user["uid"]
    entry_id = await save_visualiser_entry(
        user_id=user_id,
        template_id=payload.template_id,
        parameters=payload.parameters,
    )
    return {"id": entry_id}


@router.get("/states")
async def list_visualiser_states(request: Request, limit: int = 20):
    user_id = request.state.user["uid"]
    entries = await get_visualiser_entries(user_id, limit=limit)
    return {"items": entries}
