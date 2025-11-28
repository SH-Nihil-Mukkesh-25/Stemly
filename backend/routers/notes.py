from fastapi import APIRouter, Depends, HTTPException, Request

from auth.auth_middleware import require_firebase_user
from database.notes_model import save_notes_entry
from models.notes_models import NotesFollowUpRequest, NotesGenerateRequest, NotesResponse
from services.ai_notes import follow_up_notes, generate_notes
from utils.file_utils import resolve_scan_path, scan_path_to_relative

router = APIRouter(
    prefix="/notes",
    tags=["Notes"],
    dependencies=[Depends(require_firebase_user)],
)


# -----------------------------------------
# 1. Generate Full Notes
# -----------------------------------------

@router.post("/generate", response_model=NotesResponse)
async def generate_notes_route(req: NotesGenerateRequest, request: Request):

    local_path = None
    relative_path = None
    if req.image_path:
        try:
            local_path = resolve_scan_path(req.image_path)
            relative_path = scan_path_to_relative(local_path)
        except ValueError as exc:
            raise HTTPException(
                status_code=400,
                detail=str(exc),
            ) from exc

    user_id = request.state.user["uid"]

    try:
        image_arg = relative_path or req.image_path
        notes = await generate_notes(req.topic, req.variables, image_arg)
        await save_notes_entry(
            user_id=user_id,
            topic=req.topic,
            notes_payload=notes.dict(),
            image_path=relative_path or req.image_path,
        )
        return notes

    except Exception as e:
        print("❌ Error in /notes/generate:", e)
        raise HTTPException(status_code=500, detail="Failed to generate notes.")



# -----------------------------------------
# 2. Follow-up Question
# -----------------------------------------

@router.post("/ask", response_model=NotesResponse)
async def follow_up_notes_route(req: NotesFollowUpRequest, request: Request):

    try:
        image_reference = None
        if isinstance(req.previous_notes, dict):
            raw_path = req.previous_notes.get("image_path")
            if isinstance(raw_path, str):
                try:
                    image_reference = scan_path_to_relative(resolve_scan_path(raw_path))
                except ValueError:
                    image_reference = None

        notes = await follow_up_notes(req.topic, req.previous_notes, req.user_prompt)
        await save_notes_entry(
            user_id=request.state.user["uid"],
            topic=req.topic,
            notes_payload=notes.dict(),
            image_path=image_reference,
        )
        return notes

    except Exception as e:
        print("❌ Error in /notes/ask:", e)
        raise HTTPException(status_code=500, detail="Failed to process follow-up question.")