from datetime import datetime
from typing import Any, Dict, List

from .db import db

visualiser_collection = db["visualiser"]


async def save_visualiser_entry(user_id: str, template_id: str, parameters: Dict[str, Any]):
    if not user_id:
        raise ValueError("user_id is required")

    doc = {
        "user_id": user_id,
        "template_id": template_id,
        "parameters": parameters,
        "timestamp": datetime.utcnow(),
    }

    result = await visualiser_collection.insert_one(doc)
    return str(result.inserted_id)


async def get_visualiser_entries(user_id: str, limit: int = 20):
    if not user_id:
        return []

    cursor = (
        visualiser_collection.find({"user_id": user_id})
        .sort("timestamp", -1)
        .limit(limit)
    )

    entries: List[Dict[str, Any]] = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        entries.append(doc)
    return entries

