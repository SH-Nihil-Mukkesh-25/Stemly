# backend/database/db.py

from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.server_api import ServerApi
import os
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

if not MONGO_URI:
    raise Exception("❌ MONGO_URI missing in .env")

client = AsyncIOMotorClient(MONGO_URI, server_api=ServerApi("1"))

db = client["stemly_db"]
