from fastapi import APIRouter, HTTPException, Depends, Request, Header
from openai import AuthenticationError
from pydantic import BaseModel
from typing import Dict, Any, Optional
from services.visualiser_loader import get_template_by_topic, fill_template_defaults
from database.visualiser_model import save_visualiser_entry, get_visualiser_entries
from auth.auth_middleware import require_firebase_user

router = APIRouter(
    prefix="/visualiser",
    tags=["Visualiser Engine"],
    dependencies=[Depends(require_firebase_user)],
)


class VisualiserGenerateRequest(BaseModel):
    topic: str
    variables: Optional[list] = None
    user_id: Optional[str] = None


class VisualiserUpdateRequest(BaseModel):
    template_id: str
    parameters: Dict[str, Any]
    user_prompt: Optional[str] = None
    user_id: Optional[str] = None


@router.post("/generate")
async def generate_visualiser(req: VisualiserGenerateRequest, request: Request):
    template = await get_template_by_topic(req.topic)

    if not template:
        raise HTTPException(status_code=404, detail="No template found for this topic.")

    filled = fill_template_defaults(template, req.variables)

    # Save initial state using authenticated user_id
    user_id = request.state.user["uid"]
    await save_visualiser_entry(
        user_id=user_id,
        template_id=filled["template_id"],
        parameters=filled["parameters"],
    )

    return {
        "template_id": filled["template_id"],
        "template": filled
    }


from config import FALLBACK_GROQ_API_KEY

@router.post("/update")
async def update_visualiser(
    req: VisualiserUpdateRequest, 
    request: Request,
    x_groq_api_key: str = Header(None, alias="x-groq-api-key")
):
    # Default values in case AI is not invoked
    updated: Dict[str, Any] = {}
    ai_response: str = "No AI changes were applied."

    if req.user_prompt and req.user_prompt.strip():
        # Use header key or fallback from env
        api_key_to_use = x_groq_api_key or FALLBACK_GROQ_API_KEY
        
        if not api_key_to_use:
             # Just warn or fail? Fail is better if user expects AI.
             print("⚠ Missing API Key for visual update")
             ai_response = "Please configure Groq API Key in Settings to use AI features."
        else:
            try:
                from services.ai_visualiser import adjust_parameters_with_ai

                ai_result = await adjust_parameters_with_ai(
                    req.template_id,
                    req.parameters,
                    req.user_prompt,
                    api_key=api_key_to_use
                )
                updated = ai_result.get("updated_parameters", {})
                ai_response = ai_result.get("ai_response", "Updated parameters.")
                print(f"🤖 AI Updates: {updated}")
            except AuthenticationError:
                print("❌ Invalid Groq API Key")
                updated = {}
                ai_response = "Error: Invalid Groq API Key. Please check your settings."
            except Exception as e:
                print(f"⚠ AI Update Error: {e}")
                updated = {}
                ai_response = (
                    "Sorry, I encountered an error processing your request. "
                    "The previous parameters are kept unchanged."
                )

    merged = dict(req.parameters)
    merged.update(updated)

    # Save using authenticated user_id
    user_id = request.state.user["uid"]
    await save_visualiser_entry(
        user_id=user_id,
        template_id=req.template_id,
        parameters=merged,
    )

    return {
        "template_id": req.template_id,
        "parameters": merged,
        "ai_updates": updated,
        "ai_response": ai_response,
    }


@router.get("/history")
async def visualiser_history(request: Request):
    user_id = request.state.user["uid"]
    history = await get_visualiser_entries(user_id)
    return {"history": history}
