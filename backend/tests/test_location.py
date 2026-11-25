from sqlalchemy import func, select

from database import async_session
from models import LocationState
from helpers import auth, pair

# Made-up coordinates, not real places.
FIRST = {"lat": 1.5, "lng": 2.5}
SECOND = {"lat": 3.5, "lng": 4.5}


async def test_posting_again_overwrites_the_one_row_instead_of_keeping_history(client, make_user):
    user = await make_user()
    await client.post("/location", headers=auth(user), json=FIRST)
    await client.post("/location", headers=auth(user), json=SECOND)

    async with async_session() as session:
        assert await session.scalar(select(func.count()).select_from(LocationState)) == 1
        state = await session.get(LocationState, user.id)
    assert (state.lat, state.lng) == (3.5, 4.5)


async def test_reading_while_unpaired_says_not_paired(client, make_user):
    user = await make_user()
    body = (await client.get("/location", headers=auth(user))).json()
    assert body == {"paired": False, "lat": None, "lng": None, "updated_at": None}


async def test_reading_before_the_partner_has_shared_returns_nulls(client, make_user):
    mina = await make_user()
    jamie = await make_user()
    await pair(mina, jamie)

    body = (await client.get("/location", headers=auth(mina))).json()
    assert body == {"paired": True, "lat": None, "lng": None, "updated_at": None}


async def test_reading_returns_the_partners_location_not_your_own(client, make_user):
    mina = await make_user()
    jamie = await make_user()
    await pair(mina, jamie)
    await client.post("/location", headers=auth(mina), json=FIRST)
    await client.post("/location", headers=auth(jamie), json=SECOND)

    body = (await client.get("/location", headers=auth(mina))).json()
    assert (body["lat"], body["lng"]) == (3.5, 4.5)
    assert body["updated_at"] is not None


async def test_someone_elses_location_is_never_returned(client, make_user):
    mina = await make_user()
    stranger = await make_user()
    await client.post("/location", headers=auth(stranger), json=FIRST)

    body = (await client.get("/location", headers=auth(mina))).json()
    assert body["paired"] is False
    assert body["lat"] is None


async def test_posting_pushes_the_partner_only_when_paired(client, make_user, apns):
    mina = await make_user()
    jamie = await make_user(apns_token="jamie-phone")

    await client.post("/location", headers=auth(mina), json=FIRST)
    assert apns.sent == []

    await pair(mina, jamie)
    await client.post("/location", headers=auth(mina), json=SECOND)
    assert apns.sent == ["jamie-phone"]
