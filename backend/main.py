from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

@app.get("/health")
def health_check():
    return {"status": "ok"}

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