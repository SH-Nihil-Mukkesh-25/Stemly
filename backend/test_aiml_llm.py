import requests

url = "https://api.aimlapi.com/v1/chat/completions"

headers = {
    "Authorization": "Bearer f93aade779b843acbcbfc52e43c940a0",
    "Content-Type": "application/json"
}

payload = {
    "model": "gpt-4o",  # Trying a standard alias supported by AIML
    "messages": [
        {"role": "user", "content": "Hello"}
    ],
    "max_tokens": 10
}

print(f"Testing LLM access with model: {payload['model']}...")

try:
    response = requests.post(url, json=payload, headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code != 200:
         print(f"Error Body: {response.text}")
         
    response.raise_for_status()
    print("Success!")
    print(response.json())
except Exception as e:
    print(f"Error: {e}")
    if hasattr(e, 'response') and e.response:
        print(f"Response Body: {e.response.text}")
