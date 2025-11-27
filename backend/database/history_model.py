# backend/database/history_model.py

from datetime import datetime
from typing import List

from .db import db

scans_collection = db["scans"]


async def save_scan_history(user_id: str, topic: str, variables: list, image_path: str):
    if not user_id:
        raise ValueError("user_id is required to save scan history.")

    doc = {
        "user_id": user_id,
        "topic": topic,
        "variables": variables,
        "image_path": image_path,
        "timestamp": datetime.utcnow(),
    }

    result = await scans_collection.insert_one(doc)
    return str(result.inserted_id)


async def get_user_history(user_id: str) -> List[dict]:
    if not user_id:
        return []

    history: List[dict] = []
    cursor = scans_collection.find({"user_id": user_id}).sort("timestamp", -1)

    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        history.append(doc)

    return history
