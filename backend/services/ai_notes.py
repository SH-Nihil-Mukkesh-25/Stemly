from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.messages import HumanMessage
from config import llm, is_ai_enabled
from models.notes_models import NotesResponse
import json
import re

parser = PydanticOutputParser(pydantic_object=NotesResponse)
FORMAT_INSTRUCTIONS = parser.get_format_instructions()

NOTES_GENERATE_PROMPT = PromptTemplate(
    input_variables=["topic", "variables"],
    partial_variables={"format_instructions": FORMAT_INSTRUCTIONS},
    template="""
You are an expert STEM tutor.

A student has scanned an image about the topic: "{topic}"
The important variables in the image are: {variables}

Generate detailed study notes for the student.

STRICT RULES:
- Output ONLY valid JSON.
- No backticks.
- No markdown.
- Follow this exact structure:
{format_instructions}

Now generate the JSON:
"""
)


NOTES_FOLLOWUP_PROMPT = PromptTemplate(
    input_variables=["topic", "previous_notes", "user_prompt"],
    partial_variables={"format_instructions": FORMAT_INSTRUCTIONS},
    template="""
You are a STEM tutor continuing a study session.

The topic is: {topic}
These are the previous notes the student has: {previous_notes}

The student asks: "{user_prompt}"

STRICT RULES:
- Output ONLY valid JSON.
- No markdown.
- Follow this JSON structure:
{format_instructions}

Now generate the JSON response:
"""
)


def clean_json_output(text: str):
    text = text.strip()
    text = re.sub(r"```json", "", text)
    text = re.sub(r"```", "", text)
    text = text.strip()
    try:
        return json.loads(text)
    except:
        return None


async def generate_notes(topic: str, variables: list):
    if not is_ai_enabled():
        raise RuntimeError("Gemini AI is not configured.")

    prompt = NOTES_GENERATE_PROMPT.format(
        topic=topic,
        variables=variables
    )

    response = llm.invoke([HumanMessage(content=prompt)])
    raw_text = response.content
    data = clean_json_output(raw_text)
    return NotesResponse(**data)


async def follow_up_notes(topic: str, previous_notes: dict, user_prompt: str):
    if not is_ai_enabled():
        raise RuntimeError("Gemini AI is not configured.")

    prompt = NOTES_FOLLOWUP_PROMPT.format(
        topic=topic,
        previous_notes=previous_notes,
        user_prompt=user_prompt
    )

    response = llm.invoke([HumanMessage(content=prompt)])
    raw_text = response.content

    data = clean_json_output(raw_text)
    return NotesResponse(**data)
