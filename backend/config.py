import os
from dotenv import load_dotenv

# Load environment variables once, at import time.
load_dotenv()

# ==============================================================================
# AI Configuration (Google Gemini API)
# ==============================================================================

# Gemini API Configuration
GEMINI_API_KEY = os.getenv("GOOGLE_API_KEY") or os.getenv("GEMINI_API_KEY")
GEMINI_FALLBACK_API_KEY = os.getenv("GEMINI_FALLBACK_API_KEY")
GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
GEMINI_MODEL = "gemini-2.5-flash"  # Latest Gemini 2.5 Flash model
GEMINI_VISION_MODEL = "gemini-2.5-flash"  # Same model handles vision

# Legacy aliases for compatibility (redirecting to Gemini)
OPENROUTER_API_KEY = GEMINI_API_KEY
LOCAL_MODEL = GEMINI_MODEL
VISION_MODEL = GEMINI_VISION_MODEL
OLLAMA_BASE_URL = GEMINI_BASE_URL
GENERAL_MODEL = GEMINI_MODEL

# Legacy keys (deprecated, kept for import compatibility)
FALLBACK_GROQ_API_KEY = None
AIML_API_KEY = os.getenv("AIML_API_KEY")  # For image generation only
OPENROUTER_API_KEY_LEGACY = os.getenv("OPENROUTER_API_KEY")

def is_ai_enabled() -> bool:
    """Returns True if Gemini API key is configured."""
    return bool(GEMINI_API_KEY)

def get_gemini_url(model: str = None) -> str:
    """Get the full Gemini API URL for generateContent."""
    m = model or GEMINI_MODEL
    return f"{GEMINI_BASE_URL}/models/{m}:generateContent?key={GEMINI_API_KEY}"
