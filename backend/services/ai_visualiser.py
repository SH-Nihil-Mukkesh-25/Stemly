import json
import re
import requests
from typing import Dict, Any, Optional
from config import OLLAMA_BASE_URL, LOCAL_MODEL, AIML_API_KEY
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
    except:
        return None

async def adjust_parameters_with_ai(template_id: str, current_params: Dict[str, Any], user_prompt: str, api_key: str = None) -> Dict[str, Any]:
    """
    Uses Local LLM (Ollama) to interpret user prompt and update visualiser parameters.
    """
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
    
    payload = {
        "model": LOCAL_MODEL,
        "prompt": system_prompt,
        "stream": False,
        "format": "json"
    }
    
    try:
        r = requests.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload, timeout=60)
        r.raise_for_status()
        data = clean_json_output(r.json().get("response", ""))
        
        if data:
            return {
                "updated_parameters": data.get("updated_parameters", {}),
                "ai_response": data.get("ai_response", "")
            }
        
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
        
        # AIML API (OpenAI compatible) returns:
        # { "created": 123, "data": [ { "url": "..." } ] }
        # OR sometimes specific format. Based on user script:
        # print("Generation:", response.json())
        
        # Flux response from AIML might be distinct.
        # Assuming OpenAI format standard for /generations
        if "data" in res_json and len(res_json["data"]) > 0:
             return res_json["data"][0].get("url")
             
        # Or fall back inspection
        return None

    except Exception as e:
        print(f"❌ Image Gen Error: {e}")
        return None
