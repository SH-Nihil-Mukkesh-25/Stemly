from fastapi import APIRouter, HTTPException
import os

from models.notes_models import NotesGenerateRequest, NotesFollowUpRequest, NotesResponse
from services.ai_notes import generate_notes, follow_up_notes

router = APIRouter(
    prefix="/notes",
    tags=["Notes"]
)


# -----------------------------------------
# 1. Generate Full Notes
# -----------------------------------------

@router.post("/generate", response_model=NotesResponse)
async def generate_notes_route(req: NotesGenerateRequest):

    # Validate that the image path points to a real saved scan.
    local_path = req.image_path
    if not os.path.isfile(local_path) and local_path.startswith("static/"):
        local_path = os.path.join(os.getcwd(), local_path)

    if not os.path.isfile(local_path):
        raise HTTPException(
            status_code=400,
            detail="Invalid image_path: scan image not found. "
                   "Use the image_path returned from /scan/upload."
        )

    try:
        notes = await generate_notes(req.topic, req.variables, req.image_path)
        return notes

    except Exception as e:
        print("❌ Error in /notes/generate:", e)
        raise HTTPException(status_code=500, detail="Failed to generate notes.")



# -----------------------------------------
# 2. Follow-up Question
# -----------------------------------------

@router.post("/ask", response_model=NotesResponse)
async def follow_up_notes_route(req: NotesFollowUpRequest):

    try:
        notes = await follow_up_notes(req.topic, req.previous_notes, req.user_prompt)
        return notes

    except Exception as e:
        print("❌ Error in /notes/ask:", e)
        raise HTTPException(status_code=500, detail="Failed to process follow-up question.")
