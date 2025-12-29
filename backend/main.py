from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Routers
from auth import auth_router
from routers import notes, scan, visualiser, visualiser_engine, chat
from routers.quiz_router import router as quiz_router

# ----------------------------
# App Initialization
# ----------------------------
app = FastAPI(title="Stemly Backend")

# ----------------------------
# CORS (Flutter Friendly)
# ----------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],         # Allow all for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------
# Static Files
# ----------------------------
app.mount("/static", StaticFiles(directory="static"), name="static")

# ----------------------------
# Routers
# ----------------------------
app.include_router(auth_router.router)
app.include_router(scan.router, prefix="/scan")
app.include_router(notes.router)
app.include_router(visualiser.router)
app.include_router(visualiser_engine.router)

# NEW: Quiz router (prefix already defined in quiz_router.py)
app.include_router(quiz_router)
app.include_router(chat.router)

# ----------------------------
# Root Route
# ----------------------------
@app.get("/")
def root():
    return {"message": "Backend is running!"}
