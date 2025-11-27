import json
import os
from typing import Any, Dict, Optional

import firebase_admin
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials

SERVICE_ACCOUNT_FILE_ENV = "FIREBASE_CREDENTIALS_FILE"
SERVICE_ACCOUNT_JSON_ENV = "FIREBASE_CREDENTIALS_JSON"


def _load_service_account() -> credentials.Certificate:
    """
    Load Firebase service account credentials either from a file path or from a
    raw JSON string stored in environment variables.
    """
    file_path = os.getenv(SERVICE_ACCOUNT_FILE_ENV)
    json_blob = os.getenv(SERVICE_ACCOUNT_JSON_ENV)

    if file_path:
        if not os.path.isfile(file_path):
            raise FileNotFoundError(f"Firebase service account file not found: {file_path}")
        return credentials.Certificate(file_path)

    if json_blob:
        try:
            service_account_dict: Dict[str, Any] = json.loads(json_blob)
        except json.JSONDecodeError as exc:
            raise ValueError("Invalid JSON provided in FIREBASE_CREDENTIALS_JSON") from exc
        return credentials.Certificate(service_account_dict)

    raise EnvironmentError(
        "Firebase credentials missing. Set FIREBASE_CREDENTIALS_FILE or FIREBASE_CREDENTIALS_JSON."
    )


def _initialize_app() -> firebase_admin.App:
    if firebase_admin._apps:
        return firebase_admin.get_app()

    cred = _load_service_account()
    return firebase_admin.initialize_app(cred)


def verify_firebase_token(id_token: str) -> Dict[str, Optional[str]]:
    """
    Verify the incoming Firebase ID token and return the normalized user info.
    """
    if not id_token:
        raise ValueError("Missing Firebase ID token")

    app = _initialize_app()
    decoded = firebase_auth.verify_id_token(id_token, app=app)

    return {
        "uid": decoded.get("uid"),
        "email": decoded.get("email"),
        "name": decoded.get("name") or decoded.get("displayName"),
        "picture": decoded.get("picture"),
    }

