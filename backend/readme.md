# Stemly Backend

FastAPI backend powering Stemly's AI-driven STEM learning features.

## Tech Stack

- **Framework**: FastAPI (Python 3.10+)
- **Database**: MongoDB (via Motor async driver)
- **Auth**: Firebase Admin SDK (ID token verification)
- **AI**: Google Gemini 2.5 Flash (vision + text)
- **Deployment**: Vercel

## Prerequisites

| Tool | Version | Installation |
|------|---------|-------------|
| Python | 3.10+ | [python.org](https://www.python.org/downloads/) |
| pip | latest | Included with Python |
| MongoDB | 6.0+ or Atlas | [mongodb.com](https://www.mongodb.com/try/download/community) |
| Firebase project | — | [Firebase Console](https://console.firebase.google.com/) |
| Gemini API key | — | [AI Studio](https://aistudio.google.com/apikey) |

## Installation

```bash
# From the repository root
cd backend

# Create virtual environment
python -m venv .venv

# Activate it
# Windows
.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate

# Install runtime dependencies
pip install -r requirements.txt

# Install development tools (linting, testing, formatting)
pip install -r requirements-dev.txt
```

## Configuration

Copy the example env file and fill in your values:

```bash
cp .env.example .env
```

Required variables:

| Variable | Description |
|----------|-------------|
| `MONGO_URI` | MongoDB connection string |
| `GOOGLE_API_KEY` | Google Gemini API key |
| `FIREBASE_CREDENTIALS_FILE` | Path to Firebase service account JSON |

See `.env.example` for all available options and documentation.

## Running Locally

```bash
# Start the development server with auto-reload
uvicorn main:app --reload

# Or specify host/port
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The server starts at `http://localhost:8000`.

- **Interactive API docs**: http://localhost:8000/docs (Swagger UI)
- **Alternative docs**: http://localhost:8000/redoc (ReDoc)
- **Health check**: http://localhost:8000/ (returns `{"message": "Backend is running!"}`)

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | No | Health check |
| POST | `/scan/upload` | Yes | Upload and analyze a STEM diagram |
| GET | `/scan/history/{user_id}` | Yes | Get scan history for a user |
| POST | `/notes/generate` | Yes | Generate AI notes from a topic |
| POST | `/visualiser/generate` | Yes | Generate physics simulation data |
| POST | `/visualiser/engine/generate` | Yes | Generate visualiser engine code |
| POST | `/quiz/generate` | Yes | Generate quiz from STEM content |
| POST | `/chat/` | Yes | AI tutor chat |
| GET | `/auth/me` | Yes | Get current authenticated user |

All authenticated endpoints require a Firebase ID token in the `Authorization: Bearer <token>` header.

## Running Tests

```bash
# Run all tests
pytest -v

# Run with coverage report
pytest --cov=. --cov-report=term-missing -v

# Run a specific test file
pytest test_db_connection.py -v
```

## Code Quality

```bash
# Format code
black .

# Check formatting without modifying
black --check .

# Lint
flake8 . --max-line-length=120

# Type checking
mypy . --ignore-missing-imports
```

## Project Structure

```
backend/
├── main.py                  # FastAPI app entry point
├── config.py                # Environment & AI configuration
├── requirements.txt         # Runtime dependencies
├── requirements-dev.txt     # Development dependencies
├── .env.example             # Environment template
├── vercel.json              # Vercel deployment config
│
├── auth/
│   ├── firebase.py          # Firebase token verification
│   ├── auth_middleware.py   # Authentication dependency
│   └── auth_router.py      # /auth endpoints
│
├── routers/
│   ├── scan.py              # /scan endpoints
│   ├── notes.py             # /notes endpoints
│   ├── visualiser.py        # /visualiser endpoints
│   ├── visualiser_engine.py # /visualiser/engine endpoints
│   ├── quiz_router.py       # /quiz endpoints
│   └── chat.py              # /chat endpoints
│
├── services/
│   ├── ai_detector.py       # Gemini vision integration
│   ├── storage.py           # Image file management
│   └── history_service.py   # In-memory scan history
│
├── database/
│   ├── db.py                # MongoDB connection
│   ├── user_model.py        # User upsert operations
│   ├── history_model.py     # Scan history persistence
│   ├── notes_model.py       # Notes persistence
│   └── visualiser_model.py  # Visualiser persistence
│
└── static/
    └── scans/               # Uploaded images
```

## Troubleshooting

### MongoDB connection fails

- Verify `MONGO_URI` is correct in `.env`
- If using Atlas, ensure your IP is whitelisted in Network Access
- The backend will start without MongoDB but database features will be disabled

### Firebase token verification fails

- Ensure `FIREBASE_CREDENTIALS_FILE` points to a valid service account JSON
- The service account must belong to the same Firebase project as the frontend
- Check that the token hasn't expired (Firebase tokens last 1 hour)

### Gemini API errors

- Verify `GOOGLE_API_KEY` is set and valid
- Check your API quota at [AI Studio](https://aistudio.google.com/)
- The backend checks `is_ai_enabled()` — if the key is missing, AI features return errors

### Import errors on startup

- Make sure you're running from the `backend/` directory
- Ensure your virtual environment is activated
- Run `pip install -r requirements.txt` to install all dependencies
