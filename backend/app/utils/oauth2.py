from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

from app.config import SECRET_KEY, ALGORITHM

from app.database import SessionLocal
from app.models.user_model import User

security = HTTPBearer()


def verify_access_token(token: str):

    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )

        email = payload.get("sub")
        user_id = payload.get("user_id")

        if email is None or user_id is None:
            raise HTTPException(
                status_code=401,
                detail="Invalid token"
            )

        return {
            "email": email,
            "user_id": user_id
        }

    except JWTError:
        raise HTTPException(
            status_code=401,
            detail="Token is invalid or expired"
        )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    token = credentials.credentials
    token_data = verify_access_token(token)

    db = SessionLocal()
    try:
        db_user = db.query(User).filter(User.id == token_data["user_id"]).first()
        if not db_user:
            raise HTTPException(
                status_code=401,
                detail="User account does not exist or has been deleted"
            )
        return token_data
    finally:
        db.close()