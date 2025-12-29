"""
AI Chat service for the visualiser.
Handles both visualization control (JSON) and concept explanation (text).
"""
import json
import re
import requests
from config import OLLAMA_BASE_URL, LOCAL_MODEL, OPENROUTER_API_KEY


VISUALISER_CHAT_PROMPT = """You are an Intelligent Visualization Assistant embedded inside an educational app.

You have two distinct responsibilities:
1. Visualization Controller – modify visualization parameters by editing JSON.
2. Conceptual Tutor – explain physics/maths concepts conversationally in chat.

🔀 Core Decision Rule (CRITICAL)

For every user message, you MUST first classify the intent:

MODE 1: VISUAL_UPDATE
Use this mode ONLY IF the user:
- Asks to change, adjust, modify, increase/decrease, animate, pause, reset, or control the visualization
- Mentions variables like: speed, velocity, acceleration, time step, mass, force, angle, direction, scale, zoom, focal length, object distance
- Uses imperative commands like: "reduce the speed", "make it faster", "change acceleration to 5"

👉 In this mode: Return ONLY valid JSON.
DO NOT include any text before or after the JSON.
DO NOT use markdown formatting like ```json ... ```. 
Just raw JSON.

MODE 2: CHAT_EXPLANATION
Use this mode if the user:
- Asks why, how, what is, explain, doubt, concept, theory
- Requests derivations, intuition, examples
- Asks about graphs, formulas, assumptions

👉 In this mode: Respond only with natural language. Do NOT output JSON.

📊 Current Visualization State:
Topic: {topic}
Parameters: {parameters}

🧾 Visualization JSON Contract (STRICT)
When in VISUAL_UPDATE mode, output JSON exactly in this structure:
{{
  "action": "update",
  "changes": {{
    "variable_name": value
  }}
}}

Rules:
- Only modify variables from the current parameters list above.
- Values must be numbers (integer or float).
- No explanations inside JSON.
- If the user asks for "gold atoms", look at parameters like "protons" and set it to 79. Infer values scientifically.

USER MESSAGE:
{user_message}"""


async def process_visualiser_chat(
    user_message: str,
    topic: str,
    parameters: dict,
    chat_history: list = None
) -> dict:
    """
    Process a chat message for the visualiser.
    Returns either JSON updates or text explanation.
    """
    
    if not user_message or len(user_message.strip()) < 2:
        return {"type": "chat", "message": "Please ask a question or give a command."}
    
    # Format parameters for prompt
    params_str = json.dumps(parameters, indent=2) if parameters else "{}"
    
    full_prompt = VISUALISER_CHAT_PROMPT.format(
        topic=topic,
        parameters=params_str,
        user_message=user_message.strip()
    )
    
    # Build messages with history
    messages = [
        {"role": "system", "content": "You are a visualization assistant. Respond with JSON for control commands, or text for explanations. Never mix both."}
    ]
    
    # Add chat history (last 6 messages)
    if chat_history:
        for msg in chat_history[-6:]:
            messages.append({
                "role": "user" if msg.get("isUser") else "assistant",
                "content": msg.get("text", "")
            })
    
    messages.append({"role": "user", "content": full_prompt})
    
    payload = {
        "model": LOCAL_MODEL,
        "messages": messages,
        "max_tokens": 800,
        "temperature": 0.3
    }
    
    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost",
        "X-Title": "Stemly"
    }
    
    try:
        url = f"{OLLAMA_BASE_URL}/chat/completions"
        print(f"🤖 Visualiser Chat: '{user_message[:50]}...'")
        
        response = requests.post(url, json=payload, headers=headers, timeout=60)
        response.raise_for_status()
        
        data = response.json()
        
        if 'choices' not in data or len(data['choices']) == 0:
            return {"type": "chat", "message": "I couldn't process that. Please try again."}
        
        raw_response = data['choices'][0]['message']['content'].strip()
        print(f"📝 AI Response: {raw_response[:200]}")
        
        # Try to detect if it's JSON (visual update)
        # Try to detect if it's JSON (visual update)
        try:
            # 1. Try direct parse
            parsed = json.loads(raw_response)
        except json.JSONDecodeError:
            # 2. Try regex extraction of JSON block
            json_match = re.search(r'(\{.*\})', raw_response.replace('\n', ' '), re.DOTALL)
            if json_match:
                try:
                    parsed = json.loads(json_match.group(1))
                except:
                    parsed = {}
            else:
                parsed = {}

        if parsed.get("action") == "update" and "changes" in parsed:
            return {
                "type": "update",
                "changes": parsed["changes"]
            }
        
        # Otherwise it's a chat explanation
        return {
            "type": "chat",
            "message": raw_response
        }
        
    except requests.exceptions.Timeout:
        return {"type": "chat", "message": "Request timed out. Please try again."}
    except Exception as e:
        print(f"❌ Visualiser chat error: {e}")
        return {"type": "chat", "message": "Sorry, I encountered an error. Please try again."}
