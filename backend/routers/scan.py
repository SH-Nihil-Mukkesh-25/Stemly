# backend/routers/scan.py

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, Header, Form
from openai import AuthenticationError

from auth.auth_middleware import require_firebase_user
from database.history_model import get_user_history, save_scan_history
from services.ai_detector import detect_topic
from services.scan_service import save_scan
from config import FALLBACK_GROQ_API_KEY

router = APIRouter(
    dependencies=[Depends(require_firebase_user)],
    tags=["Scan"],
)


@router.post("/upload")
async def upload_scan(
    request: Request,
    file: UploadFile = File(...),
    ocr_text: str = Form(""), # Received from Flutter ML Kit
    x_ai_api_key: str = Header(None, alias="X-AI-API-Key"),
):
    user_id = request.state.user["uid"]
    
    print(f"DEBUG: upload_scan starting for user {user_id}")
    if x_ai_api_key:
        print(f"DEBUG: Received AI API Key: {x_ai_api_key[:5]}...")
    
    print(f"DEBUG: OCR Text received: {ocr_text[:50]}...")

    # 1. Save File (still useful for history/debugging)
    try:
        saved_path = await save_scan(file)
    except Exception as exc:
        print(f"❌ Error saving scan: {exc}")
        raise HTTPException(status_code=500, detail="Failed to save image") from exc

    # 2. Detect Topic (using LOCAL OLLAMA)
    try:
        # We pass ocr_text AND the saved image path for Vision fallback
        topic, variables = await detect_topic(ocr_text, image_path=saved_path, api_key=x_ai_api_key)
        print(f"DEBUG: Local AI success: {topic}, {variables}")
    except Exception as exc:
        print(f"❌ Error detecting topic: {exc}")
        topic = "Unknown"
        variables = []

    # 3. Save History (Skip if DB is disabled, which is handled inside save_scan_history)
    try:
        record_id = await save_scan_history(
            user_id=user_id,
            image_path=saved_path,
            topic=topic,
            variables=variables,
        )
    except Exception as exc:
        print(f"⚠ Warning: Failed to save scan history: {exc}")
        record_id = "error-saving-history"

    return {
        "status": "success",
        "topic": topic,
        "variables": variables,
        "image_path": saved_path,
        "history_id": record_id,
    }


@router.get("/history")
async def history(request: Request):
    user_id = request.state.user["uid"]
    history_data = await get_user_history(user_id)
    return {"history": history_data}


@router.get("/ping")
def ping():
    return {"message": "Backend Connected Successfully!"}