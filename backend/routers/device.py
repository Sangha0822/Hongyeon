from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from database import async_session
from models import User
from dependencies import get_current_user

router = APIRouter()

class DeviceTokenRequest(BaseModel):
    token: str

@router.post("/device-token")
async def register_device_token(request: DeviceTokenRequest, current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        result = await session.execute(select(User).where(User.apns_token == request.token))
        other_user = result.scalar_one_or_none()

        if other_user is not None and other_user.id != current_user.id:
            other_user.apns_token = None

        user = await session.get(User, current_user.id)
        user.apns_token = request.token

        await session.commit()

    return {"status": "registered"}

@router.delete("/device-token/{token}")
async def remove_device_token(token: str, current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        user = await session.get(User, current_user.id)

        # Only clear it if this account's stored token is the one for the device signing out.
        # If the account has since registered a different device, that one keeps its pushes.
        if user.apns_token != token:
            return {"status": "unchanged"}

        user.apns_token = None
        await session.commit()

    return {"status": "removed"}
