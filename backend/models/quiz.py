from pydantic import BaseModel
from typing import List, Optional


class QuizTopic(BaseModel):
    id: int
    name: str
    description: Optional[str] = None


class QuizQuestion(BaseModel):
    id: int
    topic_id: int
    question: str
    options: List[str]
    correct_index: int   # position of correct answer


class QuizAnswerRequest(BaseModel):
    question_id: int
    selected_index: int


class QuizSubmission(BaseModel):
    answers: List[QuizAnswerRequest]


class QuizResult(BaseModel):
    score: int
    total: int
    correct_questions: List[int]
