import asyncio
import os
from dotenv import load_dotenv
from aioapns import APNs, NotificationRequest, PushType

load_dotenv()

async def main():
    with open(os.environ["APNS_KEY_PATH"]) as f:
        key_content = f.read()

    apns = APNs(
        key=key_content,
        key_id=os.environ["APNS_KEY_ID"],
        team_id=os.environ["APNS_TEAM_ID"],
        topic=os.environ["APNS_TOPIC"],
        use_sandbox=True,
    )

    request = NotificationRequest(
        device_token=os.environ["APNS_DEVICE_TOKEN"],
        message={"aps": {"content-available": 1}},
        push_type=PushType.BACKGROUND,
    )

    response = await apns.send_notification(request)
    print("Success:", response.is_successful)
    print("Description:", response.description)

asyncio.run(main())
