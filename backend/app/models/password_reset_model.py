from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime, timezone

from app.database import Base


class PasswordResetOTP(Base):

    __tablename__ = "password_reset_otps"

    id = Column(Integer, primary_key=True, index=True)

    email = Column(String, nullable=False)

    otp = Column(String, nullable=False)

    created_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc)
    )