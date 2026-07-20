import logging

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    UniqueConstraint,
    event,
    inspect,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.base import Base

logger = logging.getLogger("app.services.NotificationService")


def truncate_fcm_token(token: str | None, *, visible_chars: int = 24) -> str:
    if not token:
        return "<sin-token>"

    safe_length = min(visible_chars, max(len(token) - 1, 0))
    return f"{token[:safe_length]}..."


class DeviceToken(Base):
    __tablename__ = "device_tokens"
    __table_args__ = (
        UniqueConstraint("user_id", "device_id", name="uq_device_tokens_user_device"),
        UniqueConstraint("fcm_token", name="uq_device_tokens_fcm_token"),
        Index("ix_device_tokens_user_active", "user_id", "is_active"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("usuarios.id_usuario", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    device_id = Column(String(128), nullable=False)
    fcm_token = Column(String(512), nullable=False)
    platform = Column(String(32), nullable=True)
    app_version = Column(String(32), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    last_seen_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user = relationship("User")


def _log_token_received(device_token: DeviceToken) -> None:
    logger.info(
        "FCM: Token recibido para usuario %s. Token: %s",
        device_token.user_id,
        truncate_fcm_token(device_token.fcm_token),
    )


@event.listens_for(DeviceToken, "after_insert")
def _log_token_insert(mapper, connection, target: DeviceToken) -> None:
    _log_token_received(target)


@event.listens_for(DeviceToken, "after_update")
def _log_token_update(mapper, connection, target: DeviceToken) -> None:
    token_history = inspect(target).attrs.fcm_token.history
    if token_history.has_changes():
        _log_token_received(target)
