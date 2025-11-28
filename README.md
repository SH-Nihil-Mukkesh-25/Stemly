# Stemly 🚀

**Scan → Analyze → Visualize → Study**

A next-generation STEM learning platform that transforms any diagram, problem, or concept into an interactive learning experience powered by AI-driven visualizations and comprehensive study notes.

![Stemly Welcome Screen](https://github.com/user/repo/screenshots/welcome.png)
*Stemly's clean, modern interface with Google authentication*

---

## 🌟 Overview

Stemly is an advanced, AI-powered educational application designed to revolutionize how students learn STEM subjects, with a primary focus on physics. By combining real-time computer vision, generative AI, and interactive simulations, Stemly provides an immersive learning experience through its innovative workflow.

The moment you scan any STEM content, Stemly activates two powerful AI modes:

- **AI Visualiser**: Dynamic, parameter-driven simulations with real-time interactive controls *(currently for Physics, expanding to Math & Chemistry)*
- **AI Notes**: Complete study companion with explanations, formulas, and curated resources *(available for all STEM subjects)*

---

## ✨ Key Features

### 🎨 AI Visualiser (Primary Tab)

![AI Visualiser in Action](https://github.com/user/repo/screenshots/visualiser.png)
*Interactive projectile motion simulation with adjustable parameters*

The core innovation of Stemly - a dynamic, parameter-driven simulation window powered by Flutter's CustomPainter visual engine:

- **Template-based simulations** - Mathematically accurate, not pre-recorded animations
- **Interactive parameters** - Sliders and real-time controls for all variables
- **Adaptive visualizations** - Automatically adjusts based on scanned content
- **AI-regeneration** - Instant simulation updates based on natural language requests
- **Dynamic graphs and equations** - Real-time physics calculations with frame-accurate rendering
- **60 FPS performance** - Smooth, professional-grade animations

**Currently Supported Simulations (Physics):**
- Projectile Motion
- Simple Harmonic Motion (SHM)
- Optics (Refraction, Reflection)
- 1D Kinematics
- Circuits (Ohm's Law)
- And more physics topics...

> **Note:** Visualizations are currently available for **Physics topics only**. We're working hard to bring this powerful feature to **Mathematics and Chemistry** soon!

### 📚 AI Notes (Secondary Tab)

![AI Notes Interface](https://github.com/user/repo/screenshots/notes.png)
*Comprehensive study notes with structured sections*

A full study companion generated from your scanned content:

- **Concept Explanation** - Clear, detailed explanations tailored to the scanned image
- **Variable Breakdown** - Understanding each parameter in the problem
- **Key Formulas** - Mathematical equations with physical meaning
- **Worked Examples** - Step-by-step problem solutions
- **Common Mistakes** - Pitfalls to avoid
- **Practice Questions** - Test your understanding
- **5-Point Summary** - Quick revision bullet points
- **Curated Resources** - Best online learning materials and video links

---

## 🔄 How It Works

### Step 1: Scan

![Scan Interface](https://github.com/user/repo/screenshots/home.png)
*Simple, intuitive home screen - just tap to scan*

Capture any STEM content using your device camera:
- Physics diagrams
- Math problems
- Circuit diagrams
- Kinematics graphs
- Laboratory experiments
- Handwritten homework

**AI Image Recognition:**
- Powered by Google Gemini Vision API
- Extracts handwritten or printed text
- Recognizes diagrams, graphs, and schematics
- Classifies topics with high accuracy

### Step 2: AI Analysis

The system immediately analyzes and identifies:
- Main topic and sub-topic
- Core concepts involved
- Relevant variables (velocity, angle, resistance, gravity, etc.)
- Optimal simulation template

**Example Detection:**
```
Scanned: Projectile motion diagram
↓
Topic: Projectile Motion (Kinematics)
Variables: initial velocity (u), angle (θ), gravity (g)
Template: Projectile Motion Simulator
```

### Step 3: Interactive Learning

Two tabs appear automatically after scanning:

**Tab 1 - AI Visualiser** (opens by default)
- Real-time animated physics simulation
- Adjustable parameters via interactive sliders
- Auto-updating velocity-time, position-time graphs
- Live equation displays with current values
- Labeled components for clarity

**Tab 2 - AI Notes**
- Comprehensive concept explanations
- Formula derivations and meanings
- Solved examples with detailed steps
- External learning resources
- Quick revision summaries
- Concept clarification questions

### Step 4: AI-Driven Follow-Up

![Chat with AI](https://github.com/user/repo/screenshots/visualiser.png)
*Chat interface below the visualiser for natural language control*

Ask questions in natural language to modify simulations:
- *"Show what happens if acceleration decreases"*
- *"Increase gravity to 15 m/s²"*
- *"Separate horizontal and vertical components"*
- *"What if the refractive index becomes 2.0?"*

**How it works:**
1. AI processes your natural language request
2. Determines which parameters need adjustment
3. Returns updated JSON configuration
4. Frontend seamlessly regenerates the simulation

This creates an **infinite learning sandbox** where students can freely explore "what-if" scenarios.

---

## 💡 Real-World Example

**Scenario:** User scans a kinematics diagram of a car accelerating on a straight road.

**AI identifies:**
- Topic: 1D Kinematics
- Variables: a (acceleration), v₀ (initial velocity), t (time)
- Template: Linear Motion Simulator

**Tab 1 - AI Visualiser shows:**
- Animated car moving along a road
- Interactive sliders: acceleration, starting velocity, time
- Graph buttons: velocity-time plot, position-time plot
- Real-time equation display: v = v₀ + at, s = v₀t + ½at²

**User asks:** *"Show what happens if acceleration becomes zero after 4 seconds"*

**AI response:** Updates the simulation instantly, showing constant velocity motion after t=4s with smooth transition.

**Tab 2 - AI Notes provides:**
- Explanation of motion equations
- Physical meaning of each term
- Real-life examples (car braking, rocket launch)
- Common mistakes students make
- Curated resources (Khan Academy, YouTube videos)
- 5-point summary for quick revision

---

## 🎯 Why Stemly?

Unlike YouTube, Google Lens, ChatGPT, textbooks, or traditional tutoring, Stemly provides **everything in one place**:

| Feature | Stemly | YouTube | Textbooks | ChatGPT | Google Lens |
|---------|--------|---------|-----------|---------|-------------|
| Instant Scanning | ✅ | ❌ | ❌ | ❌ | ✅ |
| Interactive Simulations | ✅ | ❌ | ❌ | ❌ | ❌ |
| AI-Controlled Parameters | ✅ | ❌ | ❌ | ❌ | ❌ |
| Comprehensive Notes | ✅ | ⚠️ | ✅ | ✅ | ❌ |
| Personalized Learning | ✅ | ❌ | ❌ | ⚠️ | ❌ |
| Curated Resources | ✅ | ⚠️ | ❌ | ⚠️ | ❌ |

**Complete Learning Flow:**
```
Scan → AI Visualiser → Adjust Parameters → Ask Questions → Learn Theory (AI Notes)
```

**Benefits:**
- ✅ **Maximum Clarity** - Visual + theoretical understanding combined
- ✅ **High Engagement** - Interactive simulations keep students interested
- ✅ **Personalized Learning** - AI adapts to individual questions and pace
- ✅ **Deep Understanding** - Not just memorization, but conceptual mastery
- ✅ **All-in-One Platform** - Everything you need in a single app

---

## 🏗️ System Architecture

Stemly follows a modern **Client-Server Architecture** with decoupled frontend and backend:

```
┌─────────────────┐
│   User/Mobile   │
│      App        │
└────────┬────────┘
         │ HTTP Requests
         │ Auth Token
         ▼
┌─────────────────────────────────────┐
│          Frontend                   │
│       Flutter App                   │
│   CustomPainter Engine              │
└────────┬────────────────────────────┘
         │ REST API
         │ JSON Data
         ▼
┌─────────────────────────────────────┐
│          Backend                    │
│      FastAPI Backend                │
│       API Routers                   │
│     Business Logic                  │
│   LangChain Orchestrator            │
└────┬────────┬───────────┬───────────┘
     │        │           │
     ▼        ▼           ▼
┌─────────┐ ┌──────┐ ┌──────────────┐
│Firebase │ │MongoDB│ │Google Gemini │
│  Auth   │ │       │ │     AI       │
└─────────┘ └──────┘ └──────────────┘
```

---

## 🛠️ Technology Stack

### Frontend (Mobile Application)

**Framework:** Flutter 3.x  
**Language:** Dart

**Core Libraries:**
- `flutter/material.dart` - Material Design 3 UI components
- `http` - REST API communication
- `provider` - State management (Authentication, User Data, Simulation State)
- `image_picker` - Device camera integration for scanning

**Visualization Engine:**
- `CustomPainter` - Low-level painting for high-performance physics animations
- `AnimationController` - 60 FPS rendering with physics loop management
- Mathematical precision with real-time calculations

**UI/UX:**
- **Glassmorphism** - Custom BackdropFilter implementation for premium aesthetic
- **Responsive Design** - Adaptive layouts across screen sizes
- **Material Design 3** - Modern, accessible interface

### Backend (Server & Logic)

**Framework:** FastAPI  
**Language:** Python 3.10+  
**Server:** Uvicorn (ASGI for high concurrency)

**Key Libraries:**
- `pydantic` - Data validation and type safety
- `python-multipart` - File upload handling
- `python-dotenv` - Environment configuration

### AI & Machine Learning

**Model:** Google Gemini 1.5 Flash
- Balance of high reasoning capability, speed, and large context window
- OCR, physics tutoring, and JSON parameter generation

**Orchestration:** LangChain
- `langchain-google-genai` - Gemini API integration
- Custom prompt templates for:
  - **Tutor Mode** - Educational content generation
  - **Simulation Controller Mode** - Natural language to parameter translation

### Database & Storage

**Database:** MongoDB
- NoSQL document store for flexible JSON structures
- Stores: scan history, simulation templates, user preferences, learning progress
- Driver: `motor` (Async Python driver)

**Authentication:** Firebase Authentication
- Secure user sign-up/login
- Token-based API verification
- Multi-platform support (Email, Google)

---

## 🔐 Authentication & Setup

![Settings Screen](https://github.com/user/repo/screenshots/settings.png)
*User-friendly settings with dark mode and notification preferences*

### Backend Configuration

1. **Create a Firebase service account:**
   - Firebase Console → Project Settings → Service Accounts → Generate New Private Key
   - Store the JSON file securely

2. **Set environment variables:**

```env
# backend/.env
MONGO_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/stemly
GEMINI_API_KEY=your_gemini_api_key
FIREBASE_CREDENTIALS_FILE=C:\secrets\stemly-service-account.json
```

3. **Install dependencies and run:**

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### Flutter Configuration

1. **Run flutterfire configure:**

```bash
cd stemly_app
flutterfire configure
flutter pub get
flutter run --dart-define=STEMLY_API_BASE_URL=https://api.yourdomain.com
```

2. **Test authentication:**

```bash
curl https://api.yourdomain.com/auth/me \
  -H "Authorization: Bearer <Firebase_ID_token>"
```

---

## 🔌 API Structure

The backend exposes these key REST endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/scan/upload` | POST | Accepts image, performs OCR/Analysis, returns identified topic |
| `/visualiser/generate` | POST | Returns initial JSON configuration for physics topic |
| `/visualiser/update` | POST | Accepts user prompt and parameters, returns AI-adjusted config |
| `/notes/generate` | POST | Generates comprehensive study notes for topic |
| `/auth/login` | POST | User authentication |
| `/auth/me` | GET | Get current user profile |
| `/history/scans` | GET | Retrieves user's scan history |

**Authentication:** All endpoints use JWT authentication and return standardized JSON responses.

---

## 📊 Current Development Status

### ✅ Completed Features
- Core scanning and image recognition
- Physics visualizer engine with multiple simulation templates
- AI Notes generation system
- Backend API infrastructure with FastAPI
- User authentication system with Firebase
- Mobile UI with glassmorphism design
- Google authentication integration
- User profile management

### 🚧 Currently Working On
- **AI Chat Feature** - Enhanced conversational interface for follow-up questions
- **Bug Fixes** - Improving stability and performance
- **Additional Simulation Templates** - Expanding physics topic coverage
- **UI/UX Refinements** - Polishing for better accessibility
- **Mathematics Visualizations** - Bringing interactive visualizations to algebra, calculus, geometry, and more
- **Chemistry Simulations** - Molecular structures, chemical reactions, and periodic table interactions

### 🔮 Upcoming Features
- **Multi-subject visualization support** (Chemistry, Mathematics) - Currently in active development
- Collaborative learning features
- Progress tracking and analytics
- Offline mode support
- Advanced graph plotting capabilities
- Custom simulation builder

> **🎯 Current Focus:** While AI Notes work for all STEM subjects, our interactive visualizations are currently optimized for Physics. We're actively expanding this capability to Mathematics and Chemistry to provide the same immersive learning experience across all STEM disciplines.

---

## 👥 Team: Mugiwara Coders

- **[SH Nihil Mukkesh](https://github.com/SH-Nihil-Mukkesh-25)** (CB.SC.U4CSE24531)
- **[SHRE RAAM P J](https://github.com/SHRE-RAAM-P-J)** (CB.SC.U4CSE24548)
- **[P Dakshin Raj](https://github.com/Dakshin10)** (CB.SC.U4CSE24534)
- **[Vibin Ragav S](https://github.com/VibinR-code)** (CB.SC.U4CSE24556)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Python 3.10+
- Firebase account
- MongoDB Atlas account
- Google Gemini API key

### Quick Start

1. **Clone the repository:**
```bash
git clone https://github.com/SH-Nihil-Mukkesh-25/Stemly.git
cd Stemly
```

2. **Set up backend:**
```bash
cd backend
pip install -r requirements.txt
# Configure .env file with your credentials
uvicorn main:app --reload
```

3. **Set up Flutter app:**
```bash
cd stemly_app
flutter pub get
flutterfire configure
flutter run
```

---

## 📝 License

[Add your license here]

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📧 Contact

For inquiries and collaboration:
- **LinkedIn:** [SH Nihil Mukkesh](https://www.linkedin.com/in/sh-nihil-mukkesh/)
- **GitHub:** [Stemly Repository](https://github.com/SH-Nihil-Mukkesh-25/Stemly)

---

## 🙏 Acknowledgments

- Google Gemini AI for powerful vision and language capabilities
- Flutter team for the amazing cross-platform framework
- Firebase for robust authentication services
- MongoDB for flexible data storage
- All contributors and testers who helped make Stemly better

---

<div align="center">

**Transforming STEM education, one scan at a time.** 🚀

*Scan → Visualize → Learn*

</div>
