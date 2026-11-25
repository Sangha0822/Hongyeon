import os
import uuid
from aioapns import APNs, NotificationRequest, PushType
from database import async_session
from models import User

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


async def send_silent_push(user_id: uuid.UUID, device_token: str | None) -> None:
    """Wakes the user's app in the background so it refreshes. Shows nothing on screen.

    Best-effort: a failed push is logged and never raised, so it can't turn the
    request that triggered it into an error. The app also refreshes on its own when opened.
    """
    if not device_token:
        return

    push_request = NotificationRequest(
        device_token=device_token,
        message={"aps": {"content-available": 1}},
        push_type=PushType.BACKGROUND,
    )
    try:
        response = await get_apns_client().send_notification(push_request)
        print(f"Push send result: is_successful={response.is_successful}, description={response.description}")

        # Apple says this token will never work again (e.g. the app was deleted), so forget it,
        # unless the phone has already registered a newer token in the meantime.
        if response.description in ("BadDeviceToken", "Unregistered"):
            async with async_session() as session:
                user = await session.get(User, user_id)
                if user is not None and user.apns_token == device_token:
                    user.apns_token = None
                    await session.commit()
    except Exception as e:
        print(f"Push send failed: {e}")
