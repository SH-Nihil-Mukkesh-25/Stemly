import json
import requests
import re
import base64
import time
from typing import List, Tuple
from config import GEMINI_API_KEY, get_gemini_url, GEMINI_MODEL


def _gemini_request_with_retry(url: str, payload: dict, timeout: int = 30, max_retries: int = 3):
    """Make Gemini API request with exponential backoff for rate limiting."""
    for attempt in range(max_retries):
        try:
            response = requests.post(
                url, 
                json=payload, 
                headers={"Content-Type": "application/json"}, 
                timeout=timeout
            )
            
            if response.status_code == 429:
                wait_time = (2 ** attempt) + 1
                print(f"⏳ Rate limited (429). Waiting {wait_time}s (attempt {attempt+1}/{max_retries})")
                time.sleep(wait_time)
                continue
                
            response.raise_for_status()
            return response
            
        except requests.exceptions.HTTPError as e:
            if hasattr(e, 'response') and e.response is not None and e.response.status_code == 429:
                if attempt < max_retries - 1:
                    wait_time = (2 ** attempt) + 1
                    print(f"⏳ Rate limited (429). Waiting {wait_time}s...")
                    time.sleep(wait_time)
                    continue
            raise
    
    print(f"❌ Max retries ({max_retries}) exceeded for Gemini API")
    return None


# Keyword-based fallback for common topics
TOPIC_KEYWORDS = {
    "Optics": ["optic", "lens", "mirror", "refraction", "reflection", "light", "ray", "focal", "prism"],
    "Kinematics": ["velocity", "acceleration", "motion", "displacement", "kinematic", "speed", "trajectory"],
    "Electricity": ["current", "voltage", "resistance", "ohm", "circuit", "capacitor", "electric"],
    "Magnetism": ["magnetic", "magnet", "field", "solenoid", "electromagnet"],
    "Thermodynamics": ["heat", "temperature", "entropy", "thermal", "thermodynamic"],
    "Waves": ["wave", "frequency", "wavelength", "amplitude", "oscillation", "sound"],
    "Mechanics": ["force", "newton", "momentum", "torque", "equilibrium", "friction"],
    "Calculus": ["derivative", "integral", "differentiation", "integration", "limit"],
    "Algebra": ["equation", "polynomial", "quadratic", "linear", "variable"],
    "Geometry": ["triangle", "circle", "angle", "polygon", "theorem", "euclidean"],
    "Chemistry": ["reaction", "element", "compound", "molecule", "bond", "acid", "base"],
    "Biology": ["cell", "organism", "gene", "dna", "protein", "photosynthesis"],
    "Projectile Motion": ["projectile", "cannon", "parabola", "range", "trajectory", "2d motion"],
}


def detect_topic_from_keywords(text: str) -> str:
    """Fallback: detect topic using keyword matching."""
    text_lower = text.lower()
    
    for topic, keywords in TOPIC_KEYWORDS.items():
        for keyword in keywords:
            if keyword in text_lower:
                print(f"📌 Keyword match: '{keyword}' -> {topic}")
                return topic
    
    return "Unknown"


def extract_json_from_text(text: str) -> dict:
    """Extract JSON from LLM output with multiple strategies."""
    if not text:
        return None
        
    text = text.strip()
    
    # Remove markdown
    text = re.sub(r"```json\s*", "", text)
    text = re.sub(r"```\s*", "", text)
    text = text.strip()
    
    # Try direct parse
    try:
        return json.loads(text)
    except:
        pass
    
    # Find JSON object (GREEDY match for nested objects)
    # This finds the string between the FIRST '{' and the LAST '}'
    match = re.search(r'\{[\s\S]*\}', text)
    if match:
        try:
            return json.loads(match.group())
        except:
            pass
    
    return None


SYSTEM_FALLBACK_KEY = "AIzaSyBek9KwVGRNicmxCNO1Zv4ubgevRUU4LZQ"

async def detect_topic(ocr_text: str, image_path: str = None, api_key: str = None) -> Tuple[str, List[str]]:
    """
    Detect STEM topic using Google Gemini API.
    Strategy:
    1. If OCR text is available, try Text-Only model (Fast).
    2. If Text model fails (returns Unknown) OR OCR is poor, use Vision model.
    """
    
    # Use provided key or fall back to config
    gemini_key = api_key if (api_key and api_key.startswith("AIza")) else GEMINI_API_KEY
    
    if not gemini_key:
        # Try fallback if even config is missing info
        gemini_key = SYSTEM_FALLBACK_KEY
    
    # 1. Try Keyword fallback first (Fastest)
    keyword_topic = detect_topic_from_keywords(ocr_text) if ocr_text else "Unknown"
    
    # 2. Determine if we skip straight to Vision (Sparse text)
    skip_text_model = not ocr_text or len(ocr_text.strip()) < 10
    
    topic = "Unknown"
    variables = []

    # --- ATTEMPT 1: TEXT MODEL ---
    if not skip_text_model:
        print(f"🔍 Text detected ({len(ocr_text)} chars). Using Gemini Text...")
        try:
            topic, variables = await _query_gemini_text(gemini_key, ocr_text)
        except Exception as e:
            print(f"⚠ Gemini text error with primary key: {e}")
            # FALBACK RETRY
            try:
                print("🔄 Retrying Text Model with System Fallback Key...")
                topic, variables = await _query_gemini_text(SYSTEM_FALLBACK_KEY, ocr_text)
            except Exception as e2:
                print(f"❌ Gemini text fallback failed: {e2}")
                topic = "Unknown"
            

    # --- ATTEMPT 2: VISION MODEL (Fallback) ---
    if (topic == "Unknown" or topic == "General Science") and image_path:
        reason = "Short Text" if skip_text_model else "Text Model failed"
        print(f"👁 {reason}. Using Gemini Vision...")
        
        try:
            topic, variables = await _query_gemini_vision(gemini_key, image_path, ocr_text)
        except Exception as e:
            print(f"❌ Gemini vision error with primary key: {e}")
            # FALLBACK RETRY
            try:
                print("🔄 Retrying Vision Model with System Fallback Key...")
                topic, variables = await _query_gemini_vision(SYSTEM_FALLBACK_KEY, image_path, ocr_text)
            except Exception as e2:
                 print(f"❌ Gemini vision fallback failed: {e2}")

            
    # Final Fallback
    if topic == "Unknown":
        topic = keyword_topic

    return topic, variables


async def _query_gemini_text(api_key: str, text: str) -> Tuple[str, List[str]]:
    """Query Google Gemini API for text-based topic detection."""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={api_key}"
    
    system_prompt = """You are an expert STEM topic classifier. Analyze the given text and return ONLY valid JSON.

STRICT RULES:
1. Look for keywords: If text contains "projectile", "trajectory", "parabola", "launch angle", "range", "horizontal/vertical motion", "cannon", "ball thrown" -> topic MUST be "Projectile Motion"
2. If text contains "lens", "mirror", "refraction", "reflection", "focal", "optics", "light ray" -> topic is "Optics"
3. If text contains "velocity", "acceleration", "displacement" in 1D context (no angles) -> topic is "Kinematics"
4. If text contains "force", "newton", "friction", "momentum" -> topic is "Mechanics"
5. If text contains "circuit", "voltage", "current", "resistance", "ohm" -> topic is "Electricity"
6. If text contains "atom", "electron", "proton", "neutron", "orbital" -> topic is "Atomic Structure"

Output format: {"topic": "TopicName", "variables": ["var1", "var2"]}
Return ONLY the JSON, no markdown, no explanation."""
    
    payload = {
        "contents": [{
            "parts": [{"text": f"{system_prompt}\n\nUser input: {text[:1000]}"}]
        }],
        "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 200,
            "response_mime_type": "application/json"
        }
    }
    
    response = _gemini_request_with_retry(url, payload, timeout=30)
    if not response:
        return "Unknown", []
    data = response.json()
    
    try:
        candidates = data.get('candidates', [])
        if not candidates:
            print(f"⚠ Gemini Trace: No candidates in response. Data: {data}")
            return "Unknown", []
            
        content = candidates[0].get('content', {})
        parts = content.get('parts', [])
        if not parts:
            print(f"⚠ Gemini Trace: No parts in candidate content. Content: {content}")
            return "Unknown", []

        raw = parts[0].get('text', '')
        print(f"💎 Gemini Response: {raw[:100]}...")
        parsed = extract_json_from_text(raw)
        if parsed:
            return parsed.get("topic", "Unknown"), [str(x) for x in parsed.get("variables", [])]
        else:
            print(f"❌ Failed to extract JSON from: {raw[:200]}")
    except Exception as e:
        print(f"❌ Gemini Parse Error: {e}")
        
    return "Unknown", []


async def _query_gemini_vision(api_key: str, image_path: str, ocr_text: str = "") -> Tuple[str, List[str]]:
    """Query Google Gemini API for vision-based topic detection."""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={api_key}"
    
    with open(image_path, "rb") as img_file:
        b64_image = base64.b64encode(img_file.read()).decode('utf-8')

    mime_type = "image/png" if image_path.lower().endswith(".png") else "image/jpeg"

    system_prompt = """Analyze this physics/science image carefully. What specific topic is being shown?

Be very precise with topic identification:
- Projectile Motion: trajectory, parabolic path, launch angle, horizontal range
- Optics: lenses, mirrors, light rays, prisms, focal points
- Kinematics: 1D motion graphs, velocity-time, position-time
- Electricity: circuits, resistors, capacitors, batteries
- Mechanics: forces, free body diagrams, pulleys, inclines
- Atomic Structure: electron shells, orbitals, atomic models

Return ONLY a JSON object: {"topic": "TopicName", "variables": ["var1", "var2"]}
No markdown formatting, just the raw JSON."""

    payload = {
        "contents": [{
            "parts": [
                {"text": f"{system_prompt}\nContext text: {ocr_text[:200]}"},
                {
                    "inline_data": {
                        "mime_type": mime_type,
                        "data": b64_image
                    }
                }
            ]
        }],
        "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 300,
            "response_mime_type": "application/json"
        }
    }
    
    response = _gemini_request_with_retry(url, payload, timeout=60)
    if not response:
        return "Unknown", []
    data = response.json()
    
    try:
        candidates = data.get('candidates', [])
        if not candidates:
            print(f"⚠ Gemini Vision Trace: No candidates in response. Data: {data}")
            return "Unknown", []
            
        content = candidates[0].get('content', {})
        parts = content.get('parts', [])
        if not parts:
             # Safety check for 'finishReason'
            finish_reason = candidates[0].get('finishReason')
            print(f"⚠ Gemini Vision Trace: No parts. Finish Reason: {finish_reason}")
            return "Unknown", []

        raw = parts[0].get('text', '')
        print(f"💎 Gemini Vision Response: {raw[:100]}...")
        parsed = extract_json_from_text(raw)
        if parsed:
            return parsed.get("topic", "Unknown"), [str(x) for x in parsed.get("variables", [])]
        else:
            print(f"❌ Failed to extract JSON from Vision response: {raw[:200]}")
    except Exception as e:
        print(f"❌ Gemini Vision Parse Error: {e}")
        
    return "Unknown", []
