from datetime import datetime

from pydantic import BaseModel, Field


class DeviceTokenRegisterRequest(BaseModel):
    device_id: str = Field(..., min_length=1, max_length=128)
    fcm_token: str = Field(..., min_length=1, max_length=512)
    platform: str | None = Field(default="android", max_length=32)
    app_version: str | None = Field(default=None, max_length=32)


class DeviceTokenResponse(BaseModel):
    id: int
    user_id: int
    device_id: str
    platform: str | None = None
    app_version: str | None = None
    is_active: bool
    last_seen_at: datetime | None = None

    class Config:
        from_attributes = True
