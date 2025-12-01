# services/ai_detector.py

import json
import re
from pathlib import Path
from typing import List, Tuple

import google.generativeai as genai

from config import GEMINI_API_KEY


def _ensure_genai_configured() -> bool:
    """
    Configure the Gemini client once using the shared API key.
    Returns True if configuration is available, False otherwise.
    """
    if not GEMINI_API_KEY:
        print(
            "⚠ GEMINI_API_KEY is not set. "
            "Topic detection will be disabled and return fallback values."
        )
        return False

    # google-generativeai is configured globally; calling this multiple times is cheap.
    genai.configure(api_key=GEMINI_API_KEY)
    return True


async def detect_topic(image_path: str) -> Tuple[str, List[str]]:
    """
    Detect STEM topic + variables from an image using Gemini 2.0 Flash.
    Ensures clean JSON output and supports various formats returned by Gemini.
    """

    # Ensure the Gemini client is ready
    if not _ensure_genai_configured():
        return "Unknown", []

    # --- Read image bytes ---
    path = Path(image_path)
    if not path.is_file():
        print(f"❌ ai_detector: image file not found at {image_path}")
        return "Unknown", []

    img_bytes = path.read_bytes()

    # --- Auto-detect MIME type ---
    ext = path.suffix.lower()
    if ext.endswith(".jpg") or ext.endswith(".jpeg"):
        mime_type = "image/jpeg"
    else:
        mime_type = "image/png"

    # --- Strict JSON Prompt ---
    system_prompt = """
    You are a STEM topic detector.

    Your job:
    - Identify the main STEM topic from the scanned image.
    - Identify important variables (e.g., v0, angle, g, refractive index, resistance).

    STRICT RULES:
    - Respond ONLY with a valid JSON object.
    - NO backticks.
    - NO markdown.
    - NO explanations.
    - NO code blocks.

    Output format:
    {
      "topic": "Projectile Motion",
      "variables": ["v0", "angle", "g"]
    }
    """

    # --- Gemini Model ---
    model = genai.GenerativeModel("gemini-2.0-flash")

    try:
        response = model.generate_content(
            [
                system_prompt,
                {
                    "mime_type": mime_type,
                    "data": img_bytes
                }
            ]
        )
        raw_text = response.text.strip()
    except Exception as e:
        print(f"❌ Gemini API Error in ai_detector: {e}")
        return "Unknown", []

    # --- Clean raw output ---
    raw_text = re.sub(r"```json", "", raw_text)
    raw_text = re.sub(r"```", "", raw_text).strip()

    # --- Try parsing JSON ---
    try:
        parsed = json.loads(raw_text)

        # --- Handle topic variations ---
        topic = (
            parsed.get("topic") or
            parsed.get("stem_topic") or
            parsed.get("subject") or
            "Unknown"
        )

        # --- Handle variable formats ---
        variables_raw = parsed.get("variables", [])
        variables = []

        for item in variables_raw:
            if isinstance(item, str):
                variables.append(item)
            elif isinstance(item, dict):
                # Convert {"u": "velocity"} → "u"
                key = list(item.keys())[0]
                variables.append(key)
            else:
                variables.append(str(item))

        return topic, variables

    except Exception as e:
        print("⚠ JSON Parse Error in ai_detector:", e)
        print("Raw Gemini Output:", raw_text)

        # Fallback to raw topic only
        return raw_text, []