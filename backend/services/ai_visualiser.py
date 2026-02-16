import json
import re
import requests
import time
from typing import Dict, Any, Optional
from config import GEMINI_API_KEY, GEMINI_MODEL, AIML_API_KEY
from pydantic import BaseModel, Field


class ParameterUpdate(BaseModel):
    updated_parameters: Dict[str, Any] = Field(description="Dictionary of updated parameter values. Empty if no changes needed.")
    ai_response: str = Field(description="Response to the user.")


def clean_json_output(text: str):
    text = text.strip()
    text = re.sub(r"```json", "", text)
    text = re.sub(r"```", "", text)
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    
    # Try to find JSON object
    match = re.search(r'\{[\s\S]*\}', text)
    if match:
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            pass
    return None


async def adjust_parameters_with_ai(template_id: str, current_params: Dict[str, Any], user_prompt: str, api_key: str = None) -> Dict[str, Any]:
    """
    Uses Google Gemini to interpret user prompt and update visualiser parameters.
    """
    # Use provided key or fall back to config
    gemini_key = api_key if (api_key and api_key.startswith("AIza")) else GEMINI_API_KEY
    
    if not gemini_key:
        return {"updated_parameters": {}, "ai_response": "AI not configured."}
    
    system_prompt = f"""
    You are an expert Physics Tutor and Simulation Controller.
    
    Current Simulation: {template_id}
    Current Parameters: {current_params}
    User Request: "{user_prompt}"
    
    Tasks:
    1. If user asks to change simulation (e.g. "faster", "angle 45"), update relevant parameters.
    2. If user asks a question, answer it.
    
    Output strictly as JSON:
    {{
      "updated_parameters": {{ "velocity": 20 }},
      "ai_response": "I have set the velocity to 20 m/s."
    }}
    """
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={gemini_key}"
    
    payload = {
        "contents": [{
            "parts": [{"text": system_prompt}]
        }],
        "generationConfig": {
            "temperature": 0.3,
            "maxOutputTokens": 500,
            "response_mime_type": "application/json"
        }
    }
    
    max_retries = 3
    for attempt in range(max_retries):
        try:
            print(f"💎 Adjusting parameters via Gemini for: {template_id}")
            response = requests.post(url, json=payload, headers={"Content-Type": "application/json"}, timeout=60)
            
            # Handle rate limiting with retry
            if response.status_code == 429:
                wait_time = (2 ** attempt) + 1
                print(f"⏳ Rate limited (429). Waiting {wait_time}s (attempt {attempt+1}/{max_retries})")
                time.sleep(wait_time)
                continue
            
            response.raise_for_status()
            
            data = response.json()
            
            if 'candidates' in data and len(data['candidates']) > 0:
                raw_text = data['candidates'][0]['content']['parts'][0]['text']
                parsed = clean_json_output(raw_text)
                
                if parsed:
                    return {
                        "updated_parameters": parsed.get("updated_parameters", {}),
                        "ai_response": parsed.get("ai_response", "")
                    }
            
        except requests.exceptions.HTTPError as e:
            if hasattr(e, 'response') and e.response is not None and e.response.status_code == 429:
                if attempt < max_retries - 1:
                    wait_time = (2 ** attempt) + 1
                    print(f"⏳ Rate limited (429). Waiting {wait_time}s...")
                    time.sleep(wait_time)
                    continue
            print(f"❌ Visualiser Params Error: {e}")
        except Exception as e:
            print(f"❌ Visualiser Params Error: {e}")

    return {"updated_parameters": {}, "ai_response": "AI Error."}


def generate_visualiser_image(prompt: str) -> Optional[str]:
    """
    Generates an image using AIML API (flux/schnell).
    Returns the Image URL.
    """
    if not AIML_API_KEY:
        print("❌ AIML_API_KEY missing.")
        return None

    url = "https://api.aimlapi.com/v1/images/generations/"
    
    payload = {
      "model": "flux/schnell",
      "prompt": f" Educational Diagram: {prompt}",
      "n": 1,
      "size": "512x512" 
    }
    
    headers = {
      "Authorization": f"Bearer {AIML_API_KEY}", 
      "content-type": "application/json"
    }

    try:
        print(f"DEBUG: Generating image via AIML API for prompt: {prompt[:30]}...")
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        res_json = response.json()
        
        if "data" in res_json and len(res_json["data"]) > 0:
             return res_json["data"][0].get("url")
             
        return None

    except Exception as e:
        print(f"❌ Image Gen Error: {e}")
        return None
