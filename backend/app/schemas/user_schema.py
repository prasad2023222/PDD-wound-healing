from pydantic import BaseModel, EmailStr, Field


class UserSignup(BaseModel):
    full_name: str
    email: EmailStr
    password: str = Field(..., min_length=8, description="Password must be at least 8 characters")

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")
    new_password: str = Field(..., min_length=8, description="Password must be at least 8 characters")

class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None