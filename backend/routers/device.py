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