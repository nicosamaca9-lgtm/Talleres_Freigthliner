import logging
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any

from sqlalchemy.orm import Query, Session

from app.models.CleanupAuditLogEntity import CleanupAuditLog
from app.models.MessageEntity import Message

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class CleanupJobResult:
    job_name: str
    evaluated: int
    deleted: int


class DataCleanupService:
    DEFAULT_BATCH_SIZE = 500
    DEFAULT_RETENTION_DAYS = 30

    OLD_MESSAGES_JOB = "cleanup_old_chat_messages"

    @classmethod
    def cleanup_old_chat_messages(
        cls,
        db: Session,
        *,
        now: datetime | None = None,
        retention_days: int = DEFAULT_RETENTION_DAYS,
        batch_size: int = DEFAULT_BATCH_SIZE,
    ) -> CleanupJobResult:
        cutoff = cls._cutoff(now=now, retention_days=retention_days)
        batch_size = cls._validated_batch_size(batch_size)
        evaluated = 0
        deleted = 0

        logger.info(
            "Limpieza automatica de mensajes iniciada. Evaluados: 0. "
            "Eliminados: 0. Cutoff: %s",
            cutoff.isoformat(),
        )

        try:
            while True:
                message_ids = cls._old_message_ids(db, cutoff=cutoff, batch_size=batch_size)
                if not message_ids:
                    break

                evaluated += len(message_ids)
                deleted += cls._delete_message_batch(db, message_ids, cutoff=cutoff)

                if len(message_ids) < batch_size:
                    break

        except Exception:
            db.rollback()
            logger.exception("Error ejecutando limpieza automatica de mensajes.")
            raise

        logger.info(
            "Limpieza automatica de mensajes finalizada. Evaluados: %s. Eliminados: %s",
            evaluated,
            deleted,
        )
        return CleanupJobResult(cls.OLD_MESSAGES_JOB, evaluated, deleted)

    @classmethod
    def _old_message_ids(
        cls,
        db: Session,
        *,
        cutoff: datetime,
        batch_size: int,
    ) -> list[int]:
        query = (
            db.query(Message.id)
            .filter(Message.timestamp < cutoff)
            .order_by(Message.timestamp.asc(), Message.id.asc())
            .limit(batch_size)
        )
        query = cls._with_postgres_skip_locked(db, query)
        return [message_id for (message_id,) in query.all()]

    @classmethod
    def _delete_message_batch(
        cls,
        db: Session,
        message_ids: list[int],
        *,
        cutoff: datetime,
    ) -> int:
        messages = db.query(Message).filter(Message.id.in_(message_ids)).all()
        for message in messages:
            db.add(
                cls._audit_log(
                    job_name=cls.OLD_MESSAGES_JOB,
                    entity_name="messages",
                    entity_id=message.id,
                    reason="message_older_than_retention",
                    cutoff=cutoff,
                    metadata={
                        "sender_id": message.sender_id,
                        "receiver_id": message.receiver_id,
                        "timestamp": cls._datetime_to_iso(message.timestamp),
                        "is_read": message.is_read,
                        "content_length": len(message.content or ""),
                    },
                )
            )

        deleted = (
            db.query(Message)
            .filter(Message.id.in_(message_ids))
            .delete(synchronize_session=False)
        )
        db.commit()
        return int(deleted)

    @staticmethod
    def _cutoff(*, now: datetime | None, retention_days: int) -> datetime:
        current_time = now or datetime.now(timezone.utc)
        if current_time.tzinfo is None:
            current_time = current_time.replace(tzinfo=timezone.utc)
        else:
            current_time = current_time.astimezone(timezone.utc)
        return current_time - timedelta(days=retention_days)

    @staticmethod
    def _validated_batch_size(batch_size: int) -> int:
        if batch_size < 1:
            raise ValueError("El batch_size debe ser mayor o igual a 1")
        return batch_size

    @staticmethod
    def _with_postgres_skip_locked(db: Session, query: Query) -> Query:
        bind = db.get_bind()
        if bind.dialect.name == "postgresql":
            return query.with_for_update(skip_locked=True)
        return query

    @staticmethod
    def _audit_log(
        *,
        job_name: str,
        entity_name: str,
        entity_id: int,
        reason: str,
        cutoff: datetime,
        metadata: dict[str, Any],
    ) -> CleanupAuditLog:
        return CleanupAuditLog(
            job_name=job_name,
            entity_name=entity_name,
            entity_id=str(entity_id),
            reason=reason,
            cutoff_at=cutoff,
            metadata_json=metadata,
        )

    @staticmethod
    def _datetime_to_iso(value: datetime | None) -> str | None:
        return value.isoformat() if value else None
