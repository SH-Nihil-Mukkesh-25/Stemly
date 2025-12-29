import os

from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from openai import AsyncOpenAI

# Load environment variables once, at import time.
load_dotenv()

# ==============================================================================
# AI Configuration (OpenRouter API)
OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"
OPENROUTER_MODEL = "meta-llama/llama-3.2-3b-instruct:free"  # Free model

# Legacy aliases for compatibility
OLLAMA_BASE_URL = OPENROUTER_BASE_URL
LOCAL_MODEL = OPENROUTER_MODEL

# For compatibility with existing imports
GENERAL_MODEL = LOCAL_MODEL

# Vision model for no-text scans
VISION_MODEL = "google/gemini-2.0-flash-exp:free"

# API Keys
FALLBACK_GROQ_API_KEY = None
AIML_API_KEY = os.getenv("AIML_API_KEY")  # Legacy
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

def is_ai_enabled() -> bool:
    """Always True as we depend on user-provided keys or basic fallback."""
    return True

