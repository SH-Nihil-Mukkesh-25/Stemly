import json
import requests
import re
from typing import List, Tuple
from config import OLLAMA_BASE_URL, LOCAL_MODEL, OPENROUTER_API_KEY


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
    
    # Find JSON object
    match = re.search(r'\{[\s\S]*?\}', text)
    if match:
        try:
            return json.loads(match.group())
        except:
            pass
    
    return None


import base64
from config import OLLAMA_BASE_URL, LOCAL_MODEL, OPENROUTER_API_KEY, VISION_MODEL


# ... existing keywords/parsing ...

async def detect_topic(ocr_text: str, image_path: str = None) -> Tuple[str, List[str]]:
    """
    Detect STEM topic.
    Strategy:
    1. If OCR text is available, try Text-Only model (Fast/Cheap).
    2. If Text model fails (returns Unknown) OR OCR is poor, usage Vision model (Slow/Smart).
    """

    # 1. Try Keyword fallback first (Fastest)
    keyword_topic = detect_topic_from_keywords(ocr_text) if ocr_text else "Unknown"
    
    # 2. Determine if we skip straight to Vision (Sparse text)
    skip_text_model = not ocr_text or len(ocr_text.strip()) < 10
    
    topic = "Unknown"
    variables = []

    # --- ATTEMPT 1: TEXT MODEL ---
    if not skip_text_model:
        print(f"🔍 Text detected ({len(ocr_text)} chars). Trying Text Model...")
        try:
            topic, variables = await _query_text_model(ocr_text)
        except Exception as e:
            print(f"⚠ Text model error: {e}")
            topic = "Unknown"

    # --- ATTEMPT 2: VISION MODEL (Fallback) ---
    # Trigger if:
    # a) We skipped text model (text too short)
    # b) Text model returned "Unknown"
    # c) Text model returned "General Science" (too vague)
    
    if (topic == "Unknown" or topic == "General Science") and image_path and VISION_MODEL:
        reason = "Short Text" if skip_text_model else "Text Model failed"
        print(f"👁 {reason}. Switching to VISION model: {VISION_MODEL}")
        
        try:
            topic, variables = await _query_vision_model(image_path)
        except Exception as e:
            print(f"❌ Vision model error: {e}")
            
    # Final Fallback
    if topic == "Unknown":
        topic = keyword_topic

    return topic, variables


async def _query_text_model(text: str) -> Tuple[str, List[str]]:
    """Helper to query text-only model."""
    system_prompt = """You are a STEM topic classifier. Return ONLY valid JSON.
Output format: {"topic": "TopicName", "variables": ["x", "y"], "confidence": 0.9}
Common topics: Optics, Kinematics, Mechanics, Electricity, Magnetism, Thermodynamics, Waves, Calculus, Algebra, Geometry, Chemistry, Biology, Atom, Projectile Motion.
IMPORTANT: Be specific. If the text describes 2D motion, angles, or parabolas, classify as 'Projectile Motion' instead of generic 'Kinematics'. If it involves dropping objects, use 'Free Fall'."""

    payload = {
        "model": LOCAL_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Classify this text:\n{text[:800]}"}
        ],
        "max_tokens": 150,
        "temperature": 0.1
    }
    
    return _execute_request(payload)


async def _query_vision_model(image_path: str) -> Tuple[str, List[str]]:
    """Helper to query vision model."""
    with open(image_path, "rb") as img_file:
        b64_image = base64.b64encode(img_file.read()).decode('utf-8')

    # Determine MIME type
    mime_type = "image/png" if image_path.lower().endswith(".png") else "image/jpeg"

    system_prompt = """You are a Visual STEM Expert. Analyze the image provided.
Identify the main scientific Topic. Be specific:
- Use 'Projectile Motion' for parabolic paths/cannons (NOT Kinematics).
- Use 'Free Fall' for dropping objects.
- Use 'Kinematics' only for linear/1D motion (cars, blocks).
- Other topics: Optics, Circuits, Chemistry, Calculus, Atomic Structure.
Identify any variables or values visible (e.g. v, t, x, theta, protons).
Return ONLY valid JSON: {"topic": "TopicName", "variables": ["x", "y"]}"""

    payload = {
        "model": VISION_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": [
                {"type": "text", "text": "Analyze this scientific image. What is the topic and variables?"},
                {"type": "image_url", "image_url": {"url": f"data:{mime_type};base64,{b64_image}"}}
            ]}
        ],
        "max_tokens": 300,
        "temperature": 0.1
    }
    
    return _execute_request(payload)


def _execute_request(payload: dict) -> Tuple[str, List[str]]:
    """Execute Request to OpenRouter."""
    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost",
        "X-Title": "Stemly"
    }

    response = requests.post(f"{OLLAMA_BASE_URL}/chat/completions", json=payload, headers=headers, timeout=50)
    response.raise_for_status()
    data = response.json()
    
    if 'choices' not in data or len(data['choices']) == 0:
        return "Unknown", []
        
    raw = data['choices'][0]['message']['content']
    print(f"📝 AI Response: {raw[:100]}...")
    
    parsed = extract_json_from_text(raw)
    if parsed:
        t = parsed.get("topic", "Unknown")
        v = [str(x) for x in parsed.get("variables", [])]
        return t, v
        
    return "Unknown", []
