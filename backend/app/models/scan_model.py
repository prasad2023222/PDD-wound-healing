from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    ForeignKey,
    Text
)

from sqlalchemy.sql import func

from app.database import Base


class Scan(Base):
    __tablename__ = "scans"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True
    )

    filename = Column(String, nullable=False)

    image_url = Column(String, nullable=False)

    condition = Column(String, nullable=False)

    confidence = Column(Integer, nullable=False)

    severity = Column(String, nullable=False)

    healing_score = Column(Integer, default=0)

    progress_status = Column(String, default="First scan")

    improvement_percentage = Column(Integer, default=0)

    predicted_recovery_days = Column(Integer, nullable=True)

    risk_alert = Column(Text, nullable=True)

    coaching_tip = Column(Text, nullable=True)

    summary = Column(Text, nullable=True)

    observations = Column(Text, nullable=True)

    recommendations = Column(Text, nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )