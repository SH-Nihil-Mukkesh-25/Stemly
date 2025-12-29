from fastapi import APIRouter, Depends, Request

from auth.auth_middleware import require_firebase_user
from database.visualiser_model import (
    get_visualiser_entries,
    save_visualiser_entry,
)
from models.visualiser_models import VisualiserSaveRequest

router = APIRouter(
    prefix="/visualiser",
    tags=["Visualiser"],
    dependencies=[Depends(require_firebase_user)],
)


@router.post("/states")
async def save_visualiser_state(payload: VisualiserSaveRequest, request: Request):
    user_id = request.state.user["uid"]
    entry_id = await save_visualiser_entry(
        user_id=user_id,
        template_id=payload.template_id,
        parameters=payload.parameters,
    )
    return {"id": entry_id}


@router.get("/states")
async def list_visualiser_states(request: Request, limit: int = 20):
    user_id = request.state.user["uid"]
    entries = await get_visualiser_entries(user_id, limit=limit)
    return {"items": entries}


from pydantic import BaseModel
from services.ai_visualiser import generate_visualiser_image

class ImageGenRequest(BaseModel):
    prompt: str

@router.post("/generate-image")
def create_visualisation_image(payload: ImageGenRequest, request: Request):
    """
    Generates an educational diagram using AIML API.
    """
    image_url = generate_visualiser_image(payload.prompt)
    if not image_url:
        return {"error": "Failed to generate image"}
    return {"image_url": image_url}


# -----------------------------------------------------
# MISSING ENDPOINT: Generate Interactive Template Logic
# -----------------------------------------------------

class VisualiserGenerateRequest(BaseModel):
    topic: str
    variables: list

@router.post("/generate")
def generate_interactive_template(payload: VisualiserGenerateRequest):
    """
    Determines if an interactive template exists for the topic.
    Returns template data or 404.
    """
    topic = payload.topic.lower()
    variables = [str(v).lower() for v in payload.variables]
    print(f"DEBUG /visualiser/generate: Received topic='{topic}', vars={variables}")

    # Heuristic: Detect Projectile Motion via variables if topic is generic
    is_optics = "optic" in topic or "lens" in topic or "mirror" in topic
    
    if not is_optics:
        # 1. Strong Projectile Indicators
        if any(k in variables for k in ["theta", "angle", "projectile", "trajectory", "range"]):
            topic = "projectile motion"
        
        # 2. Gravity Presence (Distinguish from generic 1D horizontal motion)
        elif "g" in variables or "gravity" in variables:
             if "kinematic" in topic or "motion" in topic:
                 # Prefer projectile for T (Time of Flight) and H (Max Height)
                 if "h" in variables or "t" in variables:
                     topic = "projectile motion"
                 else:
                     topic = "free fall"

    # 1. Projectile Motion
    if "projectile" in topic:
        return {
            "template": {
                "templateId": "projectile_motion",
                "parameters": {
                    "U": {"value": 50.0, "min": 0, "max": 100},
                    "theta": {"value": 45.0, "min": 0, "max": 90},
                    "g": {"value": 9.8, "min": 1, "max": 20},
                }
            }
        }

    # 2. Kinematics (1D)
    if "kinematic" in topic or "motion" in topic:
         return {
            "template": {
                "templateId": "kinematics_1d",
                "parameters": {
                    "u": {"value": 0.0, "min": -50, "max": 50},
                    "a": {"value": 2.0, "min": -20, "max": 20},
                    "t_max": {"value": 10.0, "min": 1, "max": 30},
                }
            }
        }
        
    # 3. Free Fall
    if "fall" in topic or "gravity" in topic:
         return {
            "template": {
                "templateId": "free_fall",
                "parameters": {
                    "h": {"value": 100.0, "min": 0, "max": 500},
                    "g": {"value": 9.8, "min": 1, "max": 20},
                }
            }
        }

    # 4. SHM (Pendulum/Spring)
    if "harmonic" in topic or "oscillation" in topic or "pendulum" in topic:
         return {
            "template": {
                "templateId": "simple_harmonic_motion",
                "parameters": {
                    "A": {"value": 5.0, "min": 1, "max": 20},
                    "m": {"value": 1.0, "min": 0.1, "max": 10},
                    "k": {"value": 10.0, "min": 1, "max": 50},
                }
            }
        }
        
    # 5. Optics (Lens)
    if "optic" in topic or "lens" in topic or "mirror" in topic:
         return {
            "template": {
                "templateId": "optics_lens",
                "parameters": {
                    "f": {"value": 10.0, "min": -50, "max": 50},
                    "u": {"value": -20.0, "min": -100, "max": 0},
                    "h_o": {"value": 5.0, "min": 1, "max": 20},
                }
            }
        }

    # 6. Chemistry - Atom Structure
    if "atom" in topic or "electron" in topic or "proton" in topic or "chemistry" in topic:
        return {
            "template": {
                "templateId": "chemistry_atom",
                "parameters": {
                    "protons": {"value": 6.0, "min": 1, "max": 18}, # Carbon default
                    "neutrons": {"value": 6.0, "min": 0, "max": 24},
                }
            }
        }

    # 7. Math - Quadratic Graph
    if "math" in topic or "quadratic" in topic or "parabola" in topic or "algebra" in topic or "graph" in topic:
         return {
            "template": {
                "templateId": "math_quadratic",
                "parameters": {
                    "a": {"value": 1.0, "min": -5, "max": 5},
                    "b": {"value": 0.0, "min": -10, "max": 10},
                    "c": {"value": 0.0, "min": -10, "max": 10},
                }
            }
        }

    # 8. Fallback for Unknown or Unmatched topics - return a general science template
    # This prevents 404 errors and allows the chat to still work
    return {
        "template": {
            "templateId": "general_topic",
            "parameters": {}, # No sliders for general chat
            "message": "No interactive visualization available for this topic. Use the AI Chat below to ask questions!"
        }
    }


# -----------------------------------------------------
# AI CHAT ENDPOINT FOR VISUALISER
# -----------------------------------------------------

from services.ai_chat import process_visualiser_chat
from typing import List, Optional

class ChatMessage(BaseModel):
    text: str
    isUser: bool

class VisualiserChatRequest(BaseModel):
    message: str
    topic: str
    parameters: dict
    history: Optional[List[ChatMessage]] = None

@router.post("/chat")
async def visualiser_chat(payload: VisualiserChatRequest, request: Request):
    """
    AI Chat for the visualiser.
    Returns either visualization updates (JSON) or explanations (text).
    """
    history = [{"text": m.text, "isUser": m.isUser} for m in payload.history] if payload.history else []
    
    result = await process_visualiser_chat(
        user_message=payload.message,
        topic=payload.topic,
        parameters=payload.parameters,
        chat_history=history
    )
    
    return result

