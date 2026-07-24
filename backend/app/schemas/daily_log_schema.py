from pydantic import BaseModel, Field

class DailyLogRequest(BaseModel):
    pain_level: int = Field(..., ge=0, le=10, description="Pain level must be between 0 and 10")
    dryness_level: int = Field(..., ge=0, le=10, description="Dryness level must be between 0 and 10")
    smoking_count: int = Field(..., ge=0, description="Smoking count must be non-negative")
    water_intake: int = Field(..., ge=0, description="Water intake must be non-negative")
    notes: str | None = None
