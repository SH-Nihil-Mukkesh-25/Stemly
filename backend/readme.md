# 📘 Stemly Backend

> **AI-Powered STEM Learning Assistant**  
> Scan, analyze, and learn from STEM diagrams using Gemini AI

[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=flat&logo=fastapi)](https://fastapi.tiangolo.com/)
[![Gemini AI](https://img.shields.io/badge/Gemini%202.0-4285F4?style=flat&logo=google)](https://ai.google.dev/)
[![Python 3.8+](https://img.shields.io/badge/Python-3.8+-3776AB?style=flat&logo=python)](https://www.python.org/)

---

## 🌟 Overview

Stemly enables students to scan STEM diagrams with their mobile device, automatically detect topics, extract variables, and maintain a comprehensive scan history. Built with a clean, modular architecture for seamless scalability.

**Phase 1 Status:** ✅ Complete

---

## ✨ Features

### 🔍 Smart Image Processing
- **Upload & Scan** - Seamless image upload from Flutter camera integration
- **Automatic Storage** - Images saved with organized file management

### 🤖 AI-Powered Analysis
- **Topic Detection** - Identifies STEM concepts (e.g., Projectile Motion, Circuits, Refraction)
- **Variable Extraction** - Automatically detects key variables (`v₀`, `θ`, `g`, etc.)
- **Powered by** Gemini 2.0 Flash vision model

### 💾 Persistent History
- **User-Specific Storage** - Each scan linked to user ID
- **Complete Metadata** - Topic, variables, image path, and timestamp
- **Easy Retrieval** - Query full scan history per user

### 🎯 Flutter-Ready Output
- **Strict JSON** - No markdown, no code fences
- **Consistent Format** - Predictable structure for mobile parsing
- **Error Handling** - Graceful fallbacks and validation

---

## 📁 Project Structure

```
backend/
├── 📄 main.py                    # FastAPI application entry point
├── ⚙️  config.py                  # Environment & Gemini configuration
├── 📋 requirements.txt           # Python dependencies
├── 📖 README.md                  # This file
│
├── 🛣️  routers/
│   └── scan.py                   # Scan upload & history endpoints
│
├── 🔧 services/
│   ├── ai_detector.py            # Gemini vision integration
│   ├── storage.py                # Image file management
│   └── history_service.py        # Scan history (in-memory, DB-ready)
│
├── 📦 static/
│   └── scans/                    # Uploaded images directory
│
├── 🔐 .env                       # API keys (not in version control)
└── 🚫 .gitignore                 # Ignored files configuration
```

---

## 🚀 Quick Start

### Prerequisites
- Python 3.8 or higher
- Gemini API key ([Get one here](https://ai.google.dev/))

### 1️⃣ Clone Repository
```bash
git clone https://github.com/SH-Nihil-Mukkesh-25/Stemly.git
cd stemly/backend
```

### 2️⃣ Create Virtual Environment
```bash
# Windows
python -m venv venv
./venv/Scripts/activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

### 3️⃣ Install Dependencies
```bash
pip install -r requirements.txt
```

### 4️⃣ Configure Environment
Create a `.env` file in the `backend/` directory:
```env
GEMINI_API_KEY=your_gemini_api_key_here
```

> ⚠️ **Important:** Never commit `.env` to version control

### 5️⃣ Launch Server
```bash
uvicorn main:app --reload
```

✅ **Server running at:** `http://127.0.0.1:8000`  
📚 **API Documentation:** `http://127.0.0.1:8000/docs`

---

## 📡 API Reference

### **POST** `/scan/upload`
Upload and analyze a STEM diagram

**Request** (multipart/form-data)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `user_id` | string | ✅ | Unique user identifier |
| `file` | binary | ✅ | Image file (PNG/JPG) |

**Response** (200 OK)
```json
{
  "status": "success",
  "topic": "Projectile Motion",
  "variables": ["U", "theta", "R"],
  "image_path": "static/scans/diagram_abc123.png",
  "history_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

### **GET** `/scan/history/{user_id}`
Retrieve scan history for a user

**Parameters**
| Name | Type | Location | Description |
|------|------|----------|-------------|
| `user_id` | string | path | User identifier |

**Response** (200 OK)
```json
{
  "history": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "test123",
      "image_path": "static/scans/diagram_abc123.png",
      "topic": "Projectile Motion",
      "variables": ["U", "theta", "R"],
      "timestamp": "2025-11-25T11:31:50"
    }
  ]
}
```

---

## 🧠 AI Integration

### Gemini 2.0 Flash Pipeline

```
📸 Image Upload → 🔄 Byte Processing → 🤖 Gemini Vision API
                                              ↓
                                    📊 JSON Response
                                              ↓
                            🧹 Sanitization & Validation
                                              ↓
                                    ✅ Clean Output
```

**Key Features:**
- Markdown-free responses
- Code fence removal
- Strict JSON parsing
- Automatic fallback handling
- Error recovery system

---

## 🔒 Security

| Feature | Status | Details |
|---------|--------|---------|
| Environment Variables | ✅ | API keys in `.env` (gitignored) |
| Secure Loading | ✅ | `python-dotenv` integration |
| Static File Safety | ✅ | Isolated `/static` directory |
| Authentication | 🔜 | JWT implementation (Phase 2) |
| Input Validation | ✅ | File type & size checks |

---

## 🗺️ Roadmap

### Phase 1: Core Scanner ✅ **COMPLETE**
- [x] Image upload API
- [x] Gemini topic detection
- [x] Variable extraction
- [x] Scan history storage

### Phase 2: Visual Engine 🚧 **IN PROGRESS**
- [ ] `/visualiser/generate` endpoint
- [ ] `/visualiser/update` endpoint
- [ ] Flame-based rendering
- [ ] Dynamic parameter updates

### Phase 3: AI Notes 📋 **PLANNED**
- [ ] `/notes/generate` endpoint
- [ ] Structured note generation
- [ ] Resource extraction
- [ ] Summary system

---

## 🛠️ Tech Stack

- **Framework:** FastAPI
- **AI Model:** Google Gemini 2.0 Flash
- **Language:** Python 3.8+
- **Frontend:** Flutter (Mobile)
- **Storage:** File System (Database-ready)

---
