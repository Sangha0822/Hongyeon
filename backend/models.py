from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import Float, DateTime
from datetime import datetime
import uuid
from sqlalchemy import String, ForeignKey, Uuid
from sqlalchemy.orm import Mapped, mapped_column


class Base(DeclarativeBase):
    pass

class LocationState(Base):
    __tablename__ = "location_states"

    user_id: Mapped[str] = mapped_column(primary_key=True)
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

class PairingCode(Base):
    __tablename__ = "pairing_codes"
    code: Mapped[str] = mapped_column(String, primary_key = True)
    creator_id: Mapped[uuid.UUID] = mapped_column(Uuid,ForeignKey("users.id"))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

