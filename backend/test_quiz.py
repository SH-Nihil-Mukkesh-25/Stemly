import requests
import json

# Test OpenRouter API - Quiz Generation
OPENROUTER_API_KEY = "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"
url = "https://openrouter.ai/api/v1/chat/completions"

headers = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "http://localhost",
    "X-Title": "Stemly"
}

system_prompt = """
Generate a quiz for the topic: "Optics"

Requirements:
- Create EXACTLY 3 MCQs
- Mix theory and numerical questions
- Keep difficulty appropriate for high-school students
- Provide 4 clear options per question
- Return correct_index (0–3)
- Add a short explanation for each question

STRICT JSON OUTPUT ONLY. No markdown.

Output Schema:
{
  "topic": "Optics",
  "questions": [
    {
      "question": "What is...?",
      "options": ["A", "B", "C", "D"],
      "correct_index": 0,
      "explanation": "Because..."
    }
  ]
}
"""

payload = {
    "model": "meta-llama/llama-3.2-3b-instruct:free",
    "messages": [
        {"role": "system", "content": "You are a quiz generator."},
        {"role": "user", "content": system_prompt}
    ],
    "max_tokens": 1500,
    "temperature": 0.7
}

print("Testing OpenRouter Quiz Generation...")
response = requests.post(url, json=payload, headers=headers, timeout=120)
print(f"Status: {response.status_code}")
print(f"Raw Response: {response.text}")
