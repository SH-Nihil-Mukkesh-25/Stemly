# Setup Guide

Step-by-step guide to get Stemly running on your machine from scratch.

## 1. Get Your API Keys

### Google Gemini (Required)

Gemini powers topic detection, notes generation, quizzes, and the AI tutor.

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click **Create API Key**
4. Copy the key (starts with `AIza...`)

Free tier: 15 requests/minute, 1500 requests/day. Sufficient for development.

### Firebase Project (Required)

Firebase handles user authentication.

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project** and follow the wizard
3. Enable **Authentication** > **Sign-in method** > Enable **Google** and **Email/Password**
4. Go to **Project Settings** > **Service accounts**
5. Click **Generate new private key** — download the JSON file
6. Save it as `backend/serviceAccountKey.json`

For the Flutter app, follow `stemly_app/FIREBASE_SETUP.md` to configure platform-specific files.

### MongoDB Atlas (Required for persistence)

MongoDB stores scan history, notes, and user data.

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas/register)
2. Create a free M0 cluster
3. Under **Database Access**, create a user with read/write permissions
4. Under **Network Access**, add your IP (or `0.0.0.0/0` for development)
5. Click **Connect** > **Drivers** and copy the connection string

The string looks like:
```
mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/stemly?retryWrites=true&w=majority
```

### Optional: Additional AI Providers

These are only needed if you want to test the multi-provider chat feature.

| Provider | Get a key at | Used for |
|----------|-------------|----------|
| xAI (Grok) | [console.x.ai](https://console.x.ai/) | Chat/tutor (alternative) |
| OpenAI | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) | Chat/tutor (alternative) |
| Groq | [console.groq.com/keys](https://console.groq.com/keys) | Chat/tutor (alternative) |
| AIML | [aimlapi.com](https://aimlapi.com/) | Image generation |

---

## 2. Platform-Specific Setup

### Windows

**Prerequisites**:

```powershell
# Python (via winget or python.org)
winget install Python.Python.3.11

# Flutter (via chocolatey or flutter.dev)
choco install flutter

# Git
winget install Git.Git

# Android Studio (for Android emulator)
winget install Google.AndroidStudio
```

**Backend**:

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements-dev.txt
copy .env.example .env
# Edit .env with your API keys
uvicorn main:app --reload
```

**Flutter app**:

```powershell
cd stemly_app
flutter pub get
flutter run
```

### macOS

**Prerequisites**:

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Python
brew install python@3.11

# Flutter
brew install --cask flutter

# Xcode (for iOS development)
xcode-select --install
# Also install Xcode from the App Store

# Android Studio (for Android)
brew install --cask android-studio

# CocoaPods (for iOS)
sudo gem install cocoapods
```

**Backend**:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -r requirements-dev.txt
cp .env.example .env
# Edit .env with your API keys
uvicorn main:app --reload
```

**Flutter app**:

```bash
cd stemly_app
flutter pub get

# iOS: install pods
cd ios && pod install && cd ..

flutter run
```

### Linux (Ubuntu/Debian)

**Prerequisites**:

```bash
# Python
sudo apt update
sudo apt install python3.11 python3.11-venv python3-pip

# Flutter — follow https://docs.flutter.dev/get-started/install/linux
sudo snap install flutter --classic

# Android Studio
sudo snap install android-studio --classic

# Additional dependencies for Flutter Linux desktop
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev
```

**Backend**:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -r requirements-dev.txt
cp .env.example .env
# Edit .env with your API keys
uvicorn main:app --reload
```

**Flutter app**:

```bash
cd stemly_app
flutter pub get
flutter run -d linux  # or connect an Android device
```

---

## 3. Docker Setup (Alternative)

If you prefer Docker, you can run MongoDB and the backend without installing Python locally.

**Prerequisites**: [Docker Desktop](https://www.docker.com/products/docker-desktop/)

```bash
# From the repo root
cp backend/.env.example backend/.env
# Edit backend/.env with your API keys (MONGO_URI will be overridden by Docker)

# Start MongoDB + backend
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f backend
```

The backend will be available at `http://localhost:8000`. MongoDB runs on port 27017.

You still need Flutter installed locally to run the mobile app:

```bash
cd stemly_app
flutter pub get
flutter run
```

To stop:

```bash
docker compose down
```

---

## 4. Configure Environment Variables

Edit `backend/.env` with your actual values:

```env
# Required
MONGO_URI=mongodb+srv://user:pass@cluster0.xxxxx.mongodb.net/stemly
GOOGLE_API_KEY=AIzaSy...your_key_here
FIREBASE_CREDENTIALS_FILE=serviceAccountKey.json

# Optional
AIML_API_KEY=your_aiml_key
```

See `backend/.env.example` for all available options.

---

## 5. Verify Everything Works

### Backend

```bash
cd backend
source .venv/bin/activate  # or .venv\Scripts\activate on Windows
uvicorn main:app --reload
```

Check these URLs:
- http://localhost:8000/ — should return `{"message": "Backend is running!"}`
- http://localhost:8000/docs — should show Swagger UI
- http://localhost:8000/scan/ping — should respond

### Flutter app

```bash
cd stemly_app
flutter run
```

The app should:
1. Show the splash screen
2. Navigate to the login screen
3. Allow Google Sign-In (if Firebase is configured)
4. Open the camera/scanner on the home screen

### End-to-end test

1. Sign in to the app
2. Take a photo of a physics problem (or use a screenshot)
3. The app should detect the topic and show notes
4. Tap "Visualize" to see an interactive simulation
5. Try the quiz feature

---

## Troubleshooting

### "MONGO_URI not set" warning

The backend starts without MongoDB. Database features (history, saved states) will be disabled, but scanning, notes, and quizzes still work.

### Firebase token errors

- Ensure `serviceAccountKey.json` exists in `backend/`
- The service account must be from the same Firebase project used in the Flutter app
- Firebase tokens expire after 1 hour — re-authenticate in the app

### "flutter pub get" hangs or fails

```bash
flutter doctor   # check for issues
flutter clean
flutter pub cache clean
flutter pub get
```

### Android emulator can't reach backend

The Android emulator uses `10.0.2.2` to reach the host machine's `localhost`. The app is configured for this by default. If using a physical device, you'll need to update the API base URL in the Flutter service files or use a tool like ngrok.

### Port already in use

```bash
# Find what's using port 8000
# Windows
netstat -ano | findstr :8000
# macOS/Linux
lsof -i :8000
```
