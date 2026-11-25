import uuid
from datetime import datetime, timedelta, timezone

import jwt
from sqlalchemy import func, select

import auth as auth_module
from database import async_session
from models import User
from routers import auth_routes
from helpers import auth


async def test_missing_token_is_rejected(client):
    response = await client.get("/me")
    assert response.status_code == 401


async def test_garbage_token_is_rejected(client):
    response = await client.get("/me", headers={"Authorization": "Bearer not-a-real-token"})
    assert response.status_code == 401


async def test_expired_token_is_rejected(client, make_user):
    user = await make_user()
    expired = jwt.encode(
        {"sub": str(user.id), "exp": datetime.now(timezone.utc) - timedelta(minutes=1)},
        auth_module.JWT_SECRET_KEY,
        algorithm="HS256",
    )
    response = await client.get("/me", headers={"Authorization": f"Bearer {expired}"})
    assert response.status_code == 401


async def test_token_signed_with_another_secret_is_rejected(client, make_user):
    user = await make_user()
    forged = jwt.encode(
        {"sub": str(user.id), "exp": datetime.now(timezone.utc) + timedelta(days=1)},
        "some-other-secret-that-an-attacker-might-try",
        algorithm="HS256",
    )
    response = await client.get("/me", headers={"Authorization": f"Bearer {forged}"})
    assert response.status_code == 401


async def test_token_for_a_deleted_account_is_rejected(client):
    ghost = User(id=uuid.uuid4())
    response = await client.get("/me", headers=auth(ghost))
    assert response.status_code == 401


async def _count_users():
    async with async_session() as session:
        return await session.scalar(select(func.count()).select_from(User))


async def test_apple_sign_in_creates_the_account_once(client, monkeypatch):
    # The real check downloads Apple's public keys; here Apple "says" who the user is.
    monkeypatch.setattr(auth_routes, "verify_apple_identity_token",
                        lambda token: {"provider_subject": "apple-user-1", "email": "a@example.com"})

    first = await client.post("/auth/apple", json={"identity_token": "anything"})
    second = await client.post("/auth/apple", json={"identity_token": "anything"})
    assert first.status_code == second.status_code == 200
    assert await _count_users() == 1

    me_first = (await client.get("/me", headers={"Authorization": f"Bearer {first.json()['token']}"})).json()
    me_second = (await client.get("/me", headers={"Authorization": f"Bearer {second.json()['token']}"})).json()
    assert me_first["id"] == me_second["id"]
    assert me_first["auth_provider"] == "apple"
    assert me_first["email"] == "a@example.com"


async def test_google_sign_in_creates_a_google_account(client, monkeypatch):
    monkeypatch.setattr(auth_routes, "verify_google_identity_token",
                        lambda token: {"provider_subject": "google-user-1", "email": "g@example.com"})

    response = await client.post("/auth/google", json={"identity_token": "anything"})
    me = (await client.get("/me", headers={"Authorization": f"Bearer {response.json()['token']}"})).json()
    assert me["auth_provider"] == "google"
    assert me["paired"] is False
