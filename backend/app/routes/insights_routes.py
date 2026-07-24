from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.scan_model import Scan
from app.models.daily_log_model import DailyLog
from app.utils.oauth2 import get_current_user

router = APIRouter()


@router.get("/insights")
def get_insights(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    scans = db.query(Scan).filter(
        Scan.user_id == current_user["user_id"]
    ).order_by(
        Scan.created_at.desc()
    ).all()

    logs = db.query(DailyLog).filter(
        DailyLog.user_id == current_user["user_id"]
    ).order_by(
        DailyLog.created_at.desc()
    ).all()

    if not scans and not logs:
        return {
            "healing_status": "No data yet",
            "risk_level": "Unknown",
            "summary": "Upload an oral image and add daily logs to generate insights.",
            "recommendations": [
                "Upload your first oral scan",
                "Start tracking daily symptoms"
            ]
        }

    latest_scan = scans[0] if scans else None
    latest_log = logs[0] if logs else None

    risk_score = 0
    recommendations = []

    if latest_scan:
        if latest_scan.severity.lower() == "low":
            risk_score += 1
        elif latest_scan.severity.lower() == "medium":
            risk_score += 2
        else:
            risk_score += 3

    if latest_log:
        if latest_log.pain_level >= 7:
            risk_score += 3
            recommendations.append("Pain level is high. Consider consulting a dentist.")
        elif latest_log.pain_level >= 4:
            risk_score += 2
            recommendations.append("Monitor pain levels for the next few days.")

        if latest_log.dryness_level >= 6:
            risk_score += 2
            recommendations.append("Increase water intake to reduce dryness.")

        if latest_log.smoking_count > 0:
            risk_score += 2
            recommendations.append("Avoid smoking because it can slow oral healing.")

        if latest_log.water_intake <= 1:
            risk_score += 2
            recommendations.append("Drink more water to support recovery.")

    if risk_score <= 2:
        risk_level = "Low"
        healing_status = "Improving"
    elif risk_score <= 5:
        risk_level = "Moderate"
        healing_status = "Needs Monitoring"
    else:
        risk_level = "High"
        healing_status = "Consult Recommended"

    if not recommendations:
        recommendations = [
            "Maintain good oral hygiene",
            "Continue hydration",
            "Keep tracking your progress"
        ]

    summary = "Your insights are generated from your latest scan and daily symptom log."

    return {
        "healing_status": healing_status,
        "risk_level": risk_level,
        "summary": summary,
        "latest_scan": {
            "condition": latest_scan.condition if latest_scan else None,
            "confidence": latest_scan.confidence if latest_scan else None,
            "severity": latest_scan.severity if latest_scan else None
        },
        "latest_log": {
            "pain_level": latest_log.pain_level if latest_log else None,
            "dryness_level": latest_log.dryness_level if latest_log else None,
            "smoking_count": latest_log.smoking_count if latest_log else None,
            "water_intake": latest_log.water_intake if latest_log else None
        },
        "recommendations": recommendations
    }