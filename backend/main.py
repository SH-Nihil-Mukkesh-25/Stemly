from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Routers
from routers import scan
from routers import notes

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
app.include_router(scan.router, prefix="/scan", tags=["Scan"])
app.include_router(notes.router, prefix="/notes", tags=["Notes"])

# ----------------------------
# Root Route
# ----------------------------
@app.get("/")
def root():
    return {"message": "Backend is running!"}
