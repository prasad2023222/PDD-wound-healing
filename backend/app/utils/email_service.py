import smtplib
from email.message import EmailMessage

from app.config import EMAIL_HOST, EMAIL_PORT, EMAIL_USERNAME, EMAIL_PASSWORD


def send_otp_email(to_email: str, otp: str):

    message = EmailMessage()

    message["Subject"] = "Oral Health AI Password Reset OTP"
    message["From"] = EMAIL_USERNAME
    message["To"] = to_email

    message.set_content(
        f"""
Hello,

Your password reset OTP is:

{otp}

This OTP is valid for 10 minutes.

If you did not request this, please ignore this email.

Oral Health AI Team
"""
    )

    with smtplib.SMTP(EMAIL_HOST, EMAIL_PORT) as server:
        server.starttls()
        server.login(EMAIL_USERNAME, EMAIL_PASSWORD)
        server.send_message(message)