"""
AI Chat service for the visualiser.
Handles both visualization control (JSON) and concept explanation (text).
Uses Google Gemini API.
"""
import json
import requests
import time
from config import GEMINI_API_KEY, GEMINI_FALLBACK_API_KEY, GEMINI_MODEL


VISUALISER_CHAT_PROMPT = """You are an Intelligent Visualization Assistant embedded inside an educational app.

You have two distinct responsibilities:
1. Visualization Controller – modify visualization parameters by editing JSON.
2. Conceptual Tutor – explain physics/maths concepts conversationally.

🔀 Core Decision Rule (CRITICAL)

For every user message, you MUST first classify the intent:

MODE 1: VISUAL_UPDATE
Use this mode ONLY IF the user:
- Asks to change, adjust, modify, increase/decrease, animate, pause, reset, or control the visualization
- Mentions variables like: speed, velocity, acceleration, time step, mass, force, angle, direction, scale, zoom, focal length
- Uses imperative commands like: "reduce the speed", "make it faster", "change acceleration to 5"

MODE 2: CHAT_EXPLANATION
Use this mode if the user:
- Asks why, how, what is, explain, doubt, concept, theory
- Requests derivations, intuition, examples
- Asks about graphs, formulas, assumptions or just chats.

👉 ALWAYS Output strictly as JSON. 
Schema:
{{
  "type": "update" | "chat",
  "changes": {{ "variable_name": value }},  // Only for "update" type
  "message": "Text response here"         // Only for "chat" type
}}

Examples:

User: "Set speed to 50"
JSON:
{{
  "type": "update",
  "changes": {{ "speed": 50 }}
}}

User: "Why does it curve?"
JSON:
{{
  "type": "chat", 
  "message": "It curves because gravity acts downwards..."
}}

📊 Current Visualization State:
Topic: {topic}
Parameters: {parameters}

Rules:
- Only modify variables from the current parameters list above.
- Values must be numbers (integer or float).
- No markdown formatting in the JSON output.
- If the user asks for "gold atoms", infer proper values.

USER MESSAGE:
{user_message}"""


async def process_visualiser_chat(
    user_message: str,
    topic: str,
    parameters: dict,
    chat_history: list = None,
    api_key: str = None
) -> dict:
    """
    Process a chat message for the visualiser using Google Gemini.
    Returns either JSON updates or text explanation.
    """
    
    if not user_message or len(user_message.strip()) < 2:
        return {"type": "chat", "message": "Please ask a question or give a command."}
    
    # Use provided key or fall back to config
    gemini_key = api_key if (api_key and api_key.startswith("AIza")) else GEMINI_API_KEY
    if not gemini_key and GEMINI_FALLBACK_API_KEY and GEMINI_FALLBACK_API_KEY.startswith("AIza"):
        gemini_key = GEMINI_FALLBACK_API_KEY
    
    if not gemini_key:
        return {"type": "chat", "message": "AI not configured. Please add your Gemini API key."}
    
    # Format parameters for prompt
    params_str = json.dumps(parameters, indent=2) if parameters else "{}"
    
    full_prompt = VISUALISER_CHAT_PROMPT.format(
        topic=topic,
        parameters=params_str,
        user_message=user_message.strip()
    )
    
    # Add chat history context
    if chat_history:
        history_text = "\n\nRecent conversation:\n"
        for msg in chat_history[-4:]:
            role = "User" if msg.get("isUser") else "Assistant"
            history_text += f"{role}: {msg.get('text', '')[:200]}\n"
        full_prompt = history_text + "\n" + full_prompt
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={gemini_key}"
    
    payload = {
        "contents": [{
            "parts": [{"text": full_prompt}]
        }],
        "generationConfig": {
            "temperature": 0.3,
            "maxOutputTokens": 800,
            "response_mime_type": "application/json"
        }
    }
    
    max_retries = 3
    current_key = gemini_key
    fallback_key = GEMINI_FALLBACK_API_KEY if (GEMINI_FALLBACK_API_KEY and GEMINI_FALLBACK_API_KEY.startswith("AIza")) else None

    for attempt in range(max_retries):
        try:
            # Update URL with current key
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={current_key}"
            
            print(f"🤖 Visualiser Chat via Gemini: '{user_message[:50]}...'")
            
            response = requests.post(url, json=payload, headers={"Content-Type": "application/json"}, timeout=60)
            
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
            
            if 'candidates' not in data or len(data['candidates']) == 0:
                continue
            
            raw_response = data['candidates'][0]['content']['parts'][0]['text'].strip()
            return _parse_chat_response(raw_response)
            
        except requests.exceptions.Timeout:
            return {"type": "chat", "message": "Request timed out. Please try again."}
        except Exception as e:
            print(f"❌ Visualiser chat error: {e}")
            if attempt == max_retries - 1:
                return {"type": "chat", "message": "Sorry, I encountered an error. Please try again."}
    
    return {"type": "chat", "message": "Rate limited. Please try again."}


def _parse_chat_response(raw_response: str) -> dict:
    """Helper to parse JSON response."""
    print(f"💎 Gemini Response: {raw_response[:200]}")
    
    try:
        parsed = json.loads(raw_response)
        
        # Ensure it matches expected structure
        if parsed.get("type") == "update":
            return {
                "type": "update",
                "changes": parsed.get("changes", {})
            }
        elif parsed.get("type") == "chat":
             return {
                "type": "chat",
                "message": parsed.get("message", "")
            }
        else:
             # Fallback if structure is weird but JSON valid
             return {"type": "chat", "message": raw_response[:200]}
             
    except json.JSONDecodeError:
        print(f"❌ Failed to parse JSON: {raw_response[:100]}")
        return {"type": "chat", "message": "I couldn't understand that. Please try again."}
