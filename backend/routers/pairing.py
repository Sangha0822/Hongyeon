import random
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from aioapns import NotificationRequest, PushType
from database import async_session
from models import User, PairingCode
from push import get_apns_client
from dependencies import get_current_user


router = APIRouter()

CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

@router.post("/pairing/create")
async def create_pairing_code(current_user: User = Depends(get_current_user)):
    code = ''.join(random.choices(CODE_ALPHABET, k=6))
    async with async_session() as session:
        pairing_code = PairingCode(
            code=code,
            creator_id=current_user.id,
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=10)
        )
        session.add(pairing_code)
        await session.commit()
    return {"code": code}

class JoinPairingRequest(BaseModel):
    code: str

@router.post("/pairing/join")
async def join_pairing_code(request: JoinPairingRequest, current_user: User = Depends(get_current_user)):
    if current_user.partner_id is not None:
        raise HTTPException(status_code=400, detail="You are already paired")

    code = request.code.upper()
    async with async_session() as session:
        pairing_code = await session.get(PairingCode, code)
        if pairing_code is None or pairing_code.expires_at < datetime.now(timezone.utc):
            raise HTTPException(status_code=400, detail="Invalid or expired pairing code")

        if pairing_code.creator_id == current_user.id:
            raise HTTPException(status_code=400, detail="You cannot join your own pairing code")

        creator = await session.get(User, pairing_code.creator_id)
        if creator.partner_id is not None:
            raise HTTPException(status_code=400, detail="This pairing code's creator is already paired")

        joiner = await session.get(User, current_user.id)
        creator.partner_id = joiner.id
        joiner.partner_id = creator.id

        await session.delete(pairing_code)
        await session.commit()

    return {"partner_id": str(creator.id)}

@router.post("/pairing/unpair")
async def unpair(current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        user = await session.get(User, current_user.id)

        if user.partner_id is None:
            return {"unpaired": False, "detail": "You are not currently paired"}

        partner = await session.get(User, user.partner_id)
        partner_token = partner.apns_token if partner is not None else None
        partner_id = partner.id if partner is not None else None
        user.partner_id = None
        if partner is not None:
            partner.partner_id = None

        await session.commit()

    if partner_token:
        push_request = NotificationRequest(
            device_token=partner_token,
            message={"aps": {"content-available": 1}},
            push_type=PushType.BACKGROUND,
        )
        try:
            response = await get_apns_client().send_notification(push_request)
            print(f"Push send result: is_successful={response.is_successful}, description={response.description}")

            if response.description == "BadDeviceToken" or response.description == "Unregistered":
                async with async_session() as session:
                    stale_partner = await session.get(User, partner_id)
                    stale_partner.apns_token = None
                    await session.commit()
        except Exception as e:
            print(f"Push send failed: {e}")

    return {"unpaired": True}
