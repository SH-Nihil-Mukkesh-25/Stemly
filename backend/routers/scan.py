from fastapi import APIRouter, UploadFile, File, Form
from services.storage import save_scan
from services.ai_detector import detect_topic
from services.history_service import add_history, get_user_history

router = APIRouter()

@router.post("/upload")
async def upload_scan(
    user_id: str = Form(...),
    file: UploadFile = File(...)
):
    # 1. Save the scanned image
    saved_path = await save_scan(file)

    # 2. AI detection
    topic, variables = await detect_topic(saved_path)

    # 3. Save to history DB
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


@router.get("/history/{user_id}")
def history(user_id: str):
    return {"history": get_user_history(user_id)}


@router.get("/ping")
def ping():
    return {"message": "Backend Connected Successfully!"}
