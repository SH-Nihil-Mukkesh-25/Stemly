from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from auth.firebase import verify_firebase_token
from database.user_model import record_user_login

http_bearer = HTTPBearer(auto_error=False)


async def require_firebase_user(
    request: Request, credentials: HTTPAuthorizationCredentials = Depends(http_bearer)
):
    """
    Dependency that validates the Authorization header, verifies the Firebase
    token, persists/updates the user in MongoDB, and attaches the user object
    to `request.state`.
    """
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Authorization header.",
        )

    id_token = credentials.credentials
    
    # Debug print to see what we are receiving
    print(f"DEBUG: Received token: '{id_token}'")

    # --- DEV BYPASS FOR TESTING ---
    if id_token.strip() == "test-token":
        print("⚠ USING DEV BYPASS TOKEN")
        mock_user = {
            "uid": "test-user-123",
            "email": "test@stemly.app",
            "name": "Test User",
            "picture": None
        }
        # We still try to record login, but user_model handles missing DB now
        await record_user_login(mock_user)
        request.state.user = mock_user
        request.state.id_token = id_token
        return mock_user
    # ------------------------------

    try:
        firebase_user = verify_firebase_token(id_token)
    except Exception as exc:  # firebase_admin raises several custom exceptions
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Firebase ID token.",
        ) from exc

    await record_user_login(firebase_user)

    request.state.user = firebase_user
    request.state.id_token = id_token
    return firebase_user
