from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Routers
from auth import auth_router
from routers import notes, scan, visualiser, visualiser_engine

app = FastAPI(title="Stemly Backend")

# ----------------------------
# CORS (Flutter friendly)
# ----------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],         # Allow all for development
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
app.include_router(visualiser.router)  # States storage
app.include_router(visualiser_engine.router)  # Template generation

# ----------------------------
# Root Route
# ----------------------------
@app.get("/")
def root():
    return {"message": "Backend is running!"}