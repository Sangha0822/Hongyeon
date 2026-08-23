from fastapi import FastAPI
from pydantic import BaseModel
import os
from dotenv import load_dotenv
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

load_dotenv()
engine = create_async_engine(os.environ["DATABASE_URL"])

app = FastAPI()

@app.get("/health")
async def health_check():
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "ok", "db": "connected"}

class Location(BaseModel):
    lat: float
    lng: float

latest_location: dict = {}

@app.post("/location")
def post_location(location: Location):
    latest_location["lat"] = location.lat
    latest_location["lng"] = location.lng
    return {"status": "received"}

@app.get("/location")
def get_location():
    return latest_location