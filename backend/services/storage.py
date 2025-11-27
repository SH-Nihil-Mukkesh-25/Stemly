import os
import uuid

ALLOWED_CONTENT_TYPES = {"image/png", "image/jpeg", "image/jpg"}
MAX_SCAN_BYTES = 5 * 1024 * 1024  # 5 MB
SCANS_DIR = "static/scans/"


async def save_scan(file):
    os.makedirs(SCANS_DIR, exist_ok=True)

    content_type = (file.content_type or "").lower()
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise ValueError("Unsupported file type. Upload a PNG or JPEG image.")

    filename = f"{uuid.uuid4()}.png"
    file_path = os.path.join(SCANS_DIR, filename)

    contents = bytearray()
    total_bytes = 0
    while True:
        chunk = await file.read(1024 * 1024)
        if not chunk:
            break
        total_bytes += len(chunk)
        if total_bytes > MAX_SCAN_BYTES:
            raise ValueError("File too large. Maximum allowed size is 5 MB.")
        contents.extend(chunk)

    if total_bytes == 0:
        raise ValueError("Uploaded file is empty.")

    with open(file_path, "wb") as f:
        f.write(contents)

    return f"static/scans/{filename}"
