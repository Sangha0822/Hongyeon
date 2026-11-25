import os

# Set before the app is imported: database.py and auth.py read these at import time,
# and load_dotenv() never overrides a variable that is already set.
TEST_DATABASE_URL = os.environ.get("TEST_DATABASE_URL", "postgresql+asyncpg://localhost/hongyeon_test")
if not TEST_DATABASE_URL.rsplit("/", 1)[-1].endswith("_test"):
    # Every test run empties every table, so never point it at a real database.
    raise RuntimeError("Refusing to run: the test database's name must end in _test")
os.environ["DATABASE_URL"] = TEST_DATABASE_URL
os.environ["JWT_SECRET_KEY"] = "test-only-jwt-secret-never-used-outside-tests"

from types import SimpleNamespace

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text

import push
from database import async_session, engine
from main import app
from models import Base, User


@pytest_asyncio.fixture(scope="session", autouse=True)
async def database_schema():
    """Builds the tables from models.py once per run."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


@pytest_asyncio.fixture(autouse=True)
async def empty_tables():
    """Empties every table after each test, so no test sees another's rows."""
    yield
    tables = ", ".join(table.name for table in Base.metadata.sorted_tables)
    async with engine.begin() as conn:
        await conn.execute(text(f"TRUNCATE {tables} CASCADE"))


class FakeAPNs:
    """Stands in for Apple's push service: records each push and answers as told."""

    def __init__(self):
        self.sent = []          # device tokens, in the order they were pushed
        self.answer = "Success"  # or "BadDeviceToken", "Unregistered", or an exception to raise

    async def send_notification(self, request):
        self.sent.append(request.device_token)
        if isinstance(self.answer, Exception):
            raise self.answer
        ok = self.answer == "Success"
        return SimpleNamespace(is_successful=ok, description=None if ok else self.answer)


@pytest.fixture(autouse=True)
def apns(monkeypatch):
    """Every test gets the fake, so no test can ever send a real push."""
    fake = FakeAPNs()
    monkeypatch.setattr(push, "get_apns_client", lambda: fake)
    return fake


@pytest_asyncio.fixture
async def client():
    """Sends requests straight into the FastAPI app, with no server or network."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client


@pytest.fixture
def make_user():
    """Creates a user row directly, skipping Apple/Google sign-in."""
    count = 0

    async def _make_user(name=None, anniversary=None, apns_token=None, provider="apple"):
        nonlocal count
        count += 1
        async with async_session() as session:
            user = User(
                auth_provider=provider,
                provider_subject=f"test-subject-{count}",
                display_name=name,
                anniversary=anniversary,
                apns_token=apns_token,
            )
            session.add(user)
            await session.commit()
        return user

    return _make_user
