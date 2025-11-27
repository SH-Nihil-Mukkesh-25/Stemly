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

