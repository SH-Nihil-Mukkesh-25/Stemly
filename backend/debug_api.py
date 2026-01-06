
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY", "")

print(f"KEY_START:|{api_key[:5]}|")
if api_key.startswith("Alza"):
    print("STATUS: TYPO_DETECTED_LOWERCASE_L")
elif api_key.startswith("AIza"):
    print("STATUS: PREFIX_OK")
else:
    print("STATUS: UNKNOWN_PREFIX")
