import requests

url = "http://localhost:8000/visualiser/generate"

headers = {
    "Authorization": "Bearer test-token",
    "Content-Type": "application/json"
}

payload = {"topic": "Optics", "variables": []}

print(f"Testing: POST {url}")
print(f"Payload: {payload}")

try:
    response = requests.post(url, json=payload, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
    print(f"Body: {response.text}")
except Exception as e:
    print(f"Error: {e}")
