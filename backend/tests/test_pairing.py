from datetime import date, datetime, timedelta, timezone

from sqlalchemy import select

from database import async_session
from models import PairingCode
from routers.pairing import CODE_ALPHABET
from helpers import auth, pair, reload


async def _codes():
    async with async_session() as session:
        return list((await session.execute(select(PairingCode))).scalars())


async def _add_code(code, creator, expires_in):
    async with async_session() as session:
        session.add(PairingCode(code=code, creator_id=creator.id,
                                expires_at=datetime.now(timezone.utc) + expires_in))
        await session.commit()


# --- POST /pairing/create and GET /pairing/code ---

async def test_create_returns_a_six_character_code_valid_for_24_hours(client, make_user):
    user = await make_user()
    body = (await client.post("/pairing/create", headers=auth(user))).json()

    assert len(body["code"]) == 6
    assert all(character in CODE_ALPHABET for character in body["code"])
    lifetime = datetime.fromisoformat(body["expires_at"]) - datetime.now(timezone.utc)
    assert timedelta(hours=23, minutes=59) < lifetime <= timedelta(hours=24)


async def test_creating_again_replaces_your_old_code(client, make_user):
    user = await make_user()
    await client.post("/pairing/create", headers=auth(user))
    second = (await client.post("/pairing/create", headers=auth(user))).json()

    codes = await _codes()
    assert [c.code for c in codes] == [second["code"]]


async def test_create_clears_expired_codes_from_anyone(client, make_user):
    old_creator = await make_user()
    live_creator = await make_user()
    await _add_code("OLDOLD", old_creator, expires_in=timedelta(minutes=-1))
    await _add_code("LIVE22", live_creator, expires_in=timedelta(hours=1))

    user = await make_user()
    await client.post("/pairing/create", headers=auth(user))

    remaining = {c.code for c in await _codes()}
    assert "OLDOLD" not in remaining
    assert "LIVE22" in remaining


async def test_read_code_returns_the_live_code(client, make_user):
    user = await make_user()
    created = (await client.post("/pairing/create", headers=auth(user))).json()
    body = (await client.get("/pairing/code", headers=auth(user))).json()
    assert body["code"] == created["code"]


async def test_read_code_returns_nulls_when_there_is_none_or_it_expired(client, make_user):
    user = await make_user()
    assert (await client.get("/pairing/code", headers=auth(user))).json() == {"code": None, "expires_at": None}

    await _add_code("EXPIRD", user, expires_in=timedelta(minutes=-1))
    response = await client.get("/pairing/code", headers=auth(user))
    assert response.status_code == 200
    assert response.json() == {"code": None, "expires_at": None}


# --- POST /pairing/join ---

async def test_join_pairs_both_deletes_the_code_and_pushes_the_creator(client, make_user, apns):
    creator = await make_user(apns_token="creator-phone")
    joiner = await make_user()
    code = (await client.post("/pairing/create", headers=auth(creator))).json()["code"]

    response = await client.post("/pairing/join", headers=auth(joiner), json={"code": code})
    assert response.status_code == 200
    assert (await reload(creator)).partner_id == joiner.id
    assert (await reload(joiner)).partner_id == creator.id
    assert await _codes() == []
    assert apns.sent == ["creator-phone"]


async def test_join_accepts_the_code_however_it_was_typed(client, make_user):
    for typed in ["hy-abc234", "  HY-ABC234 ", "abc234"]:
        creator = await make_user()
        joiner = await make_user()
        await _add_code("ABC234", creator, expires_in=timedelta(hours=1))

        response = await client.post("/pairing/join", headers=auth(joiner), json={"code": typed})
        assert response.status_code == 200, typed


async def _join_error(client, user, code):
    response = await client.post("/pairing/join", headers=auth(user), json={"code": code})
    assert response.status_code == 400
    return response.json()["detail"]["code"]


async def test_join_with_an_unknown_or_expired_code_says_code_not_found(client, make_user):
    creator = await make_user()
    joiner = await make_user()
    await _add_code("EXPIRD", creator, expires_in=timedelta(minutes=-1))

    assert await _join_error(client, joiner, "NOPE22") == "code_not_found"
    assert await _join_error(client, joiner, "EXPIRD") == "code_not_found"


async def test_join_with_your_own_code_says_own_code(client, make_user):
    user = await make_user()
    code = (await client.post("/pairing/create", headers=auth(user))).json()["code"]
    assert await _join_error(client, user, code) == "own_code"


async def test_join_while_already_paired_says_already_paired(client, make_user):
    creator = await make_user()
    me = await make_user()
    my_partner = await make_user()
    await pair(me, my_partner)
    code = (await client.post("/pairing/create", headers=auth(creator))).json()["code"]

    assert await _join_error(client, me, code) == "already_paired"


async def test_join_when_the_creator_is_already_paired_says_partner_already_paired(client, make_user):
    creator = await make_user()
    code = (await client.post("/pairing/create", headers=auth(creator))).json()["code"]
    await pair(creator, await make_user())

    joiner = await make_user()
    assert await _join_error(client, joiner, code) == "partner_already_paired"


async def _join_and_read_dates(client, creator, joiner):
    code = (await client.post("/pairing/create", headers=auth(creator))).json()["code"]
    await client.post("/pairing/join", headers=auth(joiner), json={"code": code})
    return (await reload(creator)).anniversary, (await reload(joiner)).anniversary


async def test_join_keeps_the_creators_date_when_both_gave_one(client, make_user):
    creator = await make_user(anniversary=date(2022, 5, 1))
    joiner = await make_user(anniversary=date(2023, 9, 9))
    assert await _join_and_read_dates(client, creator, joiner) == (date(2022, 5, 1), date(2022, 5, 1))


async def test_join_uses_the_joiners_date_when_the_creator_skipped(client, make_user):
    creator = await make_user()
    joiner = await make_user(anniversary=date(2023, 9, 9))
    assert await _join_and_read_dates(client, creator, joiner) == (date(2023, 9, 9), date(2023, 9, 9))


async def test_join_leaves_no_date_when_neither_gave_one(client, make_user):
    creator = await make_user()
    joiner = await make_user()
    assert await _join_and_read_dates(client, creator, joiner) == (None, None)


# --- POST /pairing/unpair ---

async def test_unpair_clears_both_partners_and_the_couple_date_and_pushes_the_partner(client, make_user, apns):
    mina = await make_user(anniversary=date(2022, 5, 1))
    jamie = await make_user(anniversary=date(2022, 5, 1), apns_token="jamie-phone")
    await pair(mina, jamie)

    response = await client.post("/pairing/unpair", headers=auth(mina))
    assert response.json() == {"unpaired": True}
    for user in [await reload(mina), await reload(jamie)]:
        assert user.partner_id is None
        assert user.anniversary is None
    assert apns.sent == ["jamie-phone"]


async def test_unpair_when_not_paired_changes_nothing(client, make_user, apns):
    user = await make_user()
    response = await client.post("/pairing/unpair", headers=auth(user))
    assert response.json()["unpaired"] is False
    assert apns.sent == []
