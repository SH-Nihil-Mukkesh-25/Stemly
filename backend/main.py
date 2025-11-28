from dotenv import load_dotenv
load_dotenv()  # ← This loads your .env file BEFORE anything else

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Routers
from auth import auth_router
from routers import notes, scan, visualiser

app = FastAPI(title="Stemly Backend")

# ----------------------------
# CORS (Flutter friendly)
# ----------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------
# Serve Static Files
# ----------------------------
app.mount("/static", StaticFiles(directory="static"), name="static")

# ----------------------------
# Routers
# ----------------------------
app.include_router(auth_router.router)
app.include_router(scan.router, prefix="/scan")
app.include_router(notes.router)
app.include_router(visualiser.router)

# ----------------------------
# Root Route
# ----------------------------
@app.get("/")
def root():
    return {"message": "Backend is running!"}
