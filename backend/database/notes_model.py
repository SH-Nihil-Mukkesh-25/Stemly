from datetime import datetime
from typing import Any, Dict, Optional

from .db import db

notes_collection = db["notes"]


async def save_notes_entry(
    user_id: str,
    topic: str,
    notes_payload: Dict[str, Any],
    image_path: Optional[str] = None,
):
    if not user_id:
        raise ValueError("user_id is required to save notes.")

    doc = {
        "user_id": user_id,
        "topic": topic,
        "notes": notes_payload,
        "image_path": image_path,
        "timestamp": datetime.utcnow(),
    }

    result = await notes_collection.insert_one(doc)
    return str(result.inserted_id)


async def get_notes_for_user(user_id: str, limit: int = 20):
    if not user_id:
        return []

    cursor = (
        notes_collection.find({"user_id": user_id})
        .sort("timestamp", -1)
        .limit(limit)
    )

    notes = []
    async for entry in cursor:
        entry["_id"] = str(entry["_id"])
        notes.append(entry)
    return notes

