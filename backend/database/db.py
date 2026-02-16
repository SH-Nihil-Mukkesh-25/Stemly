import os

import certifi
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.server_api import ServerApi

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
MONGO_ALLOW_INVALID_CERTS = os.getenv("MONGO_ALLOW_INVALID_CERTS", "false").lower() == "true"

if not MONGO_URI:
    print("⚠ MONGO_URI not set in .env - database disabled")
    client = None
    db = None
else:
    try:
        if MONGO_ALLOW_INVALID_CERTS:
            print("⚠ MongoDB running with invalid TLS certs allowed (development only).")
        client = AsyncIOMotorClient(
            MONGO_URI,
            tlsCAFile=certifi.where(),
            server_api=ServerApi("1"),
            connectTimeoutMS=10000,
            socketTimeoutMS=20000,
            retryWrites=True,
            tlsAllowInvalidCertificates=MONGO_ALLOW_INVALID_CERTS,
        )
        db = client["stemly_db"]
    except Exception as e:
        print(f"❌ Critical error initializing MongoDB: {e}")
        client = None
        db = None
