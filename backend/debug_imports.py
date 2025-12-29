
print("Importing dotenv...")
try:
    from dotenv import load_dotenv
    load_dotenv()
    print("dotenv loaded.")
except Exception as e:
    print(f"dotenv failed: {e}")

print("Importing FastAPI...")
try:
    from fastapi import FastAPI
    print("FastAPI imported.")
except Exception as e:
    print(f"FastAPI failed: {e}")

print("Importing main...")
try:
    import main
    print("Main imported.")
except Exception as e:
    print(f"Main failed: {e}")
