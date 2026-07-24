from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.daily_log_model import DailyLog
from app.schemas.daily_log_schema import DailyLogRequest
from app.utils.oauth2 import get_current_user

router = APIRouter()


@router.post("/daily-log")
def create_daily_log(
    data: DailyLogRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    new_log = DailyLog(
        user_id=current_user["user_id"],
        pain_level=data.pain_level,
        dryness_level=data.dryness_level,
        smoking_count=data.smoking_count,
        water_intake=data.water_intake,
        notes=data.notes
    )

    try:
        db.add(new_log)
        db.commit()
        db.refresh(new_log)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Failed to save daily log due to database error"
        )

    return {
        "message": "Daily log saved successfully",
        "log_id": new_log.id
    }


@router.get("/my-daily-logs")
def get_my_daily_logs(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    logs = db.query(DailyLog).filter(
        DailyLog.user_id == current_user["user_id"]
    ).order_by(
        DailyLog.created_at.desc()
    ).all()

    results = []

    for log in logs:
        results.append({
            "id": log.id,
            "pain_level": log.pain_level,
            "dryness_level": log.dryness_level,
            "smoking_count": log.smoking_count,
            "water_intake": log.water_intake,
            "notes": log.notes,
            "created_at": log.created_at
        })

    return {
        "total_logs": len(results),
        "logs": results
    }