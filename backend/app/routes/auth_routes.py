from datetime import datetime, timedelta
import random

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session

from app.database import get_db

from app.models.user_model import User
from app.models.password_reset_model import PasswordResetOTP

from app.schemas.user_schema import UserSignup, LoginRequest, ForgotPasswordRequest, ResetPasswordRequest, UpdateProfileRequest

from app.utils.security import (
    hash_password,
    verify_password,
    create_access_token
)

from app.utils.oauth2 import get_current_user
from app.utils.email_service import send_otp_email

router = APIRouter()


@router.post("/signup")
def signup(user: UserSignup, db: Session = Depends(get_db)):

    existing_user = db.query(User).filter(
        User.email == user.email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    new_user = User(
        full_name=user.full_name,
        email=user.email,
        password_hash=hash_password(user.password)
    )

    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Failed to register user due to database error"
        )

    return {
        "message": "User created successfully",
        "user_id": new_user.id
    }


@router.post("/login")
def login(user: LoginRequest, db: Session = Depends(get_db)):

    db_user = db.query(User).filter(
        User.email == user.email
    ).first()

    if not db_user:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    if not verify_password(
        user.password,
        db_user.password_hash
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    access_token = create_access_token(
        data={
            "sub": db_user.email,
            "user_id": db_user.id
        }
    )

    return {
        "message": "Login successful",
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": db_user.id,
        "full_name": db_user.full_name,
        "email": db_user.email
    }


@router.get("/profile")
def profile(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    db_user = db.query(User).filter(
        User.id == current_user["user_id"]
    ).first()

    if not db_user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    return {
        "message": "Profile accessed successfully",
        "user": {
            "id": db_user.id,
            "full_name": db_user.full_name,
            "email": db_user.email,
            "created_at": db_user.created_at
        }
    }


@router.post("/forgot-password")
def forgot_password(
    data: ForgotPasswordRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):

    email = data.email

    user = db.query(User).filter(
        User.email == email
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    otp = str(random.randint(100000, 999999))

    try:
        db.query(PasswordResetOTP).filter(
            PasswordResetOTP.email == email
        ).delete()

        otp_entry = PasswordResetOTP(
            email=email,
            otp=otp
        )

        db.add(otp_entry)
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Failed to store password reset OTP due to database error"
        )

    background_tasks.add_task(send_otp_email, email, otp)

    return {
        "message": "OTP sent successfully"
    }


@router.post("/reset-password")
def reset_password(
    data: ResetPasswordRequest,
    db: Session = Depends(get_db)
):

    email = data.email
    otp = data.otp
    new_password = data.new_password

    otp_entry = db.query(PasswordResetOTP).filter(
        PasswordResetOTP.email == email,
        PasswordResetOTP.otp == otp
    ).first()

    if not otp_entry:
        raise HTTPException(
            status_code=400,
            detail="Invalid OTP"
        )

    current_time = datetime.utcnow()
    created_time = otp_entry.created_at.replace(tzinfo=None)

    if current_time - created_time > timedelta(minutes=10):
        raise HTTPException(
            status_code=400,
            detail="OTP expired"
        )

    user = db.query(User).filter(
        User.email == email
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    user.password_hash = hash_password(new_password)

    try:
        db.commit()
        db.delete(otp_entry)
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Failed to complete password reset due to database error"
        )

    return {
        "message": "Password reset successful"
    }


@router.put("/update-profile")
def update_profile(
    data: UpdateProfileRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    user = db.query(User).filter(
        User.id == current_user["user_id"]
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    full_name = data.full_name
    email = data.email

    if full_name:
        user.full_name = full_name

    if email:
        existing_email = db.query(User).filter(
            User.email == email,
            User.id != user.id
        ).first()

        if existing_email:
            raise HTTPException(
                status_code=400,
                detail="Email already in use"
            )

        user.email = email

    try:
        db.commit()
        db.refresh(user)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Failed to update profile due to database error"
        )

    return {
        "message": "Profile updated successfully",
        "user": {
            "id": user.id,
            "full_name": user.full_name,
            "email": user.email
        }
    }