from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.reminder_model import Reminder
from app.schemas.reminder_schema import ReminderRequest
from app.utils.oauth2 import get_current_user

router = APIRouter()


@router.post("/reminders")
def create_reminder(
    data: ReminderRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    new_reminder = Reminder(
        user_id=current_user["user_id"],
        title=data.title,
        reminder_type=data.reminder_type,
        time=data.time,
        is_active=True
    )

    try:
        db.add(new_reminder)
        db.commit()
        db.refresh(new_reminder)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Failed to create reminder due to database error"
        )

    return {
        "message": "Reminder created successfully",
        "reminder_id": new_reminder.id
    }


@router.get("/reminders")
def get_my_reminders(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    reminders = db.query(Reminder).filter(
        Reminder.user_id == current_user["user_id"]
    ).order_by(Reminder.created_at.desc()).all()

    return {
        "total_reminders": len(reminders),
        "reminders": [
            {
                "id": reminder.id,
                "title": reminder.title,
                "reminder_type": reminder.reminder_type,
                "time": reminder.time,
                "is_active": reminder.is_active,
                "created_at": reminder.created_at
            }
            for reminder in reminders
        ]
    }


@router.put("/reminders/{reminder_id}/toggle")
def toggle_reminder(
    reminder_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    reminder = db.query(Reminder).filter(
        Reminder.id == reminder_id,
        Reminder.user_id == current_user["user_id"]
    ).first()

    if not reminder:
        raise HTTPException(
            status_code=404,
            detail="Reminder not found"
        )

    reminder.is_active = not reminder.is_active

    try:
        db.commit()
        db.refresh(reminder)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Failed to toggle reminder status due to database error"
        )

    return {
        "message": "Reminder status updated",
        "reminder_id": reminder.id,
        "is_active": reminder.is_active
    }


@router.delete("/reminders/{reminder_id}")
def delete_reminder(
    reminder_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    reminder = db.query(Reminder).filter(
        Reminder.id == reminder_id,
        Reminder.user_id == current_user["user_id"]
    ).first()

    if not reminder:
        raise HTTPException(
            status_code=404,
            detail="Reminder not found"
        )

    try:
        db.delete(reminder)
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Failed to delete reminder due to database error"
        )

    return {
        "message": "Reminder deleted successfully",
        "reminder_id": reminder_id
    }