import os
import jwt
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv

load_dotenv()

JWT_SECRET_KEY = os.environ["JWT_SECRET_KEY"]
JWT_ALGORITHM = "HS256"

def create_session_token(user_id: str) -> str:
    payload = {
        "sub": str(user_id),
        "exp": datetime.now(timezone.utc) + timedelta(days=365),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

def verify_session_token(token: str) -> str:
    payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
    return payload["sub"]


#-------- APPLE JWT SIGN IN --------------------
APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"
APPLE_AUDIENCE = "com.sanghajeon.Hongyeon"

_apple_jwks_client = None

def get_apple_jwks_client():
    global _apple_jwks_client
    if _apple_jwks_client is None:
        _apple_jwks_client = jwt.PyJWKClient(APPLE_KEYS_URL)
    return _apple_jwks_client

def verify_apple_identity_token(identity_token: str) -> dict:
    signing_key = get_apple_jwks_client().get_signing_key_from_jwt(identity_token)
    payload = jwt.decode(
        identity_token,
        signing_key.key,
        algorithms=["RS256"],
        audience=APPLE_AUDIENCE,
        issuer=APPLE_ISSUER,
    )
    return {
        "provider_subject": payload["sub"],
        "email": payload.get("email"),
    }
