from datetime import datetime
from typing import Dict, Optional

from .db import db

# Handle case where db is None (MongoDB disabled)
users_collection = db["users"] if db is not None else None


async def record_user_login(user_info: Dict[str, Optional[str]]):
    """
    Upsert the authenticated user inside MongoDB.
    """
    # Skip if database is disabled
    if users_collection is None:
        return

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
    if not uid or users_collection is None:
        return None
    return await users_collection.find_one({"_id": uid})
