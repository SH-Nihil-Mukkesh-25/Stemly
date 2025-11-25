from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from dotenv import load_dotenv
load_dotenv()


from routers import scan

app = FastAPI(title="..")

# CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # allow mobile app
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve static images (scanned files)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Routers
app.include_router(scan.router, prefix="/scan", tags=["Scan"])

@app.get("/")
def root():
    return {"message": "Backend is running!"}
