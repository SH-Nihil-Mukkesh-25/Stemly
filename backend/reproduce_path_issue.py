from pathlib import Path
import os

# Mimic file_utils.py logic
PROJECT_ROOT = Path(os.getcwd()).resolve()
STATIC_SCANS_DIR = (PROJECT_ROOT / "static" / "scans").resolve()

print(f"PROJECT_ROOT: {PROJECT_ROOT}")
print(f"STATIC_SCANS_DIR: {STATIC_SCANS_DIR}")

# Simulate input path
image_path = "static/scans/test_image.png"
path = Path(image_path)
if not path.is_absolute():
    path = (Path.cwd() / path).resolve()
else:
    path = path.resolve()

print(f"Resolved Input Path: {path}")

# The failing check
is_valid = str(path).startswith(str(STATIC_SCANS_DIR))
print(f"Starts with check: {is_valid}")

if not is_valid:
    print(f"Mismatch details:")
    print(f"Path string: {str(path)}")
    print(f"Ref string:  {str(STATIC_SCANS_DIR)}")