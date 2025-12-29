from fastapi import APIRouter, Depends, Request, Header, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any
from auth.auth_middleware import require_firebase_user
from config import OLLAMA_BASE_URL, LOCAL_MODEL, FALLBACK_GROQ_API_KEY
from pydantic import Field
import json
import re
import requests
from utils.file_utils import resolve_scan_path

router = APIRouter(
    prefix="/chat",
    tags=["Chat"],
    dependencies=[Depends(require_firebase_user)],
)

class ChatRequest(BaseModel):
    user_prompt: str
    topic: str
    variables: list
    image_path: Optional[str] = None
    current_params: Optional[Dict[str, Any]] = None
    template_id: Optional[str] = None
    # ocr_text? If needed later.


class ChatResponse(BaseModel):
    response: str = Field(description="Natural language response to the user")
    parameter_updates: Optional[Dict[str, Any]] = Field(
        description="Dictionary of parameter updates, if any", default=None
    )
    update_type: str = Field(
        description="Type of response: 'explanation', 'parameter_change', or 'both'"
    )


def clean_json_output(text: str):
    """Remove markdown code blocks from JSON output."""
    text = text.strip()
    text = re.sub(r"```json", "", text)
    text = re.sub(r"```", "", text)
    text = text.strip()
    try:
        return json.loads(text)
    except:
        return None


async def handle_unified_chat(
    user_prompt: str,
    topic: str,
    variables: list,
    api_key: str,
    image_path: Optional[str] = None,
    current_params: Optional[Dict[str, Any]] = None,
    template_id: Optional[str] = None,
) -> ChatResponse:
    
    # Construct Context
    context_parts = [
        f"Topic: {topic}",
        f"Variables involved: {', '.join(variables)}",
    ]
    if template_id:
        context_parts.append(f"Current simulation: {template_id}")
    if current_params:
        context_parts.append(f"Current parameters: {current_params}")
    
    context = "\n".join(context_parts)

    system_prompt = """
    You are an expert Physics Tutor and Simulation Controller.
    
    Context:
    {context}
    
    User's message: "{user_prompt}"
    
    Your tasks:
    1. If they want to change parameters, update them in "parameter_updates"
    2. If they ask a question, provide a clear answer in "response"
    3. Set "update_type" to: "explanation", "parameter_change", or "both"
    
    STRICT JSON Output:
    {
      "response": "Sure, here is the answer...",
      "parameter_updates": {"velocity": 10},
      "update_type": "both"
    }
    """
    
    full_prompt = system_prompt.replace("{context}", context).replace("{user_prompt}", user_prompt)
    
    payload = {
        "model": LOCAL_MODEL,
        "prompt": full_prompt,
        "stream": False,
        "format": "json"
    }
    
    try:
        r = requests.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload, timeout=120)
        r.raise_for_status()
        data = r.json()
        raw = data.get("response", "")
        
        parsed = clean_json_output(raw)
        if parsed:
            return ChatResponse(**parsed)
        else:
            return ChatResponse(
                response="I'm sorry, I couldn't process that.",
                update_type="explanation"
            )

    except Exception as e:
        print(f"❌ Chat Error: {e}")
        return ChatResponse(
            response="Error communicating with AI Assistant.",
            update_type="explanation"
        )


@router.post("/ask")
async def chat_ask(
    req: ChatRequest, 
    request: Request,
    x_groq_api_key: str = Header(None, alias="x-groq-api-key")
):
    # Ignore API key check
    user_id = request.state.user["uid"]
    print(f"💬 Chat request from {user_id}: {req.user_prompt}")
    
    response = await handle_unified_chat(
        user_prompt=req.user_prompt,
        topic=req.topic,
        variables=req.variables,
        api_key="local-dummy",
        image_path=req.image_path,
        current_params=req.current_params,
        template_id=req.template_id,
    )

    return response.dict()
