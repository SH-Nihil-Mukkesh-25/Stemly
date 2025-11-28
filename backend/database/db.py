# backend/database/db.py

from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.server_api import ServerApi
import os
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

# Make MongoDB optional for development/testing
if not MONGO_URI:
    print("⚠ MONGO_URI not set in .env - database features will be disabled")
    client = None
    db = None
else:
    client = AsyncIOMotorClient(MONGO_URI, server_api=ServerApi("1"))
    db = client["stemly_db"]