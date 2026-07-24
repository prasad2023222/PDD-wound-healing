import os
import uuid
import json
import anyio

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.scan_model import Scan
from app.utils.oauth2 import get_current_user
from app.utils.ai_service import analyze_palate_image

router = APIRouter()

UPLOAD_DIR = "uploads"

os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_EXTENSIONS = ["jpg", "jpeg", "png", "webp"]


def safe_int(value, default=0):
    try:
        return int(value)
    except Exception:
        return default


def safe_json_list(value):
    if isinstance(value, list):
        return json.dumps(value)

    if isinstance(value, str):
        return json.dumps([value])

    return json.dumps([])


def parse_json_list(value):
    try:
        return json.loads(value or "[]")
    except Exception:
        return []


@router.post("/upload-image")
async def upload_image(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 1. Enforce backend file size limit (5MB) pre-read
    MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
    try:
        file.file.seek(0, 2)
        size = file.file.tell()
        file.file.seek(0)
        if size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=413,
                detail="File size exceeds maximum limit of 5MB"
            )
    except HTTPException:
        raise
    except Exception:
        pass  # Fallback to len check post-read if seek fails

    # 2. Validate MIME type
    if file.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(
            status_code=400,
            detail="Only JPG, JPEG, PNG, and WEBP images are allowed"
        )

    file_extension = file.filename.split(".")[-1].lower()

    if file_extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail="Only JPG, JPEG, PNG, and WEBP images are allowed"
        )

    unique_filename = f"{uuid.uuid4()}.{file_extension}"

    file_path = os.path.join(
        UPLOAD_DIR,
        unique_filename
    )

    with open(file_path, "wb") as buffer:
        content = await file.read()
        
        # Enforce file size limit post-read check
        if len(content) > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=413,
                detail="File size exceeds maximum limit of 5MB"
            )
            
        # 3. Validate image magic bytes/signatures
        magic_bytes = content[:4]
        is_png = magic_bytes.startswith(b"\x89PNG")
        is_jpeg = magic_bytes.startswith(b"\xff\xd8\xff")
        is_webp = magic_bytes.startswith(b"RIFF")
        
        if not (is_png or is_jpeg or is_webp):
            raise HTTPException(
                status_code=400,
                detail="Invalid image signature. The file is not a valid image."
            )
            
        buffer.write(content)

    IMAGE_BASE_URL = os.getenv("IMAGE_BASE_URL", "http://127.0.0.1:8000")
    image_url = f"{IMAGE_BASE_URL}/uploads/{unique_filename}"

    previous_scan = db.query(Scan).filter(
        Scan.user_id == current_user["user_id"]
    ).order_by(
        Scan.created_at.desc()
    ).first()

    previous_image_path = None
    previous_analysis = None

    if previous_scan:
        previous_image_path = os.path.join(
            UPLOAD_DIR,
            previous_scan.filename
        )

        previous_analysis = {
            "condition": previous_scan.condition,
            "confidence": previous_scan.confidence,
            "severity": previous_scan.severity,
            "healing_score": previous_scan.healing_score,
            "progress_status": previous_scan.progress_status,
            "improvement_percentage": previous_scan.improvement_percentage,
            "predicted_recovery_days": previous_scan.predicted_recovery_days,
            "risk_alert": previous_scan.risk_alert,
            "coaching_tip": previous_scan.coaching_tip,
            "summary": previous_scan.summary,
            "observations": parse_json_list(previous_scan.observations),
            "recommendations": parse_json_list(previous_scan.recommendations),
        }

    # 4. Offload the blocking Ollama vision call to a worker thread
    prediction = await anyio.to_thread.run_sync(
        analyze_palate_image,
        file_path,
        previous_image_path,
        previous_analysis
    )

    recommendations_list = prediction.get("recommendations", [])
    observations_list = prediction.get("observations", [])

    recommendation_text = " ".join(
        [str(item) for item in recommendations_list]
    )

    new_scan = Scan(
        user_id=current_user["user_id"],
        filename=unique_filename,
        image_url=image_url,

        condition=prediction.get(
            "condition",
            "Unclear"
        ),
        confidence=safe_int(
            prediction.get("confidence", 0)
        ),
        severity=prediction.get(
            "severity",
            "Unclear"
        ),

        healing_score=safe_int(
            prediction.get("healing_score", 0)
        ),
        progress_status=prediction.get(
            "progress_status",
            "Unclear"
        ),

        improvement_percentage=safe_int(
            prediction.get("improvement_percentage", 0)
        ),
        predicted_recovery_days=prediction.get(
            "predicted_recovery_days"
        ),

        risk_alert=prediction.get("risk_alert"),
        coaching_tip=prediction.get("coaching_tip"),

        summary=prediction.get("summary"),

        observations=safe_json_list(observations_list),
        recommendations=safe_json_list(recommendations_list),
    )

    try:
        db.add(new_scan)
        db.commit()
        db.refresh(new_scan)
    except Exception:
        db.rollback()
        # Clean up the uploaded file if database write fails
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(
            status_code=500,
            detail="Failed to save image analysis to database"
        )

    return {
        "message": "Image uploaded and analyzed successfully",
        "scan_id": new_scan.id,
        "user_id": current_user["user_id"],
        "filename": unique_filename,
        "file_path": file_path,
        "image_url": image_url,
        "prediction": {
            "condition": new_scan.condition,
            "confidence": new_scan.confidence,
            "severity": new_scan.severity,

            "healing_score": new_scan.healing_score,
            "progress_status": new_scan.progress_status,

            "improvement_percentage": new_scan.improvement_percentage,
            "predicted_recovery_days": new_scan.predicted_recovery_days,

            "risk_alert": new_scan.risk_alert,
            "coaching_tip": new_scan.coaching_tip,

            "summary": new_scan.summary,

            "observations": observations_list,
            "recommendations": recommendations_list,
        }
    }


@router.get("/my-scans")
def get_my_scans(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    scans = db.query(Scan).filter(
        Scan.user_id == current_user["user_id"]
    ).order_by(
        Scan.created_at.desc()
    ).all()

    results = []

    for scan in scans:

        observations = parse_json_list(scan.observations)
        recommendations = parse_json_list(scan.recommendations)

        results.append({
            "scan_id": scan.id,
            "image_url": scan.image_url,

            "condition": scan.condition,
            "confidence": scan.confidence,
            "severity": scan.severity,

            "healing_score": scan.healing_score,
            "progress_status": scan.progress_status,

            "improvement_percentage": scan.improvement_percentage,
            "predicted_recovery_days": scan.predicted_recovery_days,

            "risk_alert": scan.risk_alert,
            "coaching_tip": scan.coaching_tip,

            "summary": scan.summary,

            "observations": observations,
            "recommendations": recommendations,

            "created_at": scan.created_at
        })

    return {
        "total_scans": len(results),
        "scans": results
    }