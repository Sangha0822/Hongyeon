import os
from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from aioapns import NotificationRequest, PushType
from database import async_session
from models import LocationState, User
from push import get_apns_client
from dependencies import get_current_user

router = APIRouter()


class Location(BaseModel):
    lat: float
    lng: float

@router.post("/location")
async def post_location(location: Location, current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        state = await session.get(LocationState, current_user.id)
        if state is None:
            state = LocationState(user_id=current_user.id)
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
async def get_location(current_user: User = Depends(get_current_user)):
    if current_user.partner_id is None:
        return {"paired": False, "lat": None, "lng": None, "updated_at": None}

    async with async_session() as session:
        state = await session.get(LocationState, current_user.partner_id)

    if state is None:
        return {"paired": True, "lat": None, "lng": None, "updated_at": None}

    return {"paired": True, "lat": state.lat, "lng": state.lng, "updated_at": state.updated_at}
