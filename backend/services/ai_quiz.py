import json
import re
import requests
import time
from typing import List, Optional
from pydantic import BaseModel
from config import GEMINI_API_KEY, GEMINI_MODEL


class QuizQuestionModel(BaseModel):
    question: str
    options: List[str]
    correct_index: int
    explanation: str
    misconceptions: Optional[List[str]] = None
    takeaway: Optional[str] = None


class QuizGenerationResult(BaseModel):
    topic: str
    questions: List[QuizQuestionModel]


# ============================================================
# FALLBACK SAMPLE QUIZZES (for when API is rate-limited)
# ============================================================
SAMPLE_QUIZZES = {
    "Kinematics": {
        "topic": "Kinematics",
        "difficulty": "mixed",
        "questions": [
            {
                "question": "A car accelerates uniformly from rest to 20 m/s in 5 seconds. What is its acceleration?",
                "options": ["2 m/s²", "4 m/s²", "10 m/s²", "100 m/s²"],
                "correct_index": 1,
                "explanation": "Using v = u + at with u=0, v=20, t=5: a = (20-0)/5 = 4 m/s²",
                "takeaway": "For uniform acceleration from rest: a = v/t"
            },
            {
                "question": "An object is thrown vertically upward. At its highest point, which of the following is true?",
                "options": ["Velocity is zero, acceleration is zero", "Velocity is zero, acceleration is 9.8 m/s² downward", "Velocity is maximum, acceleration is zero", "Both velocity and acceleration are maximum"],
                "correct_index": 1,
                "explanation": "At the highest point, velocity becomes zero momentarily but acceleration due to gravity (9.8 m/s² downward) remains constant throughout.",
                "takeaway": "Gravity never stops acting - only velocity becomes zero at peak"
            },
            {
                "question": "A ball is dropped from a height. If air resistance is negligible, its velocity after 3 seconds is approximately:",
                "options": ["10 m/s", "20 m/s", "30 m/s", "45 m/s"],
                "correct_index": 2,
                "explanation": "Using v = gt = 10 × 3 = 30 m/s (taking g ≈ 10 m/s²)",
                "takeaway": "Free fall velocity = g × time"
            },
            {
                "question": "The area under a velocity-time graph represents:",
                "options": ["Acceleration", "Displacement", "Speed", "Force"],
                "correct_index": 1,
                "explanation": "The area under v-t graph gives displacement. For uniform motion, it's simply v × t.",
                "takeaway": "Area under v-t graph = displacement"
            },
            {
                "question": "Two objects are dropped from different heights. Which reaches the ground first?",
                "options": ["The heavier object", "The lighter object", "Both reach at the same time", "The one dropped from lower height"],
                "correct_index": 3,
                "explanation": "The object dropped from lower height reaches first because it has less distance to cover. Mass doesn't affect fall time (ignoring air resistance).",
                "takeaway": "Fall time depends on height, not mass"
            }
        ]
    },
    "Optics": {
        "topic": "Optics",
        "difficulty": "mixed",
        "questions": [
            {
                "question": "When light passes from air to glass, which property remains unchanged?",
                "options": ["Wavelength", "Frequency", "Speed", "Direction"],
                "correct_index": 1,
                "explanation": "Frequency of light remains constant when passing between media. Wavelength and speed change, but frequency stays the same.",
                "takeaway": "Frequency is determined by the source, not the medium"
            },
            {
                "question": "A concave mirror is used in car headlights to:",
                "options": ["Converge light", "Diverge light", "Produce parallel beams", "Absorb light"],
                "correct_index": 2,
                "explanation": "When a light source is placed at the focus of a concave mirror, it produces parallel beams of light for better illumination.",
                "takeaway": "Object at focus → parallel reflected rays"
            },
            {
                "question": "Total internal reflection occurs when light travels from:",
                "options": ["Rarer to denser medium", "Denser to rarer medium at angle > critical angle", "Any medium to vacuum", "Vacuum to any medium"],
                "correct_index": 1,
                "explanation": "TIR occurs only when light goes from denser to rarer medium AND the angle of incidence exceeds the critical angle.",
                "takeaway": "TIR needs: denser→rarer + angle > critical"
            },
            {
                "question": "The power of a lens with focal length 25 cm is:",
                "options": ["0.25 D", "2.5 D", "4 D", "25 D"],
                "correct_index": 2,
                "explanation": "Power P = 1/f (in meters) = 1/0.25 = 4 D (Diopters)",
                "takeaway": "Power (D) = 1 / focal length (m)"
            },
            {
                "question": "Which lens is used to correct myopia (short-sightedness)?",
                "options": ["Convex lens", "Concave lens", "Cylindrical lens", "Bifocal lens"],
                "correct_index": 1,
                "explanation": "Myopia occurs when the eye forms images before the retina. A concave (diverging) lens is used to diverge light rays before they enter the eye.",
                "takeaway": "Myopia → Concave lens, Hypermetropia → Convex lens"
            }
        ]
    },
    "Mechanics": {
        "topic": "Mechanics",
        "difficulty": "mixed",
        "questions": [
            {
                "question": "A body of mass 5 kg is accelerating at 2 m/s². What is the net force acting on it?",
                "options": ["2.5 N", "7 N", "10 N", "0.4 N"],
                "correct_index": 2,
                "explanation": "Using Newton's second law: F = ma = 5 × 2 = 10 N",
                "takeaway": "F = ma is the foundation of mechanics"
            },
            {
                "question": "When a car takes a circular turn, the force that prevents it from skidding is:",
                "options": ["Gravitational force", "Centrifugal force", "Friction force", "Normal force"],
                "correct_index": 2,
                "explanation": "Friction between tires and road provides the centripetal force needed for circular motion.",
                "takeaway": "Friction provides centripetal force in turns"
            },
            {
                "question": "The momentum of a body is doubled. Its kinetic energy becomes:",
                "options": ["Same", "Doubled", "Quadrupled", "Halved"],
                "correct_index": 2,
                "explanation": "KE = p²/2m. If p doubles, KE becomes (2p)²/2m = 4p²/2m = 4 times the original KE.",
                "takeaway": "KE ∝ p², so doubling momentum quadruples KE"
            },
            {
                "question": "A satellite orbiting Earth is in:",
                "options": ["Stable equilibrium", "Unstable equilibrium", "Free fall", "No acceleration state"],
                "correct_index": 2,
                "explanation": "An orbiting satellite is continuously falling towards Earth, but its tangential velocity keeps it from hitting the surface.",
                "takeaway": "Orbital motion = continuous free fall"
            },
            {
                "question": "Work done by friction is always:",
                "options": ["Positive", "Negative", "Zero", "Depends on the situation"],
                "correct_index": 3,
                "explanation": "Kinetic friction does negative work (opposes motion), but static friction can do positive, negative, or zero work depending on the scenario.",
                "takeaway": "Static friction can do positive work (e.g., walking)"
            }
        ]
    },
    "Chemistry": {
        "topic": "Chemistry",
        "difficulty": "mixed",
        "questions": [
            {
                "question": "The nucleus of an atom consists of:",
                "options": ["Electrons and protons", "Electrons and neutrons", "Protons and neutrons", "All of the above"],
                "correct_index": 2,
                "explanation": "The nucleus contains protons and neutrons, while electrons orbit around it.",
                "takeaway": "Nucleus = Protons + Neutrons"
            },
            {
                "question": "Isotopes are atoms of the same element with different numbers of:",
                "options": ["Protons", "Electrons", "Neutrons", "Positrons"],
                "correct_index": 2,
                "explanation": "Isotopes have the same number of protons (atomic number) but different neutrons (mass number).",
                "takeaway": "Isotopes differ in neutron count"
            },
            {
                "question": "Which bond involves the sharing of electron pairs?",
                "options": ["Ionic bond", "Covalent bond", "Hydrogen bond", "Metallic bond"],
                "correct_index": 1,
                "explanation": "Covalent bonding involves the sharing of electron pairs between atoms.",
                "takeaway": "Covalent = Sharing electrons"
            },
            {
                "question": "The pH of a neutral solution at 25°C is:",
                "options": ["0", "7", "14", "1"],
                "correct_index": 1,
                "explanation": "A pH of 7 is neutral (like pure water). <7 is acidic, >7 is basic.",
                "takeaway": "pH 7 is neutral"
            },
            {
                "question": "What is the atomic number of Carbon?",
                "options": ["6", "12", "14", "8"],
                "correct_index": 0,
                "explanation": "Carbon has 6 protons, so its atomic number is 6.",
                "takeaway": "Carbon Z = 6"
            }
        ]
    },
    "Biology": {
        "topic": "Biology",
        "difficulty": "mixed",
        "questions": [
             {
                "question": "Which organelle is known as the powerhouse of the cell?",
                "options": ["Nucleus", "Ribosome", "Mitochondria", "Golgi apparatus"],
                "correct_index": 2,
                "explanation": "Mitochondria generate most of the chemical energy needed to power the cell's biochemical reactions.",
                "takeaway": "Mitochondria = Powerhouse"
            },
            {
                "question": "DNA is found in which part of the cell?",
                "options": ["Cytoplasm", "Nucleus", "Membrane", "Ribosome"],
                "correct_index": 1,
                "explanation": "In eukaryotic cells, DNA is located within the nucleus.",
                "takeaway": "DNA resides in the Nucleus"
            }
        ]
    },
    "General": {
        "topic": "General Science",
        "difficulty": "mixed",
        "questions": [
             {
                "question": "What is the most abundant gas in Earth's atmosphere?",
                "options": ["Oxygen", "Carbon Dioxide", "Nitrogen", "Hydrogen"],
                "correct_index": 2,
                "explanation": "Nitrogen makes up about 78% of Earth's atmosphere.",
                "takeaway": "Nitrogen is #1 in atmosphere"
            },
            {
                "question": "Energy cannot be created or destroyed, only transformed. This is the Law of:",
                "options": ["Conservation of Energy", "Entropy", "Inertia", "Relativity"],
                "correct_index": 0,
                "explanation": "The First Law of Thermodynamics states energy is conserved.",
                "takeaway": "Energy is conserved"
            },
             {
                "question": "Speed of light in a vacuum is approximately:",
                "options": ["300,000 km/s", "150,000 km/s", "3,000 km/s", "So fast it's instant"],
                "correct_index": 0,
                "explanation": "Light travels at approx 3 × 10^8 m/s or 300,000 km/s.",
                "takeaway": "c ≈ 300,000 km/s"
            }
        ]
    }
}


def clean_json_output(text: str):
    """Extract JSON from LLM output, handling markdown and text wrapping."""
    if not text:
        return None
        
    text = text.strip()
    
    # 1. Try direct parse
    try:
        return json.loads(text)
    except:
        pass
        
    # 2. Try Regex for code blocks
    match = re.search(r"```json\s*([\s\S]*?)\s*```", text)
    if match:
        try:
             return json.loads(match.group(1))
        except:
            pass

    # 3. Try finding first { and last }
    match = re.search(r'(\{[\s\S]*\})', text)
    if match:
        try:
            return json.loads(match.group(1))
        except:
            pass
            
    # 4. Try finding first [ and last ]
    match = re.search(r'(\[[\s\S]*\])', text)
    if match:
        try:
            return json.loads(match.group(1))
        except:
            pass
    
    print(f"⚠ Failed to parse JSON from: {text[:300]}...")
    return None


def get_fallback_quiz(topic: str, num_questions: int = 5) -> dict:
    """Return a sample quiz for common topics when API fails."""
    # Try exact match first
    if topic in SAMPLE_QUIZZES:
        return _prepare_fallback(SAMPLE_QUIZZES[topic], num_questions)
    
    # Try partial match
    topic_lower = topic.lower()
    
    # Keyword mapping
    mappings = {
        "atom": "Chemistry",
        "electron": "Chemistry",
        "reaction": "Chemistry",
        "periodic": "Chemistry",
        "cell": "Biology",
        "plant": "Biology",
        "animal": "Biology",
        "force": "Mechanics",
        "motion": "Kinematics",
        "light": "Optics",
        "lens": "Optics"
    }
    
    for key, val in mappings.items():
        if key in topic_lower:
             if val in SAMPLE_QUIZZES:
                 print(f"📋 Mapped fallback: {topic} -> {val}")
                 return _prepare_fallback(SAMPLE_QUIZZES[val], num_questions)

    for key, quiz in SAMPLE_QUIZZES.items():
        if key.lower() in topic_lower or topic_lower in key.lower():
            print(f"📋 Matched fallback: {key}")
            return _prepare_fallback(quiz, num_questions)
            
    # Default to General
    print(f"📋 Using General fallback for {topic}")
    return _prepare_fallback(SAMPLE_QUIZZES["General"], num_questions)

def _prepare_fallback(quiz_data, num):
    result = quiz_data.copy()
    result["questions"] = result["questions"][:num]
    result["_fallback"] = True
    return result


ADVANCED_QUIZ_PROMPT = """You are an expert AI tutor and examiner.
Generate high-quality MCQs for the topic: {topic}

Requirements:
- Create EXACTLY {num_questions} questions
- Mix conceptual and numerical questions
- Include 4 options per question (A, B, C, D)
- One correct answer with correct_index (0-3)
- Brief explanation for each

OUTPUT ONLY VALID JSON (no markdown):
{{
  "topic": "{topic}",
  "questions": [
    {{
      "question": "Question text here",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_index": 0,
      "explanation": "Brief explanation",
      "takeaway": "One-line key insight"
    }}
  ]
}}"""


async def generate_quiz_with_ai(topic: str, num_questions: int = 5, api_key: str = None) -> dict:
    """
    AI generates MCQs using Google Gemini with retry logic and fallback support.
    """
    
    if not topic or len(topic.strip()) < 2:
        return {"error": "Invalid topic", "questions": []}
    
    if num_questions < 1 or num_questions > 20:
        num_questions = 5
    
    # Use provided key or fall back to config
    gemini_key = api_key if (api_key and api_key.startswith("AIza")) else GEMINI_API_KEY
    
    SYSTEM_FALLBACK_KEY = "AIzaSyBek9KwVGRNicmxCNO1Zv4ubgevRUU4LZQ"

    if not gemini_key:
        print("⚠ No Gemini API key. Attempting System Fallback Key.")
        gemini_key = SYSTEM_FALLBACK_KEY
    
    full_prompt = ADVANCED_QUIZ_PROMPT.format(topic=topic.strip(), num_questions=num_questions)
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={gemini_key}"
    
    payload = {
        "contents": [{
            "parts": [{"text": full_prompt}]
        }],
        "generationConfig": {
            "temperature": 0.5,
            "maxOutputTokens": 4000,
            "response_mime_type": "application/json"
        }
    }

    # Retry logic with exponential backoff & Key Fallback
    SYSTEM_FALLBACK_KEY = "AIzaSyBek9KwVGRNicmxCNO1Zv4ubgevRUU4LZQ"
    current_key = gemini_key
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={current_key}"

    max_retries = 2
    for attempt in range(max_retries + 1):
        try:
            print(f"🎯 Quiz attempt {attempt+1}/{max_retries+1}: {topic} ({num_questions} questions) via Gemini")
            
            response = requests.post(url, json=payload, headers={"Content-Type": "application/json"}, timeout=60)
            
            # Handle Bad Key (400) or Permission (403) or Auth (401)
            if response.status_code in [400, 401, 403]:
                if current_key != SYSTEM_FALLBACK_KEY:
                     print(f"⚠ Gemini Key Error ({response.status_code}). Switching to System Fallback Key...")
                     current_key = SYSTEM_FALLBACK_KEY
                     url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={current_key}"
                     continue # Immediate retry with new key
                else:
                     print(f"❌ Fallback Key also failed ({response.status_code}).")
                     break # Stop retrying

            # Handle rate limiting with retry AND Key Switch
            if response.status_code == 429:
                print(f"⏳ Rate limited (429).")
                if current_key != SYSTEM_FALLBACK_KEY:
                    print("🔄 Switching to System Fallback Key for Rate Limit...")
                    current_key = SYSTEM_FALLBACK_KEY
                    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={current_key}"
                    continue # Immediate retry with new key

                if attempt < max_retries:
                    wait_time = (2 ** attempt) * 2  # 2s, 4s
                    print(f"⏳ Waiting {wait_time}s before retry...")
                    time.sleep(wait_time)
                    continue
                else:
                    print("❌ Rate limit persists. Using fallback quiz...")
                    return get_fallback_quiz(topic, num_questions)
            
            response.raise_for_status()
            data = response.json()
            
            if 'candidates' not in data or len(data['candidates']) == 0:
                continue
                
            raw_text = data['candidates'][0]['content']['parts'][0]['text']
            print(f"💎 Gemini Quiz Response received ({len(raw_text)} chars)")
            parsed = clean_json_output(raw_text)
            
            if not parsed:
                continue
            
            # Validate and clean questions
            if "questions" not in parsed:
                if isinstance(parsed, list):
                    parsed = {"topic": topic, "questions": parsed}
                else:
                    continue
            
            if not isinstance(parsed.get("questions"), list) or len(parsed["questions"]) == 0:
                continue
                
            # Validate each question
            validated = []
            for q in parsed["questions"]:
                if not isinstance(q, dict):
                    continue
                question_text = q.get("question", "")
                options = q.get("options", [])
                if not question_text or len(options) < 2:
                    continue
                while len(options) < 4:
                    options.append(f"Option {len(options)+1}")
                correct = q.get("correct_index", 0)
                if not isinstance(correct, int) or correct < 0 or correct > 3:
                    correct = 0
                validated.append({
                    "question": str(question_text),
                    "options": [str(o) for o in options[:4]],
                    "correct_index": correct,
                    "explanation": str(q.get("explanation", "")),
                    "takeaway": str(q.get("takeaway", ""))
                })
            
            if len(validated) > 0:
                print(f"✅ Generated {len(validated)} questions via Gemini")
                return {"topic": topic, "difficulty": "mixed", "questions": validated}

        except requests.exceptions.Timeout:
            print(f"⏱ Timeout on attempt {attempt+1}")
            if attempt == max_retries:
                return get_fallback_quiz(topic, num_questions)
        except Exception as e:
            print(f"❌ Error attempt {attempt+1}: {e}")
            if attempt == max_retries:
                return get_fallback_quiz(topic, num_questions)
    
    # All retries failed, try fallback
    return get_fallback_quiz(topic, num_questions)
