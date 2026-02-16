# Development Guide

Practical guide for developing Stemly day-to-day.

## Git Workflow

We use a feature-branch workflow on `master`.

```
master (stable)
  └── feat/add-wave-simulation     ← your feature branch
  └── fix/quiz-scoring-bug         ← your bugfix branch
```

### Working on a feature

```bash
# Start from latest master
git checkout master
git pull origin master

# Create your branch
git checkout -b feat/your-feature-name

# Make changes, commit with conventional commits
git add -A
git commit -m "feat(visualiser): add wave motion simulation"

# Push and open a PR
git push -u origin feat/your-feature-name
```

See [CONTRIBUTING.md](../CONTRIBUTING.md) for branch naming and commit conventions.

### Keeping your branch up to date

```bash
git fetch origin
git rebase origin/master
# Resolve any conflicts, then:
git push --force-with-lease
```

---

## Local Development

### Running backend and frontend together

**Terminal 1 — Backend**:
```bash
cd backend
source .venv/bin/activate
uvicorn main:app --reload --port 8000
```

**Terminal 2 — Flutter**:
```bash
cd stemly_app
flutter run
```

The Flutter app connects to `http://10.0.2.2:8080` (Android emulator) or `https://stemly-backend.vercel.app` (production). To switch, update the base URL in the service files.

### Using the Makefile

```bash
make dev-backend   # Start backend with hot reload
make dev-flutter   # Run Flutter app
make test          # Run all tests
make lint          # Check code quality
make format        # Auto-format everything
```

---

## Testing Strategy

### Backend tests

```bash
cd backend
pytest -v                                    # Run all tests
pytest --cov=. --cov-report=term-missing    # With coverage
pytest test_db_connection.py -v              # Single file
pytest -k "test_quiz" -v                     # By keyword
```

**Writing a new test**:

```python
# backend/test_my_feature.py
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_ping():
    response = client.get("/scan/ping")
    assert response.status_code == 200
```

For async tests:

```python
import pytest
from httpx import AsyncClient, ASGITransport
from main import app

@pytest.mark.asyncio
async def test_root():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/")
    assert response.status_code == 200
```

### Flutter tests

```bash
cd stemly_app
flutter test                           # Run all tests
flutter test --coverage                # With coverage
flutter test test/widget_test.dart     # Single file
```

**Writing a widget test**:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Quiz shows score', (WidgetTester tester) async {
    // Build widget, interact, assert
  });
}
```

---

## Debugging

### Backend

**FastAPI auto-docs**: Visit `http://localhost:8000/docs` to test endpoints interactively.

**Print debugging**: The codebase uses `print()` statements with emoji prefixes for visibility:
- `print("  ...")` — Firebase errors
- `print("  ...")` — Warnings (DB disabled, fallback used)
- `print("  ...")` — Failures

**Request logging**: Add to `main.py` temporarily:

```python
from fastapi import Request

@app.middleware("http")
async def log_requests(request: Request, call_next):
    print(f"→ {request.method} {request.url.path}")
    response = await call_next(request)
    print(f"← {response.status_code}")
    return response
```

### Flutter

**Flutter DevTools**: Press `d` in the terminal while `flutter run` is active, or launch from VS Code.

**Network debugging**: The service layer in `lib/services/` prints API responses. Add temporary logging:

```dart
print('API Response: ${response.statusCode} ${response.body}');
```

**Widget Inspector**: Press `i` during `flutter run` to toggle the widget inspector overlay.

---

## Adding a New Physics Simulation

The visualiser uses a factory pattern, making new simulations straightforward to add.

### Step 1: Create the widget

Create `stemly_app/lib/visualiser/your_simulation.dart`:

```dart
import 'package:flutter/material.dart';

class YourSimulationWidget extends StatefulWidget {
  final Map<String, dynamic> parameters;
  final Function(Map<String, dynamic>)? onSimulationUpdate;

  const YourSimulationWidget({
    super.key,
    required this.parameters,
    this.onSimulationUpdate,
  });

  @override
  State<YourSimulationWidget> createState() => _YourSimulationWidgetState();
}

class _YourSimulationWidgetState extends State<YourSimulationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _YourSimulationPainter(
            progress: _controller.value,
            // Pass parameters from widget.parameters
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _YourSimulationPainter extends CustomPainter {
  final double progress;

  _YourSimulationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Your physics rendering logic here
  }

  @override
  bool shouldRepaint(covariant _YourSimulationPainter old) => true;
}
```

### Step 2: Register in the factory

Edit `stemly_app/lib/visualiser/visualiser_factory.dart`:

```dart
case 'your_template_id':
  return YourSimulationWidget(
    parameters: template.parameters,
    onSimulationUpdate: onUpdate,
  );
```

### Step 3: Add the backend template

In the visualiser router, add your template to the topic matching logic with:
- `templateId` — unique string identifier
- `parameters` — each with `value`, `min`, `max`
- `metadata` — any extra data your widget needs

### Step 4: Test

1. Upload an image related to your topic
2. Check that the backend returns your template
3. Verify the Flutter widget renders correctly
4. Test parameter sliders

---

## Extending AI Capabilities

### Adding a new AI-powered endpoint

1. **Create the service** (`backend/services/ai_yourfeature.py`):

```python
import requests
from config import GEMINI_API_KEY, get_gemini_url

async def your_ai_function(input_data: str, api_key: str = None):
    key = api_key or GEMINI_API_KEY
    url = get_gemini_url()

    payload = {
        "contents": [{"parts": [{"text": f"Your prompt: {input_data}"}]}],
        "generationConfig": {"responseMimeType": "application/json"}
    }

    response = requests.post(url, json=payload)
    return response.json()
```

2. **Create the router** (`backend/routers/yourfeature.py`):

```python
from fastapi import APIRouter, Depends
from auth.auth_middleware import require_firebase_user

router = APIRouter(
    prefix="/yourfeature",
    dependencies=[Depends(require_firebase_user)],
)

@router.post("/generate")
async def generate(request: YourRequest):
    result = await your_ai_function(request.input)
    return result
```

3. **Register the router** in `backend/main.py`:

```python
from routers import yourfeature
app.include_router(yourfeature.router)
```

### Gemini API patterns used in Stemly

- **JSON mode**: Set `responseMimeType: "application/json"` for structured output
- **Vision**: Include image bytes as `inline_data` with `mime_type`
- **Token limits**: Use `maxOutputTokens` (8192 for notes, 800 for chat)
- **Retry logic**: 3 attempts with exponential backoff on 429/500

---

## Performance Profiling

### Flutter

```bash
# Run in profile mode
flutter run --profile

# Open DevTools
# Press 'p' for performance overlay
# Press 'P' for detailed performance metrics
```

Key areas to watch:
- **Visualiser frame rate**: Should maintain 60 FPS. Heavy `CustomPainter.paint()` calls can drop frames.
- **Image loading**: Large scan images should be cached or resized.
- **API call latency**: Notes generation can take 3-5 seconds. Show loading indicators.

### Backend

```bash
# Simple timing
time curl -X POST http://localhost:8000/notes/generate ...

# For detailed profiling, add timing middleware:
import time

@app.middleware("http")
async def timing_middleware(request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    response.headers["X-Process-Time"] = str(duration)
    return response
```

Typical response times:
- `/scan/upload`: 2-5s (Gemini Vision)
- `/notes/generate`: 3-8s (Gemini text generation, 8192 tokens)
- `/quiz/generate`: 2-4s
- `/visualiser/generate`: <100ms (template lookup, no AI call)
- `/chat/ask`: 1-3s

---

## Project Conventions

| Convention | Detail |
|-----------|--------|
| Python formatting | `black` with default settings |
| Python linting | `flake8` with 120 char line limit |
| Dart formatting | `dart format` (built-in) |
| Dart linting | `flutter analyze` |
| Commit messages | Conventional Commits (`feat:`, `fix:`, `docs:`, etc.) |
| Branch names | `feat/`, `fix/`, `docs/`, `refactor/`, `test/` prefixes |
| API responses | JSON, consistent `{detail: "..."}` for errors |
| File uploads | UUID filenames, magic-byte validation |
