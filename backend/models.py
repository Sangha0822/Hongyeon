from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import Float, DateTime, Date
from datetime import datetime, date
import uuid
from sqlalchemy import String, ForeignKey, Uuid
from sqlalchemy.orm import Mapped, mapped_column


class Base(DeclarativeBase):
    pass

class LocationState(Base):
    __tablename__ = "location_states"

    user_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id"), primary_key=True)
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

class User(Base):
    __tablename__ = "users"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key = True, default = uuid.uuid4)
    auth_provider: Mapped[str] = mapped_column(String)
    provider_subject: Mapped[str] = mapped_column(String, unique=True)
    email: Mapped[str | None] = mapped_column(String, nullable = True)
    partner_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, ForeignKey("users.id"), nullable = True)
    apns_token: Mapped[str | None] = mapped_column(String, nullable=True)
    display_name: Mapped[str | None] = mapped_column(String(20), nullable=True)
    # A calendar day with no time zone, so both partners read the same date wherever they are.
    # Before pairing it is this person's own answer; pairing writes the couple's date to both rows.
    anniversary: Mapped[date | None] = mapped_column(Date, nullable=True)

class PairingCode(Base):
    __tablename__ = "pairing_codes"
    code: Mapped[str] = mapped_column(String, primary_key = True)
    creator_id: Mapped[uuid.UUID] = mapped_column(Uuid,ForeignKey("users.id"))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

