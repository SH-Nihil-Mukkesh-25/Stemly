import os
import json
from typing import Dict, Any
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.prompts import PromptTemplate
from langchain.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field
from config import GEMINI_API_KEY

class ParameterUpdate(BaseModel):
    updated_parameters: Dict[str, Any] = Field(description="Dictionary of updated parameter values. Empty if no changes needed.")
    ai_response: str = Field(description="Response to the user. If parameters changed, explain what happened. If the user asked a question, answer it.")

async def adjust_parameters_with_ai(template_id: str, current_params: Dict[str, Any], user_prompt: str) -> Dict[str, Any]:
    """
    Uses Gemini to interpret user prompt and update visualiser parameters.
    """
    try:
        if not GEMINI_API_KEY:
            print("⚠ GEMINI_API_KEY not set")
            return {"updated_parameters": {}, "ai_response": "AI is not configured."}

        llm = ChatGoogleGenerativeAI(
            model="gemini-1.5-flash", 
            temperature=0.3, 
            google_api_key=GEMINI_API_KEY
        )
        
        parser = PydanticOutputParser(pydantic_object=ParameterUpdate)
        
        prompt = PromptTemplate(
            template="""
            You are an expert Physics Tutor and Simulation Controller.
            
            Current Simulation: {template_id}
            Current Parameters: {current_params}
            
            User Request: "{user_prompt}"
            
            Your tasks:
            1. Analyze the user's request.
            2. If they ask to change the simulation (e.g., "make it faster", "set angle to 45"), determine the necessary parameter updates.
               - Only change relevant parameters.
               - Ensure values are physically reasonable.
            3. If they ask a question (e.g., "why does it curve?", "what is velocity?"), answer it clearly and concisely.
            4. If they do both, do both.
            
            Return a JSON with:
            - "updated_parameters": A dictionary of changed parameters (or empty if none).
            - "ai_response": A natural language response to the user.
            
            {format_instructions}
            """,
            input_variables=["template_id", "current_params", "user_prompt"],
            partial_variables={"format_instructions": parser.get_format_instructions()}
        )
        
        chain = prompt | llm | parser
        
        result = await chain.ainvoke({
            "template_id": template_id,
            "current_params": current_params,
            "user_prompt": user_prompt
        })
        
        return {
            "updated_parameters": result.updated_parameters,
            "ai_response": result.ai_response
        }
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"AI Parameter Adjustment Error: {e}")
        return {
            "updated_parameters": {},
            "ai_response": "I'm having trouble connecting to my brain right now. Please try again."
        }