# Stemly 🚀

**Scan → Analyze → Visualize → Study**

A next-generation STEM learning platform that transforms any diagram, problem, or concept into an interactive learning experience powered by AI-driven visualizations and comprehensive study notes.

## 🌟 Overview

Stemly activates two powerful AI modes the moment you scan any STEM content:

- **AI Visualiser**: Dynamic, parameter-driven simulations with real-time interactive controls
- **AI Notes**: Complete study companion with explanations, formulas, and curated resources

## ✨ Features

### 🎨 AI Visualiser (Primary Tab)
- **Template-based simulations** powered by Flame visual engine
- **Interactive parameters** with sliders and real-time controls
- **Adaptive visualizations** that change based on scanned content
- **AI-regeneration** capability for instant simulation updates
- **Dynamic graphs and equations** that update in real-time

### 📚 AI Notes (Secondary Tab)
- Topic explanations based on scanned content
- Clean, structured notes with key formulas
- Step-by-step problem breakdowns
- Curated online learning resources
- 5-point summary for quick revision
- Common mistakes and misconceptions

## 🔄 How It Works

### Step 1: Scan
Capture any STEM content:
- Physics diagrams
- Math problems
- Circuit diagrams
- Kinematics graphs
- Experiment setups
- Handwritten homework

### Step 2: AI Analysis
The system automatically identifies:
- Topic and sub-topic
- Core concepts involved
- Relevant variables (velocity, angle, resistance, etc.)
- Optimal simulation template

### Step 3: Interactive Learning
**Tab 1 - AI Visualiser** (opens by default)
- Real-time animated simulations
- Adjustable parameters via sliders
- Auto-updating graphs and equations
- Interactive visual explanations

**Tab 2 - AI Notes**
- Comprehensive concept explanations
- Solved examples and best practices
- External learning resources
- Quick revision summaries

### Step 4: AI-Driven Follow-Up
Ask questions in the chat box:
- "Show what happens if acceleration decreases"
- "Increase gravity to 15"
- "Separate horizontal and vertical components"
- "What if refractive index becomes 2.0?"

The AI instantly updates parameters and regenerates simulations, creating an infinite learning sandbox.

## 💡 Example Use Case

**User scans:** A kinematics diagram of a car accelerating on a straight road

**AI identifies:**
- Topic: 1D Kinematics
- Variables: a, v₀, t
- Template: Kinematics Motion

**Tab 1 - AI Visualiser shows:**
- Animated car movement
- Sliders for acceleration, starting velocity, and time
- Interactive v-t and s-t graphs

**User interaction:**
- "Show what happens if acceleration becomes zero after 4 seconds"
- AI updates simulation instantly

**Tab 2 - AI Notes provides:**
- Motion equation explanations
- Formula meanings and applications
- Real-life examples
- Common student mistakes
- Curated resources and quick summary

## 🎯 Why Stemly?

Unlike YouTube, Google Lens, ChatGPT, textbooks, or traditional tutoring, Stemly provides:

- ✅ **Complete learning flow** in one platform
- ✅ **Both visualization AND theory** together
- ✅ **Personalized, interactive experience**
- ✅ **Infinite parameter exploration**
- ✅ **Maximum clarity and engagement**

**Stemly = Scan → AI Visualiser → Adjust Parameters → Ask Questions → Learn Theory**

## 👥 Team: Mugiwara Coders

- [SH Nihil Mukkesh](https://github.com/SH-Nihil-Mukkesh-25) (CB.SC.U4CSE24531)
- [SHRE RAAM P J](https://github.com/SHRE-RAAM-P-J) (CB.SC.U4CSE24548)
- [P Dakshin Raj](https://github.com/Dakshin10) (CB.SC.U4CSE24534)
- [Vibin Ragav S](https://github.com/VibinR-code) (CB.SC.U4CSE24556)

## 🛠️ Technology Stack

- **Visual Engine:** Flame
- **AI Processing:** Advanced topic detection and parameter extraction
- **Simulation System:** Template-based, dynamically generated
- **Interactive UI:** Real-time parameter controls and regeneration

## 🔐 Authentication & User Accounts

Stemly now ships with first-class Google authentication powered by Firebase Auth on the Flutter client and Firebase Admin + MongoDB on the FastAPI backend.

### Backend configuration

1. **Create a Firebase service account**
   - Firebase Console → Project Settings → Service Accounts → Generate New Private Key.
   - Store the JSON file securely (never commit it).
2. **Expose the credentials via environment variables** so `backend/auth/firebase.py` can bootstrap Firebase Admin:

```env
# backend/.env
MONGO_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/stemly
GEMINI_API_KEY=your_gemini_key
FIREBASE_CREDENTIALS_FILE=C:\secrets\stemly-service-account.json
# or instead of a file path:
# FIREBASE_CREDENTIALS_JSON={"type":"service_account",...}
```

3. **Install backend dependencies** and run the API:

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

`auth/auth_middleware.py` verifies every `Authorization: Bearer <Firebase ID token>` header, persists the user inside the `users` collection, and exposes the hydrated profile on `request.state.user`. Collections `scans`, `notes`, and `visualiser` are all automatically scoped by `user_id`, ensuring per-user isolation.

### Flutter configuration

1. Run `flutterfire configure` to generate a real `lib/firebase_options.dart` file for every target platform.
2. Install the new authentication helpers:

```bash
cd stemly_app
flutter pub get
flutter run --dart-define=STEMLY_API_BASE_URL=https://api.yourdomain.com
```

3. Use the provided `FirebaseAuthService` + `GoogleSignInButton` for Google login, profile caching, and ID token retrieval. The service keeps the latest ID token inside secure storage and exposes helpers for attaching the header to HTTP calls:

```dart
final authService = context.read<FirebaseAuthService>();
final response = await http.get(
  Uri.parse('https://api.yourdomain.com/scan/history'),
  headers: await authService.authenticatedHeaders(),
);
```

`AccountScreen` now demonstrates a drop-in login UI, token-aware logout, and backend warm-up via the `/auth/me` endpoint.

### API smoke test

```bash
curl https://api.yourdomain.com/auth/me \
  -H "Authorization: Bearer $(firebase id token here)"
```

The response returns the verified Firebase profile, confirming that FastAPI + Firebase Admin + MongoDB are wired correctly.

## 📝 License

[Add your license here]

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Contact

For inquiries and collaboration:
- LinkedIn: [SH Nihil Mukkesh](https://www.linkedin.com/in/sh-nihil-mukkesh/)

---

*Transforming STEM education, one scan at a time.*
