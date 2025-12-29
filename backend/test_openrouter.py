import requests
import json

# Test OpenRouter API
OPENROUTER_API_KEY = "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"
url = "https://openrouter.ai/api/v1/chat/completions"

headers = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "http://localhost",
    "X-Title": "Stemly"
}

payload = {
    "model": "meta-llama/llama-3.2-3b-instruct:free",
    "messages": [
        {
            "role": "system", 
            "content": """You are a STEM topic classifier. Analyze the text and return JSON:
{
  "topic": "Topic Name",
  "variables": ["v", "t"],
  "confidence": 0.95
}"""
        },
        {"role": "user", "content": "INPUT TEXT:\nOptics laws of reflection"}
    ],
    "max_tokens": 100,
    "temperature": 0.2
}

print("Testing OpenRouter API...")
response = requests.post(url, json=payload, headers=headers, timeout=30)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
