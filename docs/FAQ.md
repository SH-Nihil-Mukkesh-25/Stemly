# Frequently Asked Questions

## General

### What is Stemly?

Stemly is an AI-powered STEM learning platform. You scan a physics problem with your phone's camera, and Stemly automatically detects the topic, generates interactive simulations, study notes, and quizzes. Think of it as a personal physics tutor that can visualize any concept.

### Who built Stemly?

Stemly was built by four computer science students from Amrita Vishwa Vidyapeetham, Coimbatore, India:
- P Dakshin Raj (Frontend & Flutter Lead)
- SH Nihil Mukkesh (Backend & AI Lead)
- SHRE RAAM P J (Machine Learning)
- Vibin Ragav S (UI/UX & Frontend)

### Is Stemly free?

Yes. Stemly is open-source under the MIT license. You can use, modify, and distribute it freely.

You'll need your own API keys for Google Gemini and Firebase, which have generous free tiers.

---

## How It Works

### How does the vision analysis work?

When you scan a problem:
1. **On-device OCR** (Google ML Kit) extracts visible text from the image
2. The image and extracted text are sent to **Google Gemini Vision**
3. Gemini identifies the STEM topic (e.g., "Projectile Motion") and key variables (e.g., velocity, angle, gravity)
4. If Gemini is unavailable, a **keyword-matching fallback** detects topics from 36+ physics/chemistry/math terms

### Which AI models are supported?

| Feature | Model |
|---------|-------|
| Topic detection | Google Gemini 2.5 Flash (vision + text) |
| Notes generation | Google Gemini 2.5 Flash |
| Quiz generation | Google Gemini 2.5 Flash |
| AI Tutor chat | Google Gemini (default), with optional support for OpenAI, Groq, xAI |
| Image generation | AIML API (flux/schnell) |

Users can configure their own API keys in Settings to use different providers for the chat feature.

### How accurate are the simulations?

The simulations use real physics equations — they are mathematically accurate for ideal conditions (no air resistance, perfect collisions, etc.). Currently supported:

- Projectile Motion
- Free Fall
- Simple Harmonic Motion
- Kinematics
- Optics (lens ray tracing)
- Atom Structure
- Quadratic Graphs
- Equation Plotter
- Generic Diagrams

Each simulation has adjustable parameters with real-time rendering at 60 FPS.

### Can I use Stemly offline?

Partially. The camera scanner uses on-device OCR (works offline). However, topic detection, notes, quizzes, and the AI tutor require an internet connection since they call AI APIs. Offline mode with cached content is on our [roadmap](ROADMAP.md).

---

## Technical

### What tech stack does Stemly use?

- **Frontend**: Flutter (Dart) — cross-platform mobile app
- **Backend**: FastAPI (Python) — REST API
- **AI**: Google Gemini 2.5 Flash — vision, text, JSON generation
- **Database**: MongoDB Atlas — user data, scan history
- **Auth**: Firebase Authentication — Google Sign-In, email/password
- **Deployment**: Vercel (backend), APK/IPA (frontend)

### What platforms are supported?

Stemly is built with Flutter, so it can run on:
- Android (primary target)
- iOS
- Web (experimental)
- Windows, macOS, Linux (desktop, experimental)

### Do I need all the API keys to run Stemly?

For basic functionality, you need:
- **Google Gemini API key** (free tier available)
- **Firebase project** (free tier)
- **MongoDB connection** (free Atlas cluster)

The xAI, OpenAI, Groq, and AIML keys are optional — they enable additional chat providers and image generation.

### How do I update the AI model?

The model is configured in `backend/config.py`:

```python
GEMINI_MODEL = "gemini-2.5-flash"
```

Change this to any supported Gemini model. No other code changes needed.

---

## Contributing

### Can I contribute?

Absolutely! We welcome contributions from everyone, especially students and first-time open-source contributors. See [CONTRIBUTING.md](../CONTRIBUTING.md) for how to get started.

### I'm new to open source. Where do I start?

1. Read the [Contributing Guide](../CONTRIBUTING.md)
2. Look for issues labeled [`good first issue`](../../labels/good%20first%20issue)
3. Set up the development environment following the [Setup Guide](SETUP_GUIDE.md)
4. Pick an issue, comment that you're working on it, and submit a PR

### Can I add support for new subjects (Chemistry, Biology, Math)?

Yes! The architecture is designed to be extensible:
- **New simulations**: Follow the factory pattern in `visualiser/`
- **New topics**: Add keyword detection in `ai_detector.py`
- **New quiz subjects**: The quiz generator works with any topic string

See the [Development Guide](DEVELOPMENT.md) for step-by-step instructions.

---

## Troubleshooting

### The scan doesn't detect my topic

- Ensure good lighting and a clear photo
- The image should contain readable text or a recognizable diagram
- Currently supports physics, basic chemistry, and math topics
- Try including OCR-friendly text in the frame

### The AI features return errors

- Check that your `GOOGLE_API_KEY` is valid and has quota remaining
- Free Gemini tier: 15 requests/minute, 1500/day
- The backend automatically retries 3 times with backoff
- Check backend logs for specific error messages

### Google Sign-In fails

See `stemly_app/FIREBASE_SETUP.md` for the complete fix. Most commonly:
- SHA-1/SHA-256 keys not added to Firebase Console
- `google-services.json` is outdated
- Package name mismatch
