import os

from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
import google.generativeai as genai

# Load environment variables once, at import time.
# This will read from a `.env` file in the project root if present.
load_dotenv()

# Gemini API key used for both LangChain LLM and direct google.generativeai calls.
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

llm = None  # type: ignore

if not GEMINI_API_KEY:
    # Do NOT crash the whole backend if the key is missing.
    # Instead, disable AI features and log a clear warning.
    print("⚠ GEMINI_API_KEY is not set. AI features (notes, scan detection) are disabled.")
else:
    # Configure the underlying google.generativeai client so that
    # services like `ai_detector` can use it directly.
    genai.configure(api_key=GEMINI_API_KEY)

    # Shared Gemini LLM instance used via LangChain (e.g. notes generation).
    llm = ChatGoogleGenerativeAI(
        model="gemini-2.0-flash",
        temperature=0.7,
        max_tokens=1024,
        google_api_key=GEMINI_API_KEY,
    )


def is_ai_enabled() -> bool:
    """Return True if the Gemini API key is configured and the LLM is available."""
    return GEMINI_API_KEY is not None and llm is not None

