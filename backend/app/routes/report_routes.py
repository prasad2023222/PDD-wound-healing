from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user_model import User
from app.models.scan_model import Scan
from app.models.daily_log_model import DailyLog
from app.utils.oauth2 import get_current_user

router = APIRouter()


@router.get("/report-summary")
def report_summary(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(
        User.id == current_user["user_id"]
    ).first()

    latest_scan = db.query(Scan).filter(
        Scan.user_id == current_user["user_id"]
    ).order_by(
        Scan.created_at.desc()
    ).first()

    latest_log = db.query(DailyLog).filter(
        DailyLog.user_id == current_user["user_id"]
    ).order_by(
        DailyLog.created_at.desc()
    ).first()

    total_scans = db.query(Scan).filter(
        Scan.user_id == current_user["user_id"]
    ).count()

    total_logs = db.query(DailyLog).filter(
        DailyLog.user_id == current_user["user_id"]
    ).count()

    if not latest_scan:
        return {
            "message": "No scan data available",
            "user": {
                "full_name": user.full_name if user else "User",
                "email": user.email if user else ""
            },
            "summary": "Upload your first oral scan to generate a report.",
            "total_scans": total_scans,
            "total_logs": total_logs,
            "latest_scan": None,
            "latest_log": None,
            "recommendations": [
                "Upload an oral image",
                "Start daily symptom tracking"
            ]
        }

    risk_level = "Low"

    if latest_scan.severity.lower() == "medium":
        risk_level = "Moderate"
    elif latest_scan.severity.lower() == "high":
        risk_level = "High"

    if latest_log:
        if latest_log.pain_level >= 7 or latest_log.dryness_level >= 7:
            risk_level = "High"
        elif latest_log.pain_level >= 4 or latest_log.dryness_level >= 4:
            risk_level = "Moderate"

    recommendations = [
        "Maintain oral hygiene",
        "Drink enough water",
        "Avoid smoking during recovery",
        "Consult a dentist if symptoms persist"
    ]

    return {
        "message": "Report generated successfully",
        "user": {
            "full_name": user.full_name if user else "User",
            "email": user.email if user else ""
        },
        "summary": "This report is generated from your latest scan, daily symptoms, and recovery activity.",
        "risk_level": risk_level,
        "total_scans": total_scans,
        "total_logs": total_logs,
        "latest_scan": {
            "condition": latest_scan.condition,
            "confidence": latest_scan.confidence,
            "severity": latest_scan.severity,
            "image_url": latest_scan.image_url,
            "created_at": latest_scan.created_at
        },
        "latest_log": {
            "pain_level": latest_log.pain_level if latest_log else None,
            "dryness_level": latest_log.dryness_level if latest_log else None,
            "smoking_count": latest_log.smoking_count if latest_log else None,
            "water_intake": latest_log.water_intake if latest_log else None,
            "notes": latest_log.notes if latest_log else None,
            "created_at": latest_log.created_at if latest_log else None
        },
        "recommendations": recommendations
    }