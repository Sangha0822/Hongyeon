import os
import uuid
from datetime import datetime, timezone
from fastapi import APIRouter
from pydantic import BaseModel
from aioapns import NotificationRequest, PushType
from database import async_session
from models import LocationState
from push import get_apns_client

router = APIRouter()

TEST_USER_ID = uuid.UUID("39cd8fb9-60b0-4fa3-ac0c-ad01051845e3")

class Location(BaseModel):
    lat: float
    lng: float

@router.post("/location")
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

@router.get("/location")
async def get_location():
    async with async_session() as session:
        state = await session.get(LocationState, TEST_USER_ID)
        if state is None:
            return {}
        return {"lat": state.lat, "lng": state.lng, "updated_at": state.updated_at}
