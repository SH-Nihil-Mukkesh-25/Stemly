from pydantic import BaseModel
from typing import List, Dict, Optional

# Request: For generating full notes
class NotesGenerateRequest(BaseModel):
    topic: str
    variables: List[str]
    image_path: Optional[str] = None   # Optional: in case we use image context later


# Request: For follow-up questions inside Notes tab
class NotesFollowUpRequest(BaseModel):
    topic: str
    previous_notes: Dict
    user_prompt: str


# Response: Full AI Notes structure
class NotesResponse(BaseModel):
    explanation: str
    variable_breakdown: Dict[str, str]
    formulas: List[str]
    example: str
    mistakes: List[str]
    practice_questions: List[str]
    summary: List[str]
    resources: List[str]
