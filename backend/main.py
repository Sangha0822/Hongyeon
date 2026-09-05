from fastapi import FastAPI
from pydantic import BaseModel
import os
import uuid
from dotenv import load_dotenv
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import async_sessionmaker
from models import LocationState
from aioapns import APNs, NotificationRequest, PushType

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


async_session = async_sessionmaker(engine)
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
