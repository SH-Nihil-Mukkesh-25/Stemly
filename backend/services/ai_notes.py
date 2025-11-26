# backend/services/ai_notes.py

from langchain.prompts import PromptTemplate
from langchain.output_parsers import PydanticOutputParser
from langchain.schema import HumanMessage
from config import llm, is_ai_enabled
from models.notes_models import NotesResponse
import json
import re


# ------------------------------
# 1. Output Parser
# ------------------------------
parser = PydanticOutputParser(pydantic_object=NotesResponse)

# Format instructions for Gemini (JSON schema)
FORMAT_INSTRUCTIONS = parser.get_format_instructions()



# ------------------------------
# 2. Prompt Template for FULL NOTES GENERATION
# ------------------------------

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
- Do not include explanations outside the JSON.
- Follow this exact structure:
{format_instructions}

## Content Requirements:
1. Explanation → Concept explanation in simple words  
2. Variable Breakdown → Meaning of each variable  
3. Formulas → Relevant formulas with brief meaning
4. Example → One solved example  
5. Mistakes → Common mistakes students make  
6. Practice Questions → 3–5 questions  
7. Summary → Key points  
8. Resources → Links to best online resources  

Now generate the JSON:
"""
)



# ------------------------------
# 3. Prompt Template for FOLLOW-UP QUESTIONS
# ------------------------------

NOTES_FOLLOWUP_PROMPT = PromptTemplate(
    input_variables=["topic", "previous_notes", "user_prompt"],
    partial_variables={"format_instructions": FORMAT_INSTRUCTIONS},
    template="""
You are a STEM tutor continuing a study session.

The topic is: {topic}
These are the previous notes the student has: {previous_notes}

The student asks: "{user_prompt}"

Update the notes or generate a new notes section that answers their question.

STRICT RULES:
- Output ONLY valid JSON.
- No markdown or ``` blocks.
- Follow this JSON structure:
{format_instructions}

Now generate the JSON response:
"""
)



# ------------------------------
# 4. CLEAN JSON HELPER
# ------------------------------

def clean_json_output(text: str):
    """Remove backticks, markdown, and parse clean JSON."""
    text = text.strip()
    text = re.sub(r"```json", "", text)
    text = re.sub(r"```", "", text)
    text = text.strip()
    try:
        return json.loads(text)
    except Exception as e:
        print("⚠ JSON PARSE ERROR in ai_notes:", e)
        print("RAW OUTPUT:", text)
        return None




# ------------------------------
# 5. MAIN FUNCTION → GENERATE NOTES
# ------------------------------

async def generate_notes(topic: str, variables: list):
    """Generate full structured study notes."""

    if not is_ai_enabled():
        raise RuntimeError("Gemini AI is not configured. Set GEMINI_API_KEY to enable notes generation.")

    prompt = NOTES_GENERATE_PROMPT.format(
        topic=topic,
        variables=variables
    )

    response = llm([HumanMessage(content=prompt)])
    raw_text = response.content

    data = clean_json_output(raw_text)
    if data is None:
        raise ValueError("Invalid JSON from Gemini Notes")

    return NotesResponse(**data)



# ------------------------------
# 6. FOLLOW-UP FUNCTION → ADD MORE NOTES
# ------------------------------

async def follow_up_notes(topic: str, previous_notes: dict, user_prompt: str):
    """Handle user follow-up questions inside Notes tab."""

    if not is_ai_enabled():
        raise RuntimeError("Gemini AI is not configured. Set GEMINI_API_KEY to enable notes follow-up.")

    prompt = NOTES_FOLLOWUP_PROMPT.format(
        topic=topic,
        previous_notes=previous_notes,
        user_prompt=user_prompt
    )

    response = llm([HumanMessage(content=prompt)])
    raw_text = response.content

    data = clean_json_output(raw_text)
    if data is None:
        raise ValueError("Invalid JSON from Gemini Follow-up")

    return NotesResponse(**data)
