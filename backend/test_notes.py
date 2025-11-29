import requests
import json

# Test the /notes/generate endpoint
url = "http://127.0.0.1:8000/notes/generate"

headers = {
    "Authorization": "Bearer test-token",
    "Content-Type": "application/json"
}

# Valid request body matching NotesGenerateRequest
data = {
    "topic": "Projectile Motion",
    "variables": ["U", "theta", "g", "R"],
    "image_path": None  # Optional, can be None
}

print("🧪 Testing POST /notes/generate")
print(f"URL: {url}")
print(f"Headers: {json.dumps(headers, indent=2)}")
print(f"Body: {json.dumps(data, indent=2)}")
print()

response = requests.post(url, headers=headers, json=data)

print(f"Status Code: {response.status_code}")
print(f"Response: {response.text}")

if response.status_code != 200:
    print("\n❌ Request failed!")
    try:
        error_detail = response.json()
        print(f"Error Detail: {json.dumps(error_detail, indent=2)}")
    except:
        print(f"Raw Response: {response.text}")
else:
    print("\n✅ Request succeeded!")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
