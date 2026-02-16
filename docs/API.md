# API Reference

Complete reference for the Stemly backend REST API.

## Base URL

| Environment | URL |
|------------|-----|
| Local development | `http://localhost:8000` |
| Production | `https://stemly-backend.vercel.app` |

Interactive docs are available at `/docs` (Swagger UI) and `/redoc` (ReDoc) when the server is running.

## Authentication

All endpoints except `/scan/ping` and `/` require a valid Firebase ID token.

Include it in the `Authorization` header:

```
Authorization: Bearer <firebase_id_token>
```

Optionally, pass a custom AI API key to use your own Gemini quota:

```
X-AI-API-Key: <your_gemini_api_key>
```

### Getting a token (for testing)

```bash
# Using Firebase REST API
curl -s -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=<FIREBASE_WEB_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password","returnSecureToken":true}' \
  | jq -r '.idToken'
```

---

## Endpoints

### Health Check

#### `GET /`

Returns server status. No authentication required.

```bash
curl http://localhost:8000/
```

```json
{"message": "Backend is running!"}
```

#### `GET /scan/ping`

Lightweight health check. No authentication required.

```bash
curl http://localhost:8000/scan/ping
```

---

### Scan — Vision Analysis

#### `POST /scan/upload`

Upload an image of a STEM problem. The backend detects the topic and extracts key variables using Gemini Vision.

**Request** (multipart/form-data):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | binary | Yes | Image file (PNG or JPEG, max 5 MB) |
| `ocr_text` | string | No | Pre-extracted text from client-side OCR |

**Headers**: `Authorization: Bearer <token>`, optionally `X-AI-API-Key`

```bash
curl -X POST http://localhost:8000/scan/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@physics_problem.png" \
  -F "ocr_text=A ball is thrown at 50 m/s at 45 degrees"
```

**Response** (200):

```json
{
  "status": "success",
  "topic": "Projectile Motion",
  "variables": ["U", "theta", "g", "R"],
  "image_path": "static/scans/a1b2c3d4.png",
  "history_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Detection pipeline**: Gemini Vision → Gemini Text (if OCR available) → Keyword matching (36+ terms).

---

#### `GET /scan/history`

Retrieve scan history for the authenticated user.

```bash
curl http://localhost:8000/scan/history \
  -H "Authorization: Bearer $TOKEN"
```

**Response** (200):

```json
{
  "history": [
    {
      "id": "...",
      "user_id": "firebase_uid",
      "topic": "Projectile Motion",
      "variables": ["U", "theta"],
      "image_path": "static/scans/abc.png",
      "timestamp": "2025-11-25T11:31:50"
    }
  ]
}
```

---

### Notes — AI Study Notes

#### `POST /notes/generate`

Generate comprehensive study notes for a detected topic.

**Request** (JSON):

```json
{
  "topic": "Projectile Motion",
  "variables": ["U", "theta", "g"],
  "image_path": "static/scans/abc.png",
  "ocr_text": "A ball is thrown..."
}
```

```bash
curl -X POST http://localhost:8000/notes/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"topic":"Projectile Motion","variables":["U","theta","g"]}'
```

**Response** (200):

```json
{
  "explanation": "Projectile motion describes the path of an object launched into the air...",
  "variable_breakdown": {
    "U": "Initial velocity (m/s)",
    "theta": "Launch angle (degrees)",
    "g": "Gravitational acceleration (9.8 m/s^2)"
  },
  "formulas": [
    "R = U^2 * sin(2*theta) / g",
    "H = U^2 * sin^2(theta) / (2*g)",
    "T = 2*U*sin(theta) / g"
  ],
  "example": "A ball is thrown at 50 m/s at 45 degrees...",
  "mistakes": [
    "Forgetting to convert angles to radians",
    "Ignoring air resistance effects"
  ],
  "practice_questions": [
    "What happens to range when angle increases from 30 to 60 degrees?"
  ],
  "summary": ["Key takeaways..."],
  "resources": ["https://example.com/projectile-motion"]
}
```

---

#### `POST /notes/ask`

Ask a follow-up question about previously generated notes.

**Request** (JSON):

```json
{
  "topic": "Projectile Motion",
  "question": "Why is 45 degrees the optimal angle?",
  "notes_context": "..."
}
```

**Response** (200):

```json
{
  "answer": "At 45 degrees, sin(2*theta) = sin(90) = 1, which maximizes..."
}
```

---

### Visualiser — Simulation Generation

#### `POST /visualiser/generate`

Get an interactive simulation template for a topic.

**Request** (JSON):

```json
{
  "topic": "Projectile Motion",
  "variables": ["U", "theta", "g"]
}
```

```bash
curl -X POST http://localhost:8000/visualiser/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"topic":"Projectile Motion","variables":["U","theta","g"]}'
```

**Response** (200):

```json
{
  "templateId": "projectile_motion",
  "title": "Projectile Motion",
  "description": "Interactive projectile motion simulation",
  "parameters": {
    "U": {"value": 50.0, "min": 0, "max": 100},
    "theta": {"value": 45.0, "min": 0, "max": 90},
    "g": {"value": 9.8, "min": 1, "max": 20}
  }
}
```

**Supported templates**: `projectile_motion`, `free_fall`, `simple_harmonic`, `kinematics`, `optics`, `atom_structure`, `quadratic_graph`, `equation_plotter`, water/methane/ammonia/co2 molecules, `boyles_law`, `charles_law`, and more (19+ total).

---

#### `POST /visualiser/update`

Adjust simulation parameters using natural language.

**Request** (JSON):

```json
{
  "template_id": "projectile_motion",
  "parameters": {"U": 50.0, "theta": 45.0, "g": 9.8},
  "user_prompt": "What if gravity was half?"
}
```

**Response** (200):

```json
{
  "parameters": {"U": 50.0, "theta": 45.0, "g": 4.9},
  "explanation": "Reducing gravity to 4.9 m/s^2 doubles the range and flight time."
}
```

---

#### `POST /visualiser/states`

Save the current simulation state.

**Request** (JSON):

```json
{
  "template_id": "projectile_motion",
  "parameters": {"U": 50.0, "theta": 45.0, "g": 9.8}
}
```

#### `GET /visualiser/states`

Retrieve saved simulation states for the authenticated user.

---

#### `POST /visualiser/generate-image`

Generate an educational diagram using AIML's image generation API.

**Request** (JSON):

```json
{
  "prompt": "Projectile motion trajectory diagram with labeled components"
}
```

**Response** (200):

```json
{
  "image_url": "https://api.aiml.com/generated/abc123.png"
}
```

---

#### `POST /visualiser/chat`

Chat about the current simulation — ask questions or request parameter changes.

**Request** (JSON):

```json
{
  "user_prompt": "Why does the ball go higher when I increase the angle?",
  "topic": "Projectile Motion",
  "template_id": "projectile_motion",
  "parameters": {"U": 50.0, "theta": 60.0, "g": 9.8}
}
```

**Response** (200):

```json
{
  "response": "Increasing the angle gives more vertical velocity component...",
  "parameter_updates": null,
  "update_type": "explanation"
}
```

`update_type` can be `"explanation"`, `"parameter_change"`, or `"both"`.

---

### Chat — AI Tutor

#### `POST /chat/ask`

General AI tutor endpoint for physics questions in the context of a visualiser.

**Request** (JSON):

```json
{
  "user_prompt": "Explain the relationship between velocity and angle",
  "topic": "Projectile Motion",
  "variables": ["velocity", "angle"],
  "image_path": "static/scans/abc.png",
  "current_params": {"U": 50.0, "theta": 45.0},
  "template_id": "projectile_motion"
}
```

**Response** (200):

```json
{
  "response": "The horizontal and vertical velocity components are...",
  "parameter_updates": {"theta": 30.0},
  "update_type": "both"
}
```

---

### Quiz — Auto-Generated Quizzes

#### `GET /quiz/generate`

Generate AI-powered multiple-choice questions for a topic.

**Query parameters**:

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `topic` | string | required | STEM topic name |
| `count` | int | 10 | Number of questions |

```bash
curl "http://localhost:8000/quiz/generate?topic=Kinematics&count=5" \
  -H "Authorization: Bearer $TOKEN"
```

**Response** (200):

```json
{
  "topic": "Kinematics",
  "questions": [
    {
      "question": "A car accelerates from rest at 2 m/s^2. What is its velocity after 5 seconds?",
      "options": ["5 m/s", "10 m/s", "15 m/s", "20 m/s"],
      "correct_index": 1,
      "explanation": "Using v = u + at: v = 0 + 2(5) = 10 m/s",
      "takeaway": "v = u + at is the fundamental kinematics equation"
    }
  ]
}
```

Falls back to built-in sample quizzes if AI generation fails.

---

#### `GET /quiz/questions/{topic_id}`

Get static pre-built questions for a topic.

| topic_id | Topic |
|----------|-------|
| 1 | Force & Motion |
| 2 | Algebra |

---

#### `POST /quiz/submit`

Submit answers and receive scoring.

**Request** (JSON):

```json
{
  "answers": [
    {"question_id": 101, "selected_index": 1},
    {"question_id": 102, "selected_index": 3}
  ]
}
```

**Response** (200):

```json
{
  "score": 2,
  "total": 2,
  "correct_questions": [101, 102]
}
```

---

### Auth

#### `GET /auth/me`

Returns the authenticated user's profile from the Firebase token.

```bash
curl http://localhost:8000/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

**Response** (200):

```json
{
  "uid": "firebase_uid_here",
  "email": "student@example.com",
  "name": "Student Name",
  "picture": "https://lh3.googleusercontent.com/..."
}
```

---

## Error Responses

All errors follow a consistent format:

```json
{
  "detail": "Human-readable error message"
}
```

| Status | Meaning | Common causes |
|--------|---------|---------------|
| 400 | Bad Request | Missing required fields, invalid file format, empty upload |
| 401 | Unauthorized | Missing, invalid, or expired Firebase token |
| 404 | Not Found | Unknown template ID, topic not found |
| 422 | Validation Error | Request body doesn't match expected schema |
| 429 | Rate Limited | AI API quota exceeded (retried internally 3 times before returning) |
| 500 | Server Error | AI service down, file system error, database error |

## Rate Limiting

The backend does not enforce its own rate limits, but inherits limits from upstream AI APIs:

| Provider | Limit | Handling |
|----------|-------|----------|
| Google Gemini | Varies by plan (free: 15 RPM) | 3 retries with exponential backoff (1s, 3s, 7s) |
| AIML | Varies | Single attempt, error passed through |

When Gemini returns 429, the backend:
1. Waits with exponential backoff
2. Retries up to 3 times
3. Switches to fallback API key if available
4. Returns error to client only after all retries exhausted

## File Upload Constraints

| Constraint | Value |
|-----------|-------|
| Max file size | 5 MB |
| Allowed types | PNG, JPEG |
| Validation | Magic byte detection (not just file extension) |
| Storage | `static/scans/{uuid}.{ext}` |
| Read chunk size | 1 MB |
