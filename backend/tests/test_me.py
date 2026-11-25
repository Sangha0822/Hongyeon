from datetime import date, datetime, timedelta, timezone

from helpers import auth, pair, reload


async def test_me_for_a_new_unpaired_user(client, make_user):
    user = await make_user()
    body = (await client.get("/me", headers=auth(user))).json()
    assert body["id"] == str(user.id)
    assert body["paired"] is False
    assert body["display_name"] is None
    assert body["partner_name"] is None
    assert body["anniversary"] is None


async def test_me_shows_the_partner_name_and_couple_date(client, make_user):
    mina = await make_user(name="Mina", anniversary=date(2023, 7, 15))
    jamie = await make_user(name="Jamie", anniversary=date(2023, 7, 15))
    await pair(mina, jamie)

    body = (await client.get("/me", headers=auth(mina))).json()
    assert body["paired"] is True
    assert body["display_name"] == "Mina"
    assert body["partner_name"] == "Jamie"
    assert body["anniversary"] == "2023-07-15"


# --- PUT /me/name ---

async def test_name_is_trimmed_and_saved(client, make_user):
    user = await make_user()
    response = await client.put("/me/name", headers=auth(user), json={"display_name": "  Mina  "})
    assert response.status_code == 200
    assert response.json() == {"display_name": "Mina"}
    assert (await reload(user)).display_name == "Mina"


async def test_name_of_exactly_20_characters_is_allowed(client, make_user):
    user = await make_user()
    response = await client.put("/me/name", headers=auth(user), json={"display_name": "a" * 20})
    assert response.status_code == 200


async def test_name_that_is_blank_or_too_long_is_rejected(client, make_user):
    user = await make_user(name="Mina")
    for bad_name in ["", "   ", "a" * 21]:
        response = await client.put("/me/name", headers=auth(user), json={"display_name": bad_name})
        assert response.status_code == 422, bad_name
    assert (await reload(user)).display_name == "Mina"


# --- PUT /me/anniversary ---

def _utc_today():
    return datetime.now(timezone.utc).date()


async def test_anniversary_is_saved(client, make_user):
    user = await make_user()
    response = await client.put("/me/anniversary", headers=auth(user), json={"anniversary": "2023-07-15"})
    assert response.status_code == 200
    assert response.json() == {"anniversary": "2023-07-15"}
    assert (await reload(user)).anniversary == date(2023, 7, 15)


async def test_anniversary_allows_tomorrow_for_time_zones_ahead_of_utc(client, make_user):
    user = await make_user()
    tomorrow = (_utc_today() + timedelta(days=1)).isoformat()
    response = await client.put("/me/anniversary", headers=auth(user), json={"anniversary": tomorrow})
    assert response.status_code == 200


async def test_anniversary_rejects_bad_dates(client, make_user):
    user = await make_user()
    two_days_ahead = (_utc_today() + timedelta(days=2)).isoformat()
    for bad_date in [two_days_ahead, "1899-12-31", "not-a-date", "2023-02-30"]:
        response = await client.put("/me/anniversary", headers=auth(user), json={"anniversary": bad_date})
        assert response.status_code == 422, bad_date
    assert (await reload(user)).anniversary is None


async def test_anniversary_set_while_paired_updates_both_and_pushes_the_partner(client, make_user, apns):
    mina = await make_user(apns_token="mina-phone")
    jamie = await make_user(apns_token="jamie-phone")
    await pair(mina, jamie)

    response = await client.put("/me/anniversary", headers=auth(mina), json={"anniversary": "2024-02-14"})
    assert response.status_code == 200
    assert (await reload(mina)).anniversary == date(2024, 2, 14)
    assert (await reload(jamie)).anniversary == date(2024, 2, 14)
    assert apns.sent == ["jamie-phone"]


async def test_anniversary_set_while_unpaired_changes_only_your_row(client, make_user, apns):
    mina = await make_user()
    jamie = await make_user(apns_token="jamie-phone")

    await client.put("/me/anniversary", headers=auth(mina), json={"anniversary": "2024-02-14"})
    assert (await reload(jamie)).anniversary is None
    assert apns.sent == []
