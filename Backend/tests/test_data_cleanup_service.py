from datetime import datetime, timedelta, timezone

from app.core.Enum import UserRole
from app.models.CleanupAuditLogEntity import CleanupAuditLog
from app.models.MessageEntity import Message
from app.models.UserEntity import User
from app.services.DataCleanupService import DataCleanupService


FIXED_NOW = datetime(2026, 7, 23, 15, 0, tzinfo=timezone.utc)


def create_user(db, user_id: int, role: UserRole = UserRole.client) -> User:
    user = User(
        id_usuario=user_id,
        nombre=f"User{user_id}",
        apellido="Cleanup",
        telefono=f"300000{user_id:04d}",
        cedula=f"900000{user_id}",
        correo=f"user{user_id}@example.com",
        password_hash="hash",
        rol=role,
    )
    db.add(user)
    db.commit()
    return user


def create_message(db, message_id: int, sender_id: int, receiver_id: int, timestamp: datetime):
    message = Message(
        id=message_id,
        sender_id=sender_id,
        receiver_id=receiver_id,
        content=f"Mensaje {message_id}",
        timestamp=timestamp,
        is_read=False,
    )
    db.add(message)
    db.commit()
    return message


def test_cleanup_old_chat_messages_deletes_only_messages_older_than_retention(db):
    sender = create_user(db, 1, UserRole.client)
    receiver = create_user(db, 2, UserRole.admin)
    old_message = create_message(
        db,
        1,
        sender.id_usuario,
        receiver.id_usuario,
        FIXED_NOW - timedelta(days=31),
    )
    boundary_message = create_message(
        db,
        2,
        sender.id_usuario,
        receiver.id_usuario,
        FIXED_NOW - timedelta(days=30),
    )
    recent_message = create_message(
        db,
        3,
        sender.id_usuario,
        receiver.id_usuario,
        FIXED_NOW - timedelta(days=1),
    )
    old_message_id = old_message.id
    old_message_content_length = len(old_message.content)
    boundary_message_id = boundary_message.id
    recent_message_id = recent_message.id

    result = DataCleanupService.cleanup_old_chat_messages(
        db,
        now=FIXED_NOW,
        batch_size=2,
    )

    assert result.evaluated == 1
    assert result.deleted == 1
    assert db.get(Message, old_message_id) is None
    assert db.get(Message, boundary_message_id) is not None
    assert db.get(Message, recent_message_id) is not None

    audit = db.query(CleanupAuditLog).one()
    assert audit.job_name == DataCleanupService.OLD_MESSAGES_JOB
    assert audit.entity_name == "messages"
    assert audit.entity_id == str(old_message_id)
    assert audit.metadata_json["sender_id"] == sender.id_usuario
    assert audit.metadata_json["receiver_id"] == receiver.id_usuario
    assert audit.metadata_json["content_length"] == old_message_content_length
    assert "content" not in audit.metadata_json


def test_cleanup_old_chat_messages_runs_in_batches_and_is_idempotent(db):
    sender = create_user(db, 1, UserRole.client)
    receiver = create_user(db, 2, UserRole.admin)
    for message_id in range(1, 6):
        create_message(
            db,
            message_id,
            sender.id_usuario,
            receiver.id_usuario,
            FIXED_NOW - timedelta(days=31, minutes=message_id),
        )

    first_result = DataCleanupService.cleanup_old_chat_messages(
        db,
        now=FIXED_NOW,
        batch_size=2,
    )
    second_result = DataCleanupService.cleanup_old_chat_messages(
        db,
        now=FIXED_NOW,
        batch_size=2,
    )

    assert first_result.evaluated == 5
    assert first_result.deleted == 5
    assert second_result.evaluated == 0
    assert second_result.deleted == 0
    assert db.query(Message).count() == 0
    assert db.query(CleanupAuditLog).count() == 5
