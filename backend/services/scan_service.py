import os
import shutil
import uuid
from typing import List
from fastapi import UploadFile

UPLOAD_DIR = "static/uploads"

async def save_scan(file: UploadFile) -> str:
    """
    Saves the uploaded scan file to the static/uploads directory.
    Returns the relative path to the saved file.
    """
    if not os.path.exists(UPLOAD_DIR):
        os.makedirs(UPLOAD_DIR)

    file_extension = os.path.splitext(file.filename)[1]
    if not file_extension:
        file_extension = ".jpg" # Default to jpg if no extension

    # Generate a unique filename
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    return file_path
