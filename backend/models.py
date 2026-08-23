from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import Float, DateTime
from datetime import datetime

class Base(DeclarativeBase):
    pass

class LocationState(Base):
    __tablename__ = "location_states"

    user_id: Mapped[str] = mapped_column(primary_key=True)
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    updated_at: Mapped[datetime] = mapped_column(DateTime)
