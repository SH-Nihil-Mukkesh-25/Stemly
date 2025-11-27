from datetime import datetime
from typing import Dict, Optional

from .db import db

users_collection = db["users"]


async def record_user_login(user_info: Dict[str, Optional[str]]):
    """
    Upsert the authenticated user inside MongoDB.
    """
    uid = user_info.get("uid")
    if not uid:
        raise ValueError("Firebase user info missing 'uid'.")

    now = datetime.utcnow()

    doc = {
        "_id": uid,
        "name": user_info.get("name"),
        "email": user_info.get("email"),
        "profile_pic": user_info.get("picture"),
        "created_at": now,
        "last_login": now,
    }

    await users_collection.update_one(
        {"_id": uid},
        {
            "$set": {
                "name": doc["name"],
                "email": doc["email"],
                "profile_pic": doc["profile_pic"],
                "last_login": doc["last_login"],
            },
            "$setOnInsert": {"created_at": doc["created_at"]},
        },
        upsert=True,
    )


async def get_user(uid: str):
    if not uid:
        return None
    return await users_collection.find_one({"_id": uid})

