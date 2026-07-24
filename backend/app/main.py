import logging
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# 1. Initialize Logging Configuration
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger("app")

from app.database import engine, Base

# 2. Conditionally Create Tables in Development Only
ENV = os.getenv("ENV", "development")
if ENV == "development":
    logger.info("Development environment detected. Initializing database schema...")
    Base.metadata.create_all(bind=engine)

from app.models.user_model import User
from app.models.scan_model import Scan
from app.models.daily_log_model import DailyLog
from app.models.reminder_model import Reminder

from app.routes.auth_routes import router as auth_router
from app.routes.image_routes import router as image_router
from app.routes.daily_log_routes import router as daily_log_router
from app.routes.insights_routes import router as insights_router
from app.routes.reminder_routes import router as reminder_router
from app.routes.report_routes import router as report_router
from app.models.password_reset_model import PasswordResetOTP


app = FastAPI(
    title="Oral Health AI Backend",
    version="1.0.0"
)

# 3. Configure Restrictive CORS Origins
allowed_origins = os.getenv("ALLOWED_ORIGINS", "").split(",")
allowed_origins = [origin.strip() for origin in allowed_origins if origin.strip()]
if not allowed_origins or "*" in allowed_origins:
    logger.warning("Wildcard CORS detected/fallback active. Setting specific local domains for credentials security.")
    allowed_origins = ["http://localhost:8080", "http://127.0.0.1:8080", "http://localhost:3000"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.mount(
    "/uploads",
    StaticFiles(directory="uploads"),
    name="uploads"
)


app.include_router(auth_router)
app.include_router(image_router)
app.include_router(daily_log_router)
app.include_router(insights_router)
app.include_router(reminder_router)
app.include_router(report_router)


@app.get("/")
def root():
    return {
        "message": "Backend connected successfully",
        "status": "running",
        "version": "1.0.0"
    }