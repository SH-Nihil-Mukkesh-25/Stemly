from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.messages import HumanMessage
from typing import Optional
from config import llm, is_ai_enabled
from models.notes_models import NotesResponse
from utils.file_utils import resolve_scan_path
import google.generativeai as genai
import json
import re

parser = PydanticOutputParser(pydantic_object=NotesResponse)
FORMAT_INSTRUCTIONS = parser.get_format_instructions()

NOTES_GENERATE_PROMPT = PromptTemplate(
    input_variables=["topic", "variables"],
    partial_variables={"format_instructions": FORMAT_INSTRUCTIONS},
    template="""
You are an AI Study Assistant that generates study notes for a student based on a scanned problem image.

A separate vision model has already analyzed the IMAGE and extracted:
- topic (high-level concept): "{topic}"
- variables appearing in the image (symbols / labels): {variables}

Your job:
1. Infer the most likely subject and sub‑topic from this information (Physics, Chemistry, Biology, Math, CS, Economics, etc.).
2. Base your reasoning on what such an image would typically contain (diagrams, labels, graphs, equations, circuit symbols, biological structures, chemical apparatus, geometrical shapes, flowcharts, paragraph notes).
3. Avoid assumptions that are clearly unrelated to the topic/variables.

Very important behaviour (domain bias):
- This application is for SCHOOL / UNIVERSITY STEM subjects (physics, math, chemistry, biology, engineering, economics, etc.), NOT for teaching programming APIs or language-specific string functions.
- Do NOT default to programming / string manipulation / generic “string” explanations unless the topic or variables EXPLICITLY indicate Computer Science or programming (e.g., words like "Python", "Java", "C++", "code", "algorithm", "string data type", "array", etc.).
- If the topic is a vague word like "string" or a single generic identifier, interpret it as a **STEM concept** first (e.g., a physical string in waves/vibrations, or a labelled quantity in a formula), NOT as a programming string data type.
- If the topic and variables clearly refer to physics → talk physics.
- If biology → talk biology.
- If chemistry → talk chemistry.
- If economics → talk economics.
- If it looks like generic notes / text → extract main ideas and summarise them as study notes.
- If unsure, choose the MOST LIKELY subject based on the topic and variables.

You must produce structured study notes as JSON only, following this schema:
{format_instructions}

Guidelines for the content fields:
- explanation: clear, student‑friendly explanation of the concept.
- variable_breakdown: explain each symbol / variable and what it represents physically or conceptually.
- formulas: include only relevant formulas and briefly explain each one.
- example: one concrete, worked example that matches the topic and variables.
- mistakes: common conceptual or calculation errors students make in this STEM context.
- practice_questions: 3–5 exam‑style questions that match the same concept level (NO programming exercises unless the topic explicitly mentions code/CS).
- summary: short bullet‑style recap of the key ideas.
- resources: links or pointers to high‑quality **STEM learning resources** (e.g., Khan Academy, HyperPhysics, university lecture notes, standard educational references). Do NOT link to general programming docs like W3Schools string documentation or Java/Python API docs unless the topic explicitly says it is about programming.

STRICT OUTPUT RULES:
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
You are an AI Study Assistant continuing a study session about a scanned problem image.

Context:
- High‑level topic (from the image): {topic}
- Existing structured notes (generated from the image): {previous_notes}

The student now asks a follow‑up question:
"{user_prompt}"

STRICT RULES:
- Output ONLY valid JSON.
- No markdown.
- Follow this JSON structure:
{format_instructions}
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


async def generate_notes(topic: str, variables: list, image_path: Optional[str] = None):
    if not is_ai_enabled():
        raise RuntimeError("Gemini AI is not configured.")

    # If we have access to the scanned image, let Gemini see it directly.
    if image_path:
        try:
            local_path = resolve_scan_path(image_path)
        except ValueError as exc:
            print(f"⚠ Invalid scan path provided for notes: {exc}")
        else:
            # Detect MIME type from extension.
            ext = local_path.suffix.lower()
            if ext in (".jpg", ".jpeg"):
                mime_type = "image/jpeg"
            else:
                mime_type = "image/png"

            with open(local_path, "rb") as img:
                img_bytes = img.read()

            system_prompt = NOTES_GENERATE_PROMPT.format(
                topic=topic,
                variables=variables,
            )

            model = genai.GenerativeModel("gemini-2.0-flash")
            response = model.generate_content(
                [
                    system_prompt,
                    {
                        "mime_type": mime_type,
                        "data": img_bytes,
                    },
                ]
            )

            raw_text = response.text
            data = clean_json_output(raw_text)
            if data is None:
                raise ValueError("Invalid JSON from Gemini Notes (image-based)")

            return NotesResponse(**data)

    # Fallback: text-only notes generation via LangChain using topic + variables.
    prompt = NOTES_GENERATE_PROMPT.format(
        topic=topic,
        variables=variables,
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
