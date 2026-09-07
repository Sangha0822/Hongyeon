from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import os
import uuid
from dotenv import load_dotenv
from sqlalchemy import text, select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from datetime import datetime, timezone, timedelta
from models import LocationState, User, PairingCode
from aioapns import APNs, NotificationRequest, PushType
from auth import verify_apple_identity_token, verify_google_identity_token, create_session_token, verify_session_token
import jwt
import random

load_dotenv()
engine = create_async_engine(os.environ["DATABASE_URL"])

apns_client = None

def get_apns_client():
    global apns_client
    if apns_client is None:
        if os.environ.get("APNS_KEY_CONTENT"):
            apns_key = os.environ["APNS_KEY_CONTENT"]
        else:
            apns_key = open(os.environ["APNS_KEY_PATH"]).read()

        apns_client = APNs(
            key=apns_key,
            key_id=os.environ["APNS_KEY_ID"],
            team_id=os.environ["APNS_TEAM_ID"],
            topic=os.environ["APNS_TOPIC"],
            use_sandbox=True,
        )
    return apns_client


app = FastAPI()
@app.get("/health")
async def health_check():
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "ok", "db": "connected"}


async_session = async_sessionmaker(engine, expire_on_commit=False)
TEST_USER_ID = uuid.UUID("39cd8fb9-60b0-4fa3-ac0c-ad01051845e3")

class Location(BaseModel):
    lat: float
    lng: float

@app.post("/location")
async def post_location(location: Location):
    async with async_session() as session:
        state = await session.get(LocationState, TEST_USER_ID)
        if state is None:
            state = LocationState(user_id=TEST_USER_ID)
            session.add(state)
        state.lat = location.lat
        state.lng = location.lng
        state.updated_at = datetime.now(timezone.utc)
        await session.commit()

    notify_token = os.environ.get("NOTIFY_DEVICE_TOKEN")
    if notify_token:
        push_request = NotificationRequest(
            device_token=notify_token,
            message={"aps": {"content-available": 1}},
            push_type=PushType.BACKGROUND,
        )
        try:
            response = await get_apns_client().send_notification(push_request)
            print(f"Push send result: is_successful={response.is_successful}, description={response.description}")
        except Exception as e:
            print(f"Push send failed: {e}")
    
    return {"status": "received"}

@app.get("/location")
async def get_location():
    async with async_session() as session:
        state = await session.get(LocationState, TEST_USER_ID)
        if state is None:
            return {}
        return {"lat": state.lat, "lng": state.lng, "updated_at": state.updated_at}


#-------- APPLE JWT SIGN IN --------------------
class AppleAuthRequest(BaseModel):
    identity_token: str

@app.post("/auth/apple")
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

#-------- GOOGLE JWT SIGN IN --------------------
class GoogleAuthRequest(BaseModel):
    identity_token: str

@app.post("/auth/google")
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

security = HTTPBearer(auto_error=False)

async def get_current_user(credentials: HTTPAuthorizationCredentials | None = Depends(security)) -> User:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing authentication token")

    try:
        user_id = verify_session_token(credentials.credentials)
    except jwt.exceptions.InvalidTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

    async with async_session() as session:
        user = await session.get(User, uuid.UUID(user_id))
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    return user

@app.get("/me")
async def read_me(current_user: User = Depends(get_current_user)):
    return {"id": str(current_user.id), "email": current_user.email, "auth_provider": current_user.auth_provider}


#----------Pairing Code --------

CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
@app.post("/pairing/create")
async def create_pairing_code(current_user: User = Depends(get_current_user)):
    code = ''.join(random.choices(CODE_ALPHABET, k=6))
    async with async_session() as session:
        pairing_code = PairingCode(
            code = code,
            creator_id = current_user.id,
            expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)
        )
        session.add(pairing_code)
        await session.commit()
    return {"code": code}

class JoinPairingRequest(BaseModel):
    code: str

@app.post("/pairing/join")
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
