from fastapi import FastAPI
from sqlalchemy import text
from database import engine
from routers import auth_routes, location, pairing

app = FastAPI()

@app.get("/health")
async def health_check():
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "ok", "db": "connected"}

app.include_router(auth_routes.router)
app.include_router(location.router)
app.include_router(pairing.router)
