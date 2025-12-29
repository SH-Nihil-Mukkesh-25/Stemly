import requests

url = "https://api.aimlapi.com/v1/images/generations/"

payload = {
  "model": "flux/schnell",
  "prompt": """
Create a classroom of young robots. 
The chalkboard in the classroom has 'AI Is Your Friend' written on it.
"""
}

headers = {
  "Authorization": "Bearer f93aade779b843acbcbfc52e43c940a0", 
  "content-type": "application/json"
}

print("Sending request to AIML API...")
try:
    response = requests.post(url, json=payload, headers=headers, timeout=30)
    response.raise_for_status()
    print("Generation Success!")
    print(response.json())
except Exception as e:
    print(f"Error: {e}")
    if hasattr(e, 'response') and e.response:
        print(f"Response Body: {e.response.text}")
