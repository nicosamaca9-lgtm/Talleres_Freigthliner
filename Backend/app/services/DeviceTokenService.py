from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.DeviceTokenEntity import DeviceToken
from app.schemas.DeviceTokenSchema import DeviceTokenRegisterRequest


class DeviceTokenService:
    @staticmethod
    def register_token(
        db: Session,
        *,
        user_id: int,
        data: DeviceTokenRegisterRequest,
    ) -> DeviceToken:
        now = datetime.now(timezone.utc)
        existing_device = (
            db.query(DeviceToken)
            .filter(
                DeviceToken.user_id == user_id,
                DeviceToken.device_id == data.device_id,
            )
            .first()
        )
        existing_token = (
            db.query(DeviceToken)
            .filter(DeviceToken.fcm_token == data.fcm_token)
            .first()
        )

        if existing_device and existing_token and existing_device.id != existing_token.id:
            db.delete(existing_token)
            db.flush()
            existing_token = None

        if existing_device:
            device_token = existing_device
        elif existing_token:
            device_token = existing_token
            device_token.user_id = user_id
            device_token.device_id = data.device_id
        else:
            device_token = DeviceToken(
                user_id=user_id,
                device_id=data.device_id,
                fcm_token=data.fcm_token,
            )
            db.add(device_token)

        device_token.fcm_token = data.fcm_token
        device_token.platform = data.platform or "android"
        device_token.app_version = data.app_version
        device_token.is_active = True
        device_token.last_seen_at = now

        db.commit()
        db.refresh(device_token)
        return device_token

    @staticmethod
    def deactivate_token(
        db: Session,
        *,
        user_id: int,
        device_id: str,
    ) -> bool:
        device_token = (
            db.query(DeviceToken)
            .filter(
                DeviceToken.user_id == user_id,
                DeviceToken.device_id == device_id,
            )
            .first()
        )
        if not device_token:
            return False

        device_token.is_active = False
        device_token.last_seen_at = datetime.now(timezone.utc)
        db.commit()
        return True
