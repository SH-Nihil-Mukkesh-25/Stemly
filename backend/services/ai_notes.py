import json
import re
import requests
import time
from typing import Optional
from fastapi.concurrency import run_in_threadpool
from config import GEMINI_API_KEY, GEMINI_FALLBACK_API_KEY, GEMINI_MODEL
from models.notes_models import NotesResponse


def clean_json_output(text: str):
    """Extract JSON from LLM output, handling markdown code blocks and various formats."""
    if not text:
        return None
        
    text = text.strip()
    
    # Strategy 1: Strip markdown code blocks more aggressively
    # Handle ```json ... ``` format
    json_block_match = re.search(r'```json\s*([\s\S]*?)\s*```', text)
    if json_block_match:
        text = json_block_match.group(1).strip()
    else:
        # Also handle ``` ... ``` without json tag
        code_block_match = re.search(r'```\s*([\s\S]*?)\s*```', text)
        if code_block_match:
            text = code_block_match.group(1).strip()
        else:
            # Fallback: just strip the markers if they exist
            text = re.sub(r'^```json\s*', '', text)
            text = re.sub(r'^```\s*', '', text)
            text = re.sub(r'\s*```$', '', text)
            text = text.strip()
    
    # Strategy 2: Try direct parse
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    
    # Strategy 3: Find JSON object with greedy regex (outermost braces)
    # Use a more careful approach to find balanced braces
    match = re.search(r'\{[\s\S]*\}', text)
    if match:
        json_str = match.group()
        try:
            return json.loads(json_str)
        except json.JSONDecodeError:
            # Try to fix common issues
            pass
    
    # Strategy 4: Find the first { and try parsing from there
    first_brace = text.find('{')
    if first_brace != -1:
        potential_json = text[first_brace:]
        try:
            return json.loads(potential_json)
        except json.JSONDecodeError:
            pass
    
    print(f"❌ clean_json_output: All strategies failed. Text starts with: {text[:100]}")
    return None


def _call_gemini_api_sync(prompt: str, system_prompt: str = "", max_tokens: int = 1000, timeout: int = 120, api_key: str = None, json_mode: bool = False):
    """Blocking call to Google Gemini API with exponential backoff retry."""
    key = api_key or GEMINI_API_KEY
    fallback_key = GEMINI_FALLBACK_API_KEY if (GEMINI_FALLBACK_API_KEY and GEMINI_FALLBACK_API_KEY.startswith("AIza")) else None

    if not key:
        if fallback_key:
            print("⚠ No primary Gemini API key configured. Using fallback key from environment.")
            key = fallback_key
        else:
            print("⚠ No Gemini API key configured.")
            return None
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={key}"
    
    # Combine system and user prompts
    full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt
    
    payload = {
        "contents": [{
            "parts": [{"text": full_prompt}]
        }],
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": max_tokens
        }
    }

    if json_mode:
        payload["generationConfig"]["response_mime_type"] = "application/json"
    
    max_retries = 3
    current_key = key
    
    for attempt in range(max_retries):
        try:
            # Update URL with current key (in case it changed)
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={current_key}"
            
            print(f"💎 Calling Gemini API ({GEMINI_MODEL})...")
            response = requests.post(url, json=payload, headers={"Content-Type": "application/json"}, timeout=timeout)
            
            # Key/Permission Error Fallback
            if response.status_code in [400, 401, 403]:
                print(f"⚠ Gemini Key Error ({response.status_code}).")
                if fallback_key and current_key != fallback_key:
                    print("🔄 Switching to fallback key from environment and retrying...")
                    current_key = fallback_key
                    continue
                else:
                    print("❌ Available Gemini key failed and no alternate fallback key is configured.")
                    break

            # Handle rate limiting with retry AND Key Switch
            if response.status_code == 429:
                print("⏳ Rate limited (429).")
                if fallback_key and current_key != fallback_key:
                    print("🔄 Switching to fallback key from environment for rate limit handling...")
                    current_key = fallback_key
                    continue # Immediate retry with new key
                
                wait_time = (2 ** attempt) + 1
                print(f"⏳ Verification: Waiting {wait_time}s (attempt {attempt+1}/{max_retries})")
                time.sleep(wait_time)
                continue
                
            response.raise_for_status()
            data = response.json()
            
            if 'candidates' in data and len(data['candidates']) > 0:
                return data['candidates'][0]['content']['parts'][0]['text']
            return None
            
        except requests.exceptions.HTTPError as e:
            # ... (Rest of exception handling)
            if hasattr(e, 'response') and e.response is not None and e.response.status_code == 429:
                if attempt < max_retries - 1:
                    wait_time = (2 ** attempt) + 1
                    print(f"⏳ Rate limited (429). Waiting {wait_time}s...")
                    time.sleep(wait_time)
                    continue
            print(f"❌ Gemini API Error: {e}")
            if hasattr(e, 'response') and e.response:
                print(f"Response Body: {e.response.text}")
             # Non-critical retry for network errors?
             # Let's just return None to avoid infinite loops unless 429 caught above
            return None
        except Exception as e:
            print(f"❌ Gemini API Error: {e}")
            return None
    
    print(f"❌ Max retries ({max_retries}) exceeded for Gemini API")
    return None


async def generate_notes(
    topic: str, 
    variables: list, 
    image_path: Optional[str] = None, 
    ocr_text: Optional[str] = None, 
    api_key: str = None
) -> NotesResponse:
    
    # Context
    context = f"Topic: {topic}\nVars: {variables}"
    if ocr_text:
        context += f"\nOCR: {ocr_text[:1000]}"

    system_prompt = """
    Create DETAILED, STUDENT-FRIENDLY study notes in strict JSON format.
    
    Guidelines:
    - **Explanation**: Write a clear, 3-4 sentence paragraph defining the concept simply. Use analogies if helpful.
    - **Variable Breakdown**: Define each variable clearly with units.
    - **Example**: Provide a concrete, step-by-step example problem with numbers.
    - **Summary**: Key takeaways for quick revision.
    
    Output strictly as JSON:
    {
      "explanation": "Detailed explanation of the concept...",
      "variable_breakdown": {"v": "velocity (m/s)", "t": "time (s)"},
      "formulas": ["F = ma"],
      "example": "If a car accelerates...",
      "mistakes": ["Confusing speed with velocity"],
      "practice_questions": ["What is the force if...?", "Calculate time when..."],
      "summary": ["Force causes acceleration", "Mass is inertia"],
      "resources": ["Newton's Laws Video"]
    }
    """
    
    user_prompt = f"Topic: {topic}. Context: {context}"

    print(f"💎 Generating notes via Gemini ({GEMINI_MODEL})...")

    raw_text = await run_in_threadpool(
        _call_gemini_api_sync, 
        user_prompt, 
        system_prompt, 
        8192,  # Increased from 1000 to prevent truncation
        120, 
        api_key if (api_key and api_key.startswith("AIza")) else None,
        True # json_mode=True
    )

    if not raw_text:
        print("⚠ Notes generation failed. Returning fallback.")
        return NotesResponse(
            explanation="Notes generation failed. Please try again.",
            variable_breakdown={},
            formulas=[],
            example="Server error.",
            mistakes=[],
            practice_questions=[],
            summary=["Could not generate notes."],
            resources=[]
        )

    # Debug: Log raw response
    print(f"💎 Raw Gemini response (first 500 chars): {raw_text[:500]}")
    
    try:
        parsed = clean_json_output(raw_text)
        
        # Debug: Log parsed result
        print(f"💎 Parsed result type: {type(parsed)}, keys: {parsed.keys() if parsed else 'None'}")
        
        if parsed:
            # Ensure types match before returning
            if isinstance(parsed.get('variable_breakdown'), list):
                 parsed['variable_breakdown'] = {f"var_{i}": v for i, v in enumerate(parsed['variable_breakdown'])}
            if isinstance(parsed.get('summary'), str):
                 parsed['summary'] = [parsed['summary']]
                 
            return NotesResponse(**parsed)
        else:
            print(f"❌ clean_json_output returned None for: {raw_text[:200]}")
    except Exception as e:
        print(f"❌ Notes parse error: {e}")
        print(f"❌ Raw text that failed: {raw_text[:300]}")

    return NotesResponse(
            explanation="Error parsing notes.",
            variable_breakdown={},
            formulas=[],
            example="",
            mistakes=[],
            practice_questions=[],
            summary=["Invalid AI response."],
            resources=[]
    )


async def follow_up_notes(topic: str, previous_notes: dict, user_prompt: str, api_key: str = None) -> NotesResponse:
    
    context = f"Topic: {topic}\nSummary: {previous_notes.get('summary', '')}"
    
    system_prompt = """
    Answer briefly. Return strict JSON matching Schema.
    Schema:
    {
      "explanation": "Answer",
      "variable_breakdown": {}, 
      "formulas": [],
      "example": "",
      "mistakes": [],
      "practice_questions": [], 
      "summary": ["Recap"],
      "resources": []
    }
    """
    
    full_prompt = f"Q: {user_prompt}\nContext: {context}"

    raw_text = await run_in_threadpool(
        _call_gemini_api_sync, 
        full_prompt, 
        system_prompt, 
        500, 
        60, 
        api_key if (api_key and api_key.startswith("AIza")) else None,
        True # json_mode=True
    )

    if not raw_text:
         return NotesResponse(explanation="AI busy.", variable_breakdown={}, formulas=[], example="", mistakes=[], practice_questions=[], summary=[], resources=[])

    try:
        parsed = clean_json_output(raw_text)
        
        if parsed:
            if isinstance(parsed.get('variable_breakdown'), list):
                 parsed['variable_breakdown'] = {}
            if isinstance(parsed.get('summary'), str):
                 parsed['summary'] = [parsed['summary']]
            return NotesResponse(**parsed)
    except Exception:
        pass
        
    return NotesResponse(explanation="AI Error", variable_breakdown={}, formulas=[], example="", mistakes=[], practice_questions=[], summary=[], resources=[])
