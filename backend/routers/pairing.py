import random
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from database import async_session
from models import User, PairingCode
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
    code = request.code.upper()
    async with async_session() as session:
        pairing_code = await session.get(PairingCode, code)
        if pairing_code is None or pairing_code.expires_at < datetime.now(timezone.utc):
            raise HTTPException(status_code=400, detail="Invalid or expired pairing code")

        if pairing_code.creator_id == current_user.id:
            raise HTTPException(status_code=400, detail="You cannot join your own pairing code")

        creator = await session.get(User, pairing_code.creator_id)
        joiner = await session.get(User, current_user.id)
        creator.partner_id = joiner.id
        joiner.partner_id = creator.id

        await session.delete(pairing_code)
        await session.commit()

    return {"partner_id": str(creator.id)}
