from fastapi import FastAPI
from pydantic import BaseModel
import os
from dotenv import load_dotenv
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import async_sessionmaker
from models import LocationState

load_dotenv()
engine = create_async_engine(os.environ["DATABASE_URL"])

app = FastAPI()

@app.get("/health")
async def health_check():
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "ok", "db": "connected"}


async_session = async_sessionmaker(engine)
FIXED_USER_ID = "me"

class Location(BaseModel):
    lat: float
    lng: float

@app.post("/location")
async def post_location(location: Location):
    async with async_session() as session:
        state = await session.get(LocationState, FIXED_USER_ID)
        if state is None:
            state = LocationState(user_id=FIXED_USER_ID)
            session.add(state)
        state.lat = location.lat
        state.lng = location.lng
        state.updated_at = datetime.now(timezone.utc)
        await session.commit()
    return {"status": "received"}

@app.get("/location")
async def get_location():
    async with async_session() as session:
        state = await session.get(LocationState, FIXED_USER_ID)
        if state is None:
            return {}
        return {"lat": state.lat, "lng": state.lng, "updated_at": state.updated_at}
