import secrets
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import delete, or_, select
from sqlalchemy.exc import IntegrityError
from aioapns import NotificationRequest, PushType
from database import async_session
from models import User, PairingCode
from push import get_apns_client
from dependencies import get_current_user


router = APIRouter()

CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
CODE_LIFETIME = timedelta(hours=24)

@router.post("/pairing/create")
async def create_pairing_code(current_user: User = Depends(get_current_user)):
    # A code is the table's primary key, so two live codes can never be equal. If the
    # random pick collides with an existing one, the insert fails and we pick again.
    for _ in range(5):
        code = ''.join(secrets.choice(CODE_ALPHABET) for _ in range(6))
        now = datetime.now(timezone.utc)
        expires_at = now + CODE_LIFETIME

        async with async_session() as session:
            # One live code per user: making a new code removes this user's earlier ones.
            # Expired codes from anyone are cleared at the same time.
            await session.execute(
                delete(PairingCode).where(
                    or_(PairingCode.creator_id == current_user.id, PairingCode.expires_at < now)
                )
            )
            session.add(PairingCode(code=code, creator_id=current_user.id, expires_at=expires_at))
            try:
                await session.commit()
            except IntegrityError:
                continue

        return {"code": code, "expires_at": expires_at.isoformat()}

    raise HTTPException(status_code=503, detail="Could not create a pairing code, please try again")

@router.get("/pairing/code")
async def read_pairing_code(current_user: User = Depends(get_current_user)):
    now = datetime.now(timezone.utc)
    async with async_session() as session:
        result = await session.execute(
            select(PairingCode).where(
                PairingCode.creator_id == current_user.id,
                PairingCode.expires_at > now,
            )
        )
        pairing_code = result.scalars().first()

    # Having no live code is a normal state, not an error, so it is a 200 with empty values.
    if pairing_code is None:
        return {"code": None, "expires_at": None}
    return {"code": pairing_code.code, "expires_at": pairing_code.expires_at.isoformat()}

class JoinPairingRequest(BaseModel):
    code: str

# Each way a join can fail gets a fixed code the app can rely on, plus a readable message.
# The codes never change; the messages are for people reading logs and may be reworded.
def join_error(code: str, message: str) -> HTTPException:
    return HTTPException(status_code=400, detail={"code": code, "message": message})

@router.post("/pairing/join")
async def join_pairing_code(request: JoinPairingRequest, current_user: User = Depends(get_current_user)):
    if current_user.partner_id is not None:
        raise join_error("already_paired", "You are already paired")

    # The app shows codes as "HY-XXXXXX". Accept that form, the bare six characters,
    # lowercase, and stray spaces, so however the code was typed or pasted it still matches.
    code = request.code.strip().upper().removeprefix("HY-")
    async with async_session() as session:
        pairing_code = await session.get(PairingCode, code)
        if pairing_code is None or pairing_code.expires_at < datetime.now(timezone.utc):
            # Expired codes are usually deleted by the next create, so "expired" and
            # "never existed" can't be told apart reliably; they share one error.
            raise join_error("code_not_found", "Invalid or expired pairing code")

        if pairing_code.creator_id == current_user.id:
            raise join_error("own_code", "You cannot join your own pairing code")

        creator = await session.get(User, pairing_code.creator_id)
        if creator.partner_id is not None:
            raise join_error("partner_already_paired", "This pairing code's creator is already paired")

        joiner = await session.get(User, current_user.id)
        creator.partner_id = joiner.id
        joiner.partner_id = creator.id

        # The couple shares one date: the creator's if they gave one, otherwise the joiner's.
        couple_anniversary = creator.anniversary or joiner.anniversary
        creator.anniversary = couple_anniversary
        joiner.anniversary = couple_anniversary

        creator_token = creator.apns_token
        creator_id = creator.id

        await session.delete(pairing_code)
        await session.commit()

    if creator_token:
        push_request = NotificationRequest(
            device_token=creator_token,
            message={"aps": {"content-available": 1}},
            push_type=PushType.BACKGROUND,
        )
        try:
            response = await get_apns_client().send_notification(push_request)
            print(f"Push send result: is_successful={response.is_successful}, description={response.description}")

            if response.description == "BadDeviceToken" or response.description == "Unregistered":
                async with async_session() as session:
                    stale_creator = await session.get(User, creator_id)
                    stale_creator.apns_token = None
                    await session.commit()
        except Exception as e:
            print(f"Push send failed: {e}")

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
        # The date was this couple's; keeping it would carry it into either person's next pairing.
        user.anniversary = None
        if partner is not None:
            partner.partner_id = None
            partner.anniversary = None

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
