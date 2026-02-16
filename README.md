<p align="center">
  <h1 align="center">Stemly</h1>
  <p align="center"><strong>Scan. Analyze. Visualize. Study.</strong></p>
  <p align="center">
    An AI-powered STEM learning platform that transforms diagrams and problems into interactive simulations, study notes, and smart quizzes.
  </p>
</p>

<p align="center">
  <a href="../../actions/workflows/flutter-ci.yml"><img src="https://github.com/SH-Nihil-Mukkesh-25/Stemly/actions/workflows/flutter-ci.yml/badge.svg" alt="Flutter CI"></a>
  <a href="../../actions/workflows/backend-ci.yml"><img src="https://github.com/SH-Nihil-Mukkesh-25/Stemly/actions/workflows/backend-ci.yml/badge.svg" alt="Backend CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"></a>
  <a href="../../graphs/contributors"><img src="https://img.shields.io/github/contributors/SH-Nihil-Mukkesh-25/Stemly" alt="Contributors"></a>
  <a href="../../commits/master"><img src="https://img.shields.io/github/last-commit/SH-Nihil-Mukkesh-25/Stemly" alt="Last Commit"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter 3.x">
  <img src="https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white" alt="Python 3.10+">
  <img src="https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Gemini_AI-4285F4?logo=google&logoColor=white" alt="Gemini AI">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/MongoDB-47A248?logo=mongodb&logoColor=white" alt="MongoDB">
</p>

---

## The Problem

Students struggle to visualize abstract STEM concepts from textbooks and static diagrams. Traditional tools offer either theory OR visuals, rarely both in an interactive, personalized way.

## Our Solution

Scan any physics problem with your phone, and Stemly instantly generates:

- **AI Visualiser** — Real-time, parameter-driven physics simulations with interactive sliders  
- **AI Notes** — Comprehensive study notes with formulas, examples, and resources  
- **Smart Quizzes** — Auto-generated MCQs to test understanding immediately  
- **AI Tutor** — Chat with Gemini, GPT-4o, Grok, or Llama 3 for personalized help  

---

## Demo

<div align="center">

| Welcome | Scan & Loading | Main Interface |
|:---:|:---:|:---:|
| <img src="docs/screenshots/welcome.png" width="200" alt="Welcome"/> | <img src="docs/screenshots/scan-loading.png" width="200" alt="Scanning"/> | <img src="docs/screenshots/home.png" width="200" alt="Home"/> |

| AI Visualiser | AI Notes | Settings |
|:---:|:---:|:---:|
| <img src="docs/screenshots/visualiser.png" width="200" alt="Visualiser"/> | <img src="docs/screenshots/notes.png" width="200" alt="Notes"/> | <img src="docs/screenshots/settings.png" width="200" alt="Settings"/> |

</div>

---

## Features

### AI Visualiser — Not Just a Video

A real-time physics engine with:

- Interactive control via sliders (velocity, angle, gravity, resistance)  
- Natural language control — ask "What if gravity was 0?" and watch it update  
- Live graphs (velocity-time, position-time, acceleration-time)  
- 9+ simulations: Projectile Motion, SHM, Optics, Kinematics, Free Fall, and more  

### AI Notes — Study Smarter

Generated specifically for each scanned problem:

- Concept breakdowns with simple explanations  
- Key formulas with physical meanings  
- Step-by-step worked examples  
- Curated resources from across the web  

### Smart Quizzes

- Instantly generated from your scanned content  
- Multiple-choice with detailed explanations  
- Score tracking and feedback  

### Multi-Provider AI Tutor

Choose your preferred AI model:

- Google Gemini (default)  
- xAI Grok  
- OpenAI GPT-4o  
- Groq Llama 3  

---

## Architecture

```mermaid
graph TD
    User[Flutter App] -->|REST API| API[FastAPI Backend]
    API -->|Auth| Firebase[Firebase Auth]
    API -->|Data| DB[(MongoDB)]
    API -->|Vision + Text| Gemini[Google Gemini 2.5 Flash]

    subgraph Client
        User
        OCR[Google ML Kit OCR]
        VIS[Physics Engine]
    end

    subgraph AI
        Gemini
    end
```

| Layer | Technology |
| :--- | :--- |
| Frontend | Flutter 3.x, Dart, Provider, CustomPaint (60 FPS rendering) |
| Backend | FastAPI, Python 3.10+, Uvicorn, Pydantic |
| AI | Google Gemini 2.5 Flash (vision + text + JSON mode) |
| Database | MongoDB Atlas (async via Motor) |
| Auth | Firebase Authentication (Google Sign-In, email/password) |
| Deployment | Vercel (backend), APK/IPA (frontend) |

See `ARCHITECTURE.md` for detailed component diagrams, data flows, and the scan-to-simulation pipeline.

---

## Quick Start

### Prerequisites

- Flutter 3.x+ and Dart SDK 3.10.1+
- Python 3.10+
- API keys: Google Gemini + Firebase + MongoDB Atlas

### Setup

```bash
git clone https://github.com/SH-Nihil-Mukkesh-25/Stemly.git
cd Stemly

# Backend
cd backend
python -m venv .venv && source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env   # Fill in your API keys
uvicorn main:app --reload

# Flutter (in a new terminal)
cd stemly_app
flutter pub get
flutter run
```

For detailed instructions (platform-specific, Docker, etc.), see the Setup Guide.

---

## Documentation

| Document | Description |
| :--- | :--- |
| **Architecture** | System design, component diagrams, data flows |
| **API Reference** | Complete REST API documentation with examples |
| **Setup Guide** | Getting API keys, platform setup, Docker |
| **Development Guide** | Git workflow, testing, debugging, adding simulations |
| **Contributing** | How to contribute, code style, PR process |
| **FAQ** | Common questions answered |
| **Roadmap** | Where Stemly is headed |

---

## Roadmap

See `docs/ROADMAP.md` for the full roadmap.

- **Next**: Wave simulations, circuit builder, chemistry support, offline mode
- **Later**: Web deployment, multi-language support, classroom mode, AR features
- **Vote**: React on issues to prioritize features

---

## Contributing

We welcome contributions from everyone — especially students and first-time open-source contributors!

1. Read the **Contributing Guide**
2. Look for `good first issue` labels
3. Set up your environment with the **Setup Guide**
4. Pick an issue and submit a PR

---

## Team

Stemly was built by **Team Mugiwara Coders** — CS students from Amrita Vishwa Vidyapeetham, Coimbatore.

| Name | Role | GitHub |
| :--- | :--- | :--- |
| P Dakshin Raj | Frontend & Flutter Lead | @Dakshin10 |
| SH Nihil Mukkesh | Backend & AI Lead | @SH-Nihil-Mukkesh-25 |
| SHRE RAAM P J | Content & Ideation | @SHRE-RAAM-P-J |
| Vibin Ragav S | Testing | @VibinR-code |

### Contributors

<a href="../../graphs/contributors"> <img src="https://contrib.rocks/image?repo=SH-Nihil-Mukkesh-25/Stemly" /> </a>

---

## Community

- **Questions?** Open a discussion or ask an issue
- **Found a bug?** Report it
- **Have an idea?** Request a feature
- **Security issue?** See `SECURITY.md`

## License

Stemly is open-source under the MIT License.

<div align="center"> <strong>Transforming STEM education, one scan at a time.</strong> <br><br> <a href="../../stargazers">Star this repo</a> if you find it useful! </div>
