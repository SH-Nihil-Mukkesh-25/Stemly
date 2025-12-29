# Stemly 🚀

**Scan → Analyze → Visualize → Study**

An AI-powered STEM learning platform that transforms diagrams and problems into interactive simulations, comprehensive study notes, and smart quizzes.

[![GitHub](https://img.shields.io/badge/GitHub-Stemly-blue?logo=github)](https://github.com/Dakshin10/Stemly)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-Python-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![AI](https://img.shields.io/badge/AI-Multi--Model-purple?logo=openai)](https://x.ai)

---

## 🌟 What is Stemly?

Stemly is an advanced educational application that bridges the gap between theoretical STEM concepts and visual understanding. By combining real-time computer vision, generative AI, and interactive physics simulations, we've created a unique **"Text-to-Simulation"** learning experience.

**The Problem:** Students struggle to visualize abstract physics concepts from textbooks and static diagrams. Traditional learning tools offer either theory OR visuals, but rarely both in an interactive, personalized way.

**Our Solution:** Scan any physics problem, and Stemly instantly generates:

- **🎨 AI Visualiser**: Dynamic, parameter-driven simulations with real-time interactive controls.
- **📚 AI Notes**: Comprehensive study companion with explanations, formulas, and curated resources.
- **🧠 Smart Quizzes**: Auto-generated interactive quizzes to test your understanding immediately.
- **💬 AI Tutor**: Chat with xAI (Grok), OpenAI (GPT-4o), or Groq (Llama 3) for personalized help.

---

## 📸 App Interface

<div align="center">

| Welcome | Scan & Loading | Main Interface | 
|:---:|:---:|:---:|
| <img src="docs/screenshots/welcome.png" width="200" alt="Welcome"/> | <img src="docs/screenshots/scan-loading.png" width="200" alt="Scanning"/> | <img src="docs/screenshots/home.png" width="200" alt="Home"/> |

| AI Visualiser | AI Notes | Settings |
|:---:|:---:|:---:|
| <img src="docs/screenshots/visualiser.png" width="200" alt="Visualiser"/> | <img src="docs/screenshots/notes.png" width="200" alt="Notes"/> | <img src="docs/screenshots/settings.png" width="200" alt="Settings"/> |

</div>

---

## ✨ Core Features

### 1. 🎨 AI Visualiser - Not just a video
Our visualizer is a **real-time physics engine**:
- **Interactive Control**: Adjust velocity, angle, gravity, and resistance with sliders.
- **Natural Language Control**: Ask *"What if gravity was 0?"* and watch the simulation update instantly.
- **Real-time Graphs**: Live velocity-time, position-time, and acceleration-time plots.
- **Supported Topics**: Projectile Motion, SHM, Optics, Kinematics, Circuits, Wave Motion.

### 2. 📚 AI Notes - Study Smarter
Generated specifically for each scanned problem:
- **Concept Breakdown**: Simple explanations of complex theories.
- **Key Formulas**: With physical meanings and derivations.
- **Step-by-Step Solutions**: Worked examples for similar problems.
- **Curated Resources**: Best videos and articles from across the web.

### 3. 🧠 Smart Quizzes
- **Instant Generation**: Quizzes created instantly from your scanned content.
- **Adaptive Difficulty**: Questions that adapt to your knowledge level.
- **Detailed Explanations**: Learn why an answer is correct or incorrect.

### 4. 🤖 Multi-Provider AI Support
Stemly gives you choice. Connect your preferred AI model for the Chat & Tutor features:
- **xAI (Grok-Beta)**: Access the latest models from xAI.
- **OpenAI (GPT-4o)**: Industry-leading reasoning capabilities.
- **OpenRouter**: Access to Gemini Flash, Claude, and more.
- **Groq (Llama 3)**: Lightning-fast inference for instant responses.

---

## 🏗️ Technical Architecture

### System Design

```mermaid
graph TD
    User[Mobile App (Flutter)] -->|REST API| API[FastAPI Backend]
    API -->|Auth| Firebase[Firebase Auth]
    API -->|Data| DB[(MongoDB)]
    API -->|Vision| Gemini[Gemini Vision Pro]
    API -->|Chat/Tutor| MultiLLM[xAI / OpenAI / Groq]
    
    subgraph "AI Services"
        Gemini
        MultiLLM
    end
```

### Technology Stack

**Frontend (Mobile)**
- **Framework:** Flutter 3.x (Dart)
- **Visuals:** CustomPainter (High-performance 60FPS rendering)
- **State:** Provider & Riverpod
- **Design:** Material 3 + Glassmorphism

**Backend (Server)**
- **Framework:** FastAPI (Python 3.10+)
- **Server:** Uvicorn (ASGI)
- **Validation:** Pydantic

**AI & Cloud**
- **Vision:** Google Gemini 1.5 Pro/Flash
- **LLMs:** Integration with xAI API, OpenAI API, Groq API
- **Database:** MongoDB Atlas
- **Auth:** Firebase Authentication

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: 3.x+
- **Python**: 3.10+
- **API Keys**: 
  - Google Gemini (for Vision/Scanning)
  - Firebase Project (Auth)
  - MongoDB Connection String
  - *Optional*: xAI, OpenAI, or Groq API Key (for Chat features)

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Dakshin10/Stemly.git
   cd Stemly
   ```

2. **Backend Setup**
   ```bash
   cd backend
   pip install -r requirements.txt
   
   # Create .env file with your credentials
   # MONGO_URI=...
   # GEMINI_API_KEY=...
   # FIREBASE_CREDENTIALS_FILE=...
   
   uvicorn main:app --reload --host 0.0.0.0 --port 8080
   ```

3. **Frontend Setup**
   ```bash
   cd stemly_app
   flutter pub get
   flutter run
   ```

---

## 👥 Team Mugiwara Coders

**Stemly** was built with ❤️ by a team of passionate CS students from Amrita Vishwa Vidyapeetham, Coimbatore.

| Name | Role | GitHub |
|------|------|--------|
| **P Dakshin Raj** | Frontend & Flutter Lead | [@Dakshin10](https://github.com/Dakshin10) |
| **SH Nihil Mukkesh** | Backend & AI Lead | [@SH-Nihil-Mukkesh-25](https://github.com/SH-Nihil-Mukkesh-25) |
| **SHRE RAAM P J** | Machine Learning | [@SHRE-RAAM-P-J](https://github.com/SHRE-RAAM-P-J) |
| **Vibin Ragav S** | UI/UX & Frontend | [@VibinR-code](https://github.com/VibinR-code) |

---

<div align="center">

**Transforming STEM education, one scan at a time.** 🚀

</div>
