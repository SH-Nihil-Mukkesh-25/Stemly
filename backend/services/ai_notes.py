import json
import re
import requests
from typing import Optional, List
from fastapi.concurrency import run_in_threadpool
from config import OLLAMA_BASE_URL, LOCAL_MODEL, OPENROUTER_API_KEY
from models.notes_models import NotesResponse

def clean_json_output(text: str):
    text = text.strip()
    text = re.sub(r"```json", "", text)
    text = re.sub(r"```", "", text)
    text = text.strip()
    try:
        return json.loads(text)
    except:
        return None

def _call_openrouter_api_sync(payload: dict, timeout: int = 120):
    """Blocking call to OpenRouter API."""
    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost",
        "X-Title": "Stemly"
    }
    try:
        url = f"{OLLAMA_BASE_URL}/chat/completions"
        response = requests.post(url, json=payload, headers=headers, timeout=timeout)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"❌ OpenRouter Sync Error: {e}")
        if hasattr(e, 'response') and e.response:
             print(f"Response Body: {e.response.text}")
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
    
    payload = {
        "model": LOCAL_MODEL, # "gpt-4o"
        "messages": [
             {"role": "system", "content": system_prompt},
             {"role": "user", "content": f"Topic: {topic}. Context: {context}"}
        ],
        "max_tokens": 1000,
        "temperature": 0.7
    }

    print(f"DEBUG: Generating notes via OpenRouter ({LOCAL_MODEL})...")

    data = await run_in_threadpool(_call_openrouter_api_sync, payload, timeout=120)

    if not data:
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

    try:
        raw_text = data['choices'][0]['message']['content']
        parsed = clean_json_output(raw_text)
        
        if parsed:
            # Ensure types match before returning
            if isinstance(parsed.get('variable_breakdown'), list):
                 parsed['variable_breakdown'] = {f"var_{i}": v for i, v in enumerate(parsed['variable_breakdown'])}
            if isinstance(parsed.get('summary'), str):
                 parsed['summary'] = [parsed['summary']]
                 
            return NotesResponse(**parsed)
    except Exception:
        pass

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
    
    payload = {
        "model": LOCAL_MODEL,
        "messages": [
             {"role": "system", "content": system_prompt},
             {"role": "user", "content": f"Q: {user_prompt}\nContext: {context}"}
        ],
        "max_tokens": 500
    }

    data = await run_in_threadpool(_call_openrouter_api_sync, payload, timeout=60)

    if not data:
         return NotesResponse(explanation="AI busy.", variable_breakdown={}, formulas=[], example="", mistakes=[], practice_questions=[], summary=[], resources=[])

    try:
        raw_text = data['choices'][0]['message']['content']
        parsed = clean_json_output(raw_text)
        
        if parsed:
            if isinstance(parsed.get('variable_breakdown'), list):
                 parsed['variable_breakdown'] = {}
            if isinstance(parsed.get('summary'), str):
                 parsed['summary'] = [parsed['summary']]
            return NotesResponse(**parsed)
    except:
        pass
        
    return NotesResponse(explanation="AI Error", variable_breakdown={}, formulas=[], example="", mistakes=[], practice_questions=[], summary=[], resources=[])

