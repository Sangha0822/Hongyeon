import os
from aioapns import APNs

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
