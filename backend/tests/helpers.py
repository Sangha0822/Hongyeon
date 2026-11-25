from auth import create_session_token
from database import async_session
from models import User


def auth(user):
    """Request headers signed in as this user."""
    return {"Authorization": f"Bearer {create_session_token(user.id)}"}


async def reload(user):
    """The user's row as it is in the database now."""
    async with async_session() as session:
        return await session.get(User, user.id)


async def pair(a, b):
    """Pairs two users directly, skipping the code flow."""
    async with async_session() as session:
        first = await session.get(User, a.id)
        second = await session.get(User, b.id)
        first.partner_id = second.id
        second.partner_id = first.id
        await session.commit()
