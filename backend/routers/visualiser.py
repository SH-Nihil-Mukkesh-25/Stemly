from fastapi import APIRouter, Depends, Request, Header
from pydantic import BaseModel
from typing import List, Optional

from auth.auth_middleware import require_firebase_user
from database.visualiser_model import (
    get_visualiser_entries,
    save_visualiser_entry,
)
from models.visualiser_models import VisualiserSaveRequest
from services.ai_visualiser import generate_visualiser_image
from services.ai_chat import process_visualiser_chat

# -----------------------------------------------------
# ROUTER CONFIG
# -----------------------------------------------------

router = APIRouter(
    prefix="/visualiser",
    tags=["Visualiser"],
    dependencies=[Depends(require_firebase_user)],
)

# -----------------------------------------------------
# DATA MODELS
# -----------------------------------------------------

class ImageGenRequest(BaseModel):
    prompt: str

class VisualiserGenerateRequest(BaseModel):
    topic: str
    variables: list

class ChatMessage(BaseModel):
    text: str
    isUser: bool

class VisualiserChatRequest(BaseModel):
    message: str
    topic: str
    parameters: dict
    history: Optional[List[ChatMessage]] = None

# -----------------------------------------------------
# STATE MANAGEMENT ENDPOINTS
# -----------------------------------------------------

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
# MAIN VISUALISER GENERATION LOGIC
# -----------------------------------------------------

@router.post("/generate")
def generate_interactive_template(payload: VisualiserGenerateRequest):
    """
    Determines if an interactive template exists for the topic.
    Returns template data or 404.
    Supporting Physics, Chemistry, and Math.
    """
    topic_raw = payload.topic
    topic = payload.topic.strip().lower()
    variables = [str(v).lower() for v in payload.variables]
    
    print(f"DEBUG VISUALISER: Raw='{topic_raw}', Cleaned='{topic}', Vars={variables}")

    # =================================================
    # 1. CHEMISTRY: MOLECULES (Generic Diagram)
    # =================================================
    if "water" in topic or "h2o" in topic:
        return _molecule_template("Water (H2O)", [
             {"type": "circle", "x": 50, "y": 50, "r": 15, "text": "O", "color": "red"},
             {"type": "circle", "x": 30, "y": 70, "r": 10, "text": "H", "color": "white"},
             {"type": "circle", "x": 70, "y": 70, "r": 10, "text": "H", "color": "white"},
             {"type": "line", "x1": 50, "y1": 50, "x2": 30, "y2": 70},
             {"type": "line", "x1": 50, "y1": 50, "x2": 70, "y2": 70},
        ])
    
    if "methane" in topic or "ch4" in topic:
        return _molecule_template("Methane (CH4)", [
             {"type": "circle", "x": 50, "y": 50, "r": 12, "text": "C", "color": "black"},
             {"type": "circle", "x": 50, "y": 20, "r": 8, "text": "H", "color": "white"},
             {"type": "circle", "x": 80, "y": 80, "r": 8, "text": "H", "color": "white"},
             {"type": "circle", "x": 20, "y": 80, "r": 8, "text": "H", "color": "white"},
             {"type": "circle", "x": 35, "y": 40, "r": 8, "text": "H", "color": "white"}, # 3D effect hint
             {"type": "line", "x1": 50, "y1": 50, "x2": 50, "y2": 20},
             {"type": "line", "x1": 50, "y1": 50, "x2": 80, "y2": 80},
             {"type": "line", "x1": 50, "y1": 50, "x2": 20, "y2": 80},
             {"type": "line", "x1": 50, "y1": 50, "x2": 35, "y2": 40},
        ])

    if "ammonia" in topic or "nh3" in topic:
         return _molecule_template("Ammonia (NH3)", [
             {"type": "circle", "x": 50, "y": 40, "r": 14, "text": "N", "color": "blue"},
             {"type": "circle", "x": 30, "y": 70, "r": 9, "text": "H", "color": "white"},
             {"type": "circle", "x": 70, "y": 70, "r": 9, "text": "H", "color": "white"},
             {"type": "circle", "x": 50, "y": 80, "r": 9, "text": "H", "color": "white"},
             {"type": "line", "x1": 50, "y1": 40, "x2": 30, "y2": 70},
             {"type": "line", "x1": 50, "y1": 40, "x2": 70, "y2": 70},
             {"type": "line", "x1": 50, "y1": 40, "x2": 50, "y2": 80},
        ])

    if "carbon dioxide" in topic or "co2" in topic:
         return _molecule_template("Carbon Dioxide (CO2)", [
             {"type": "circle", "x": 50, "y": 50, "r": 12, "text": "C", "color": "black"},
             {"type": "circle", "x": 20, "y": 50, "r": 14, "text": "O", "color": "red"},
             {"type": "circle", "x": 80, "y": 50, "r": 14, "text": "O", "color": "red"},
             {"type": "line", "x1": 20, "y1": 50, "x2": 80, "y2": 50}, # Double bond simplified
        ])

    # =================================================
    # 2. CHEMISTRY: ATOM STRUCTURE (Specific Widget)
    # =================================================
    if "atom" in topic or "electron" in topic or "proton" in topic:
        return _simple_template("chemistry_atom", {
            "protons": {"value": 6.0, "min": 1, "max": 18},
            "neutrons": {"value": 6.0, "min": 0, "max": 24},
        })

    # =================================================
    # 3. CHEMISTRY: GAS LAWS / KINETICS (Equation)
    # =================================================
    if "boyle" in topic or ("pressure" in topic and "volume" in topic):
        return _equation_template("Boyle's Law (P = k/V)", "10/x", min_x=0.5, max_x=10, min_y=0, max_y=20)
    
    if "charles" in topic or ("volume" in topic and "temperature" in topic):
        return _equation_template("Charles's Law (V = kT)", "0.5*x", min_x=0, max_x=100, min_y=0, max_y=50)

    if "rate" in topic or "kinetics" in topic:
         return _equation_template("Reaction Rate ([A] = [A]0 * e^-kt)", "10 * 2.718^(-0.5*x)", min_x=0, max_x=10, min_y=0, max_y=10)

    # =================================================
    # 4. PHYSICS: WAVES (Equation)
    # =================================================
    if "wave" in topic or "sine" in topic or "frequency" in topic:
         return _equation_template("Sine Wave (y = sin(x))", "sin(x)", min_x=0, max_x=20, min_y=-1.5, max_y=1.5)

    # =================================================
    # 5. PHYSICS: CIRCUITS (Generic Diagram)
    # =================================================
    if "circuit" in topic or "resistor" in topic:
         # Simple Series Circuit
         if "series" in topic or "circuit" in topic:
             return _diagram_template("Series Circuit", [
                 {"type": "rect", "x": 20, "y": 20, "w": 60, "h": 60, "text": ""}, # Wire Loop
                 {"type": "rect", "x": 45, "y": 15, "w": 10, "h": 10, "text": "R1", "color": "orange"}, # Resistor top
                 {"type": "rect", "x": 45, "y": 75, "w": 10, "h": 10, "text": "Bat", "color": "green"},  # Battery bottom
             ])
    
    # =================================================
    # 6. PHYSICS: MECHANICS (Specific & Generic)
    # =================================================
    # Projectile
    # 5. PHYSICS: PROJECTILE MOTION
    # Check for specific "Projectile" OR "Kinematics with Angles"
    if "projectile" in topic or \
       ("kinematics" in topic and "theta" in variables) or \
       ("theta" in variables and ("range" in variables or "velocity" in variables)):
        return _simple_template("projectile_motion", {
            "U": {"value": 50.0, "min": 0, "max": 100},
            "theta": {"value": 45.0, "min": 0, "max": 90},
            "g": {"value": 9.8, "min": 1, "max": 20},
        })

    # Free Fall
    if "free fall" in topic or ("gravity" in topic and "height" in variables):
         return _simple_template("free_fall", {
             "h": {"value": 100.0, "min": 0, "max": 500},
             "g": {"value": 9.8, "min": 1, "max": 20},
         })
         
    # SHM
    if "harmonic" in topic or "pendulum" in topic or "spring" in topic:
        return _simple_template("simple_harmonic_motion", {
            "A": {"value": 5.0, "min": 1, "max": 20},
            "m": {"value": 1.0, "min": 0.1, "max": 10},
            "k": {"value": 10.0, "min": 1, "max": 50},
        })

    # Kinematics
    if "kinematic" in topic or "motion" in topic or "acceleration" in topic:
         return _simple_template("kinematics_1d", {
             "u": {"value": 0.0, "min": -50, "max": 50},
             "a": {"value": 2.0, "min": -20, "max": 20},
             "t_max": {"value": 10.0, "min": 1, "max": 30},
         })

    # =================================================
    # 7. PHYSICS: OPTICS (Specific)
    # =================================================
    if "optic" in topic or "lens" in topic or "mirror" in topic:
         return _simple_template("optics_lens", {
             "f": {"value": 10.0, "min": -50, "max": 50},
             "u": {"value": -20.0, "min": -100, "max": 0},
             "h_o": {"value": 5.0, "min": 1, "max": 20},
         })

    # =================================================
    # 8. MATH: GRAPHS (Specific & Generic)
    # =================================================
    if "quadratic" in topic or "parabola" in topic:
        return _simple_template("math_quadratic", {
            "a": {"value": 1.0, "min": -5, "max": 5},
            "b": {"value": 0.0, "min": -10, "max": 10},
            "c": {"value": 0.0, "min": -10, "max": 10},
        })
        
    if "graph" in topic or "plot" in topic or "function" in topic:
         return _equation_template("Graph Plotter", "x^2")

    # =================================================
    # 9. FALLBACK
    # =================================================
    print("DEBUG VISUALISER: No match found. Returning fallback.")
    return {
        "template": {
            "templateId": "general_topic",
            "title": "General Topic",
            "description": "Interactive learning for Stemly",
            "parameters": {},
            "message": "No interactive visualization available for this topic. Use the AI Chat below!"
        }
    }

# -----------------------------------------------------
# HELPERS
# -----------------------------------------------------

def _simple_template(t_id, params):
    return {
        "template": {
            "templateId": t_id, 
            "title": t_id.replace("_", " ").title(),
            "description": "Interactive simulation.",
            "parameters": params
        }
    }

def _equation_template(title, eq, min_x=-10, max_x=10, min_y=-10, max_y=10):
    return {
        "template": {
            "templateId": "equation_plotter", # Maps to EquationPlotterWidget
            "metadata": {"equation": eq, "title": title},
            "parameters": {
                "min_x": {"value": float(min_x), "min": -100, "max": 0},
                "max_x": {"value": float(max_x), "min": 0, "max": 100},
                "min_y": {"value": float(min_y), "min": -100, "max": 0},
                "max_y": {"value": float(max_y), "min": 0, "max": 100},
            }
        }
    }

def _diagram_template(title, primitives):
    return {
        "template": {
            "templateId": "generic_diagram", # Maps to GenericDiagramWidget
            "metadata": {"primitives": primitives, "title": title},
            "parameters": {} # No sliders for static diagrams (yet)
        }
    }

def _molecule_template(title, primitives):
    """Helper alias for chemistry molecule diagram templates."""
    return _diagram_template(title, primitives)

@router.post("/chat")
async def visualiser_chat(payload: VisualiserChatRequest, request: Request, x_ai_api_key: str = Header(None, alias="X-AI-API-Key")):
    """
    AI Chat for the visualiser.
    Supports both visualization parameter changes and concept explanations.
    """
    history = [{"text": m.text, "isUser": m.isUser} for m in payload.history] if payload.history else []
    
    if x_ai_api_key:
        print(f"💬 Chat using AI key: {x_ai_api_key[:8]}...")
    
    result = await process_visualiser_chat(
        user_message=payload.message,
        topic=payload.topic,
        parameters=payload.parameters,
        chat_history=history,
        api_key=x_ai_api_key
    )
    
    return result
