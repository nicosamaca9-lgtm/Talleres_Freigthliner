import asyncio
import logging
import threading
from enum import Enum
from typing import Iterable

from fastapi import BackgroundTasks
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.integrations import firebase_client
from app.models.DeviceTokenEntity import DeviceToken, truncate_fcm_token

logger = logging.getLogger(__name__)


class NotificationType(str, Enum):
    new_message = "new_message"
    order_assigned = "order_assigned"
    order_ready = "order_ready"


class NotificationService:
    @staticmethod
    def notify(
        *,
        db: Session | None = None,
        user_ids: list[int],
        type: NotificationType,
        title: str,
        body: str,
        data: dict,
        background_tasks: BackgroundTasks | None = None,
        exclude_device_ids: Iterable[str] | None = None,
    ) -> None:
        unique_user_ids = sorted({int(user_id) for user_id in user_ids if user_id})
        payload_data = NotificationService._build_data_payload(type=type, data=data)
        excluded_devices = sorted(set(exclude_device_ids or []))

        if background_tasks is not None:
            background_tasks.add_task(
                NotificationService._send_notification_job,
                user_ids=unique_user_ids,
                title=title,
                body=body,
                data=payload_data,
                exclude_device_ids=excluded_devices,
            )
            return

        NotificationService._schedule_async_job(
            user_ids=unique_user_ids,
            title=title,
            body=body,
            data=payload_data,
            exclude_device_ids=excluded_devices,
        )

    @staticmethod
    def _build_data_payload(*, type: NotificationType, data: dict) -> dict[str, str]:
        payload = {"type": type.value}
        for key, value in data.items():
            if value is None:
                continue
            payload[str(key)] = str(value)
        return payload

    @staticmethod
    def _schedule_async_job(
        *,
        user_ids: list[int],
        title: str,
        body: str,
        data: dict[str, str],
        exclude_device_ids: list[str],
    ) -> None:
        coroutine = NotificationService._send_notification_job(
            user_ids=user_ids,
            title=title,
            body=body,
            data=data,
            exclude_device_ids=exclude_device_ids,
        )

        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            threading.Thread(
                target=lambda: asyncio.run(coroutine),
                daemon=True,
            ).start()
            return

        loop.create_task(coroutine)

    @staticmethod
    async def _send_notification_job(
        *,
        user_ids: list[int],
        title: str,
        body: str,
        data: dict[str, str],
        exclude_device_ids: list[str],
    ) -> None:
        if not user_ids:
            return

        total_success = 0
        total_failure = 0
        should_log_summary = False
        db = SessionLocal()
        try:
            targets = NotificationService._load_target_tokens(
                db,
                user_ids=user_ids,
                exclude_device_ids=exclude_device_ids,
            )
            tokens_by_user = NotificationService._tokens_by_user(targets)
            for user_id in user_ids:
                logger.info(
                    "FCM: Preparando envío para usuario %s (%s dispositivo/s). Mensaje: '%s'",
                    user_id,
                    len(tokens_by_user.get(user_id, [])),
                    body,
                )

            should_log_summary = True
            tokens = [target.fcm_token for target in targets]
            if not tokens:
                return

            for token in tokens:
                logger.debug(
                    "Enviando Push al token: %s | Contenido: %s",
                    truncate_fcm_token(token),
                    body,
                )

            for batch in NotificationService._chunks(tokens, size=500):
                result = await firebase_client.send_multicast_notification(
                    tokens=batch,
                    title=title,
                    body=body,
                    data=data,
                )
                total_success += result.success_count
                total_failure += result.failure_count
                if result.invalid_tokens:
                    NotificationService._delete_invalid_tokens(db, result.invalid_tokens)
        except Exception:
            logger.exception("Error sending notification batch")
        finally:
            db.close()
            if should_log_summary:
                logger.info(
                    "Notificación masiva procesada. Éxito: %s, Fallos: %s",
                    total_success,
                    total_failure,
                )

    @staticmethod
    def _load_target_tokens(
        db: Session,
        *,
        user_ids: list[int],
        exclude_device_ids: list[str],
    ) -> list[DeviceToken]:
        query = db.query(DeviceToken).filter(
            DeviceToken.user_id.in_(user_ids),
            DeviceToken.is_active.is_(True),
        )
        if exclude_device_ids:
            query = query.filter(DeviceToken.device_id.notin_(exclude_device_ids))

        rows = query.order_by(DeviceToken.id).all()
        return rows

    @staticmethod
    def _tokens_by_user(targets: list[DeviceToken]) -> dict[int, list[str]]:
        tokens_by_user: dict[int, list[str]] = {}
        for target in targets:
            tokens_by_user.setdefault(target.user_id, []).append(target.fcm_token)
        return tokens_by_user

    @staticmethod
    def _delete_invalid_tokens(db: Session, invalid_tokens: list[str]) -> None:
        if not invalid_tokens:
            return

        db.query(DeviceToken).filter(DeviceToken.fcm_token.in_(invalid_tokens)).delete(
            synchronize_session=False
        )
        db.commit()

    @staticmethod
    def _chunks(values: list[str], *, size: int) -> Iterable[list[str]]:
        for index in range(0, len(values), size):
            yield values[index : index + size]
