from fastapi import APIRouter, Query, Depends, Header, HTTPException
from services.quiz_service import QuizService
from services.ai_quiz import generate_quiz_with_ai
from auth.auth_middleware import require_firebase_user

router = APIRouter(
    prefix="/quiz",
    tags=["Quiz"],
    dependencies=[Depends(require_firebase_user)]
)

service = QuizService()


@router.get("/questions/{topic_id}")
async def get_static_questions(topic_id: int, count: int = Query(10)):
    return service.get_questions(topic_id, limit=count)


@router.get("/generate")
async def ai_generate_quiz(
    topic: str, 
    count: int = 5,
    x_ai_api_key: str = Header(None, alias="X-AI-API-Key"),
    x_groq_api_key: str = Header(None, alias="x-groq-api-key")
):
    """
    Generates fresh questions using AI.
    """
    # Use X-AI-API-Key first (from Flutter), then legacy header
    api_key_to_use = x_ai_api_key or x_groq_api_key

    try:
        ai_quiz = await generate_quiz_with_ai(topic, count, api_key=api_key_to_use)
        return ai_quiz
    except Exception as e:
        print(f"❌ Error generating quiz: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate quiz")


@router.post("/submit")
def submit_static_quiz(payload):
    return service.evaluate(payload)

