import push
from helpers import auth, reload


# --- POST /device-token and DELETE /device-token/{token} ---

async def test_registering_saves_the_token(client, make_user):
    user = await make_user()
    response = await client.post("/device-token", headers=auth(user), json={"token": "phone-1"})
    assert response.json() == {"status": "registered"}
    assert (await reload(user)).apns_token == "phone-1"


async def test_a_phone_signing_into_another_account_moves_its_token(client, make_user):
    first_account = await make_user(apns_token="shared-phone")
    second_account = await make_user()

    await client.post("/device-token", headers=auth(second_account), json={"token": "shared-phone"})
    assert (await reload(first_account)).apns_token is None
    assert (await reload(second_account)).apns_token == "shared-phone"


async def test_removing_your_current_token_clears_it(client, make_user):
    user = await make_user(apns_token="phone-1")
    response = await client.delete("/device-token/phone-1", headers=auth(user))
    assert response.json() == {"status": "removed"}
    assert (await reload(user)).apns_token is None


async def test_removing_an_old_token_keeps_the_newer_one(client, make_user):
    user = await make_user(apns_token="new-phone")
    response = await client.delete("/device-token/old-phone", headers=auth(user))
    assert response.json() == {"status": "unchanged"}
    assert (await reload(user)).apns_token == "new-phone"


# --- send_silent_push ---

async def test_push_without_a_token_sends_nothing(make_user, apns):
    user = await make_user()
    await push.send_silent_push(user.id, None)
    assert apns.sent == []


async def test_push_success_keeps_the_token(make_user, apns):
    user = await make_user(apns_token="phone-1")
    await push.send_silent_push(user.id, "phone-1")
    assert apns.sent == ["phone-1"]
    assert (await reload(user)).apns_token == "phone-1"


async def test_push_to_a_dead_token_forgets_it(make_user, apns):
    for answer in ["BadDeviceToken", "Unregistered"]:
        user = await make_user(apns_token="dead-phone")
        apns.answer = answer
        await push.send_silent_push(user.id, "dead-phone")
        assert (await reload(user)).apns_token is None, answer


async def test_a_late_rejection_of_an_old_token_keeps_the_newer_one(make_user, apns):
    user = await make_user(apns_token="new-phone")
    apns.answer = "BadDeviceToken"
    await push.send_silent_push(user.id, "old-phone")
    assert (await reload(user)).apns_token == "new-phone"


async def test_a_push_failure_is_never_raised(make_user, apns):
    user = await make_user(apns_token="phone-1")
    apns.answer = ConnectionError("Apple unreachable")
    await push.send_silent_push(user.id, "phone-1")  # must not raise
    assert (await reload(user)).apns_token == "phone-1"
