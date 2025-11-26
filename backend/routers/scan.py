from fastapi import APIRouter, UploadFile, File, Form
from services.storage import save_scan
from services.ai_detector import detect_topic
from services.history_service import add_history, get_user_history
from services.ai_notes import generate_notes, follow_up_notes
from models.notes_models import NotesGenerateRequest, NotesFollowUpRequest

router = APIRouter()


@router.post("/upload")
async def upload_scan(
    user_id: str = Form(...),
    file: UploadFile = File(...)
):
    saved_path = await save_scan(file)
    topic, variables = await detect_topic(saved_path)

    record_id = add_history(
        user_id=user_id,
        image_path=saved_path,
        topic=topic,
        variables=variables
    )

    return {
        "status": "success",
        "topic": topic,
        "variables": variables,
        "image_path": saved_path,
        "history_id": record_id
    }


@router.post("/notes")
async def generate_full_notes(payload: NotesGenerateRequest):
    notes = await generate_notes(payload.topic, payload.variables)
    return notes.dict()


@router.post("/notes/followup")
async def followup_notes(payload: NotesFollowUpRequest):
    notes = await follow_up_notes(
        payload.topic,
        payload.previous_notes,
        payload.user_prompt
    )
    return notes.dict()


@router.get("/history/{user_id}")
def history(user_id: str):
    return {"history": get_user_history(user_id)}


@router.get("/ping")
def ping():
    return {"message": "Backend Connected Successfully!"}
