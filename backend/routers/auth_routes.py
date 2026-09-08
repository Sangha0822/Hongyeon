from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from database import async_session
from models import User
from auth import verify_apple_identity_token, verify_google_identity_token, create_session_token
from dependencies import get_current_user

router = APIRouter()

class AppleAuthRequest(BaseModel):
    identity_token: str

@router.post("/auth/apple")
async def auth_apple(request: AppleAuthRequest):
    claims = verify_apple_identity_token(request.identity_token)
    async with async_session() as session:
        result = await session.execute(
            select(User).where(User.provider_subject == claims["provider_subject"])
        )
        user = result.scalar_one_or_none()
        if user is None:
            user = User(
                auth_provider="apple",
                provider_subject=claims["provider_subject"],
                email=claims.get("email"),
            )
            session.add(user)
            await session.commit()
        token = create_session_token(str(user.id))
    return {"token": token}

class GoogleAuthRequest(BaseModel):
    identity_token: str

@router.post("/auth/google")
async def auth_google(request: GoogleAuthRequest):
    claims = verify_google_identity_token(request.identity_token)
    async with async_session() as session:
        result = await session.execute(
            select(User).where(User.provider_subject == claims["provider_subject"])
        )
        user = result.scalar_one_or_none()
        if user is None:
            user = User(
                auth_provider="google",
                provider_subject=claims["provider_subject"],
                email=claims.get("email"),
            )
            session.add(user)
            await session.commit()
        token = create_session_token(str(user.id))
    return {"token": token}

@router.get("/me")
async def read_me(current_user: User = Depends(get_current_user)):
    return {"id": str(current_user.id), "email": current_user.email, "auth_provider": current_user.auth_provider}
