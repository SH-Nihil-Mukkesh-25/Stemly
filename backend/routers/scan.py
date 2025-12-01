# backend/routers/scan.py

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile

from auth.auth_middleware import require_firebase_user
from database.history_model import get_user_history, save_scan_history
from services.ai_detector import detect_topic
from services.storage import save_scan

router = APIRouter(
    dependencies=[Depends(require_firebase_user)],
    tags=["Scan"],
)


@router.post("/upload")
async def upload_scan(request: Request, file: UploadFile = File(...)):
    user_id = request.state.user["uid"]

    try:
        saved_path = await save_scan(file)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        print(f"❌ Error saving scan: {exc}")
        raise HTTPException(status_code=500, detail="Failed to save image") from exc

    try:
        topic, variables = await detect_topic(saved_path)
    except Exception as exc:
        print(f"❌ Error detecting topic: {exc}")
        # Return fallback values instead of crashing
        topic = "Unknown"
        variables = []

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