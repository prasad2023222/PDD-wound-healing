from pydantic import BaseModel, Field

class ReminderRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=50, description="Title must be between 1 and 50 characters")
    reminder_type: str = Field(..., min_length=1, description="Reminder type cannot be empty")
    time: str = Field(..., min_length=1, description="Time cannot be empty")
