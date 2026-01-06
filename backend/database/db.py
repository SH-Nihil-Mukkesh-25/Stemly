# # backend/database/db.py

# from motor.motor_asyncio import AsyncIOMotorClient
# from pymongo.server_api import ServerApi
# import os
# from dotenv import load_dotenv

# load_dotenv()

# MONGO_URI = os.getenv("MONGO_URI")

# # Make MongoDB optional for development/testing
# if not MONGO_URI:
#     print("⚠ MONGO_URI not set in .env - database features will be disabled")
#     client = None
#     db = None
# else:
#     client = AsyncIOMotorClient(MONGO_URI, server_api=ServerApi("1"))
#     db = client["stemly_db"]


# backend/database/db.py
# backend/database/db.py

from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.server_api import ServerApi
import os
from dotenv import load_dotenv

import certifi

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

if not MONGO_URI:
    print("⚠ MONGO_URI not set in .env - database disabled")
    client = None
    db = None
else:
    try:
        # Use certifi for secure SSL connection, but allow invalid certs for now to fix handshake error
        print("⚠ MongoDB: Allowing invalid certificates (Development Mode Fix)")
        client = AsyncIOMotorClient(
            MONGO_URI,
            tlsCAFile=certifi.where(),
            server_api=ServerApi("1"),
            connectTimeoutMS=10000,
            socketTimeoutMS=20000,
            retryWrites=True,
            tlsAllowInvalidCertificates=True  # ENABLED to fix TLSV1_ALERT_INTERNAL_ERROR
        )
        db = client["stemly_db"]
    except Exception as e:
        print(f"❌ Critical Error initializing MongoDB: {e}")
        client = None
        db = None

