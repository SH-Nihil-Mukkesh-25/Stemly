from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional
from services.visualiser_loader import get_template_by_topic, fill_template_defaults
from database.visualiser_model import save_visualiser_entry, get_visualiser_entries

router = APIRouter(
    prefix="/visualiser",
    tags=["Visualiser Engine"]
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
async def generate_visualiser(req: VisualiserGenerateRequest):
    template = await get_template_by_topic(req.topic)

    if not template:
        raise HTTPException(status_code=404, detail="No template found for this topic.")

    filled = fill_template_defaults(template, req.variables)

    # Save initial state if user_id provided (optional)
    if req.user_id:
        await save_visualiser_entry(
            user_id=req.user_id,
            template_id=filled["template_id"],
            parameters=filled["parameters"],
        )

    return {
        "template_id": filled["template_id"],
        "template": filled
    }


@router.post("/update")
async def update_visualiser(req: VisualiserUpdateRequest):
    updated = {}

    if req.user_prompt and req.user_prompt.strip():
        try:
            from services.ai_visualiser import adjust_parameters_with_ai
            ai_result = await adjust_parameters_with_ai(
                req.template_id,
                req.parameters,
                req.user_prompt
            )
            updated = ai_result.get("updated_parameters", {})
            ai_response = ai_result.get("ai_response", "Updated parameters.")
            print(f"🤖 AI Updates: {updated}")
        except Exception as e:
            print(f"⚠ AI Update Error: {e}")
            updated = {}
            ai_response = "Sorry, I encountered an error processing your request."

    merged = dict(req.parameters)
    merged.update(updated)

    if req.user_id:
        await save_visualiser_entry(
            user_id=req.user_id,
            template_id=req.template_id,
            parameters=merged
        )

    return {
        "template_id": req.template_id,
        "parameters": merged,
        "ai_updates": updated,
        "ai_response": ai_response
    }


@router.get("/history/{user_id}")
async def visualiser_history(user_id: str):
    history = await get_visualiser_entries(user_id)
    return {"history": history}