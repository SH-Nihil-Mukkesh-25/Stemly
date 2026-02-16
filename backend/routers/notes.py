from fastapi import APIRouter, Depends, HTTPException, Request, Header

from auth.auth_middleware import require_firebase_user
from config import FALLBACK_GROQ_API_KEY
from database.notes_model import save_notes_entry
from models.notes_models import NotesFollowUpRequest, NotesGenerateRequest
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

@router.post("/generate")
async def generate_notes_route(
    req: NotesGenerateRequest, 
    request: Request,
    x_ai_api_key: str = Header(None, alias="X-AI-API-Key"),
    x_groq_api_key: str = Header(None, alias="x-groq-api-key")
):
    # Use X-AI-API-Key first (Flutter), then legacy header, then env fallback
    api_key_to_use = x_ai_api_key or x_groq_api_key or FALLBACK_GROQ_API_KEY

    local_path = None
    relative_path = None
    if req.image_path:
        try:
            local_path = resolve_scan_path(req.image_path)
            relative_path = scan_path_to_relative(local_path)
        except ValueError:
            pass # Be lenient for invalid paths
            local_path = None
            relative_path = None

    user_id = request.state.user["uid"]

    try:
        image_arg = relative_path or req.image_path
        # Pass api_key (dummy) and ocr_text
        notes = await generate_notes(req.topic, req.variables, image_arg, ocr_text=req.ocr_text, api_key=api_key_to_use)
        # Non-blocking DB save (fail-safe)
        try:
            await save_notes_entry(
                user_id=user_id,
                topic=req.topic,
                notes_payload=notes.dict(),
                image_path=relative_path or req.image_path,
            )
        except Exception as db_err:
             print(f"⚠ Non-critical DB Error (Notes Save Failed): {db_err}")

        # Wrap response to match Flutter's expected format
        return {"notes": notes.dict()}

    except Exception as e:
        print("❌ Error in /notes/generate:", e)
        raise HTTPException(status_code=500, detail="Failed to generate notes.")



# -----------------------------------------
# 2. Follow-up Question
# -----------------------------------------

@router.post("/ask")
async def follow_up_notes_route(
    req: NotesFollowUpRequest, 
    request: Request,
    x_ai_api_key: str = Header(None, alias="X-AI-API-Key"),
    x_groq_api_key: str = Header(None, alias="x-groq-api-key")
):
    # Use X-AI-API-Key first (Flutter), then legacy header, then env fallback
    api_key_to_use = x_ai_api_key or x_groq_api_key or FALLBACK_GROQ_API_KEY

    try:
        image_reference = None
        if isinstance(req.previous_notes, dict):
            raw_path = req.previous_notes.get("image_path")
            if isinstance(raw_path, str):
                try:
                    image_reference = scan_path_to_relative(resolve_scan_path(raw_path))
                except ValueError:
                    image_reference = None
        
        # Pass api_key to follow-up service
        notes = await follow_up_notes(req.topic, req.previous_notes, req.user_prompt, api_key=api_key_to_use)
        # Non-blocking DB save (fail-safe)
        try:
            await save_notes_entry(
                user_id=request.state.user["uid"],
                topic=req.topic,
                notes_payload=notes.dict(),
                image_path=image_reference,
            )
        except Exception as db_err:
             print(f"⚠ Non-critical DB Error (Follow-up Save Failed): {db_err}")

        # Wrap response to match Flutter's expected format
        return {"notes": notes.dict()}

    except Exception as e:
        print("❌ Error in /notes/ask:", e)
        raise HTTPException(status_code=500, detail="Failed to process follow-up question.")
