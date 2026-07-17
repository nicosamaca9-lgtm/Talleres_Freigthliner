from datetime import datetime, timezone

import pytest

from app.api.v1.endpoints import ChatEndpoint
from app.core.Enum import UserRole
from app.models.MessageEntity import Message
from tests.conftest import create_message, create_user


class SpyConnectionManager:
    def __init__(self):
        self.sent = []

    async def send_personal_json(self, data: dict, user_id: int) -> bool:
        self.sent.append((user_id, data))
        return True


@pytest.fixture()
def spy_manager(monkeypatch):
    spy = SpyConnectionManager()
    monkeypatch.setattr(ChatEndpoint, "manager", spy)
    return spy


def test_message_payload_exposes_derived_statuses(db):
    sender = create_user(db, 1, UserRole.admin, "admin")
    receiver = create_user(db, 2, UserRole.client, "client")

    sent = create_message(db, sender, receiver, "sent")
    delivered = create_message(db, sender, receiver, "delivered")
    delivered.delivered_at = datetime.now(timezone.utc)
    read = create_message(db, sender, receiver, "read")
    read.delivered_at = datetime.now(timezone.utc)
    read.is_read = True
    read.read_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(delivered)
    db.refresh(read)

    assert ChatEndpoint._serialize_message_payload(sent)["status"] == "sent"
    delivered_payload = ChatEndpoint._serialize_message_payload(delivered)
    assert delivered_payload["status"] == "delivered"
    assert delivered_payload["delivered_at"] == delivered.delivered_at.isoformat()
    read_payload = ChatEndpoint._serialize_message_payload(read)
    assert read_payload["status"] == "read"
    assert read_payload["read_at"] == read.read_at.isoformat()


@pytest.mark.asyncio
async def test_ws_delivery_sets_delivered_at_and_notifies_sender(db, spy_manager):
    sender = create_user(db, 1, UserRole.admin, "admin")
    receiver = create_user(db, 2, UserRole.client, "client")
    message = create_message(db, sender, receiver)

    payload = await ChatEndpoint._finalize_delivery_state(message.id, delivered=True)

    db.expire_all()
    stored = db.get(Message, message.id)
    assert stored.delivered_at is not None
    assert payload["status"] == "delivered"
    assert payload["delivered_at"] == stored.delivered_at.isoformat()
    assert spy_manager.sent == [
        (
            sender.id_usuario,
            {
                "type": "message_delivered",
                "message_id": message.id,
                "receiver_id": receiver.id_usuario,
                "delivered_at": stored.delivered_at.isoformat(),
            },
        )
    ]


@pytest.mark.asyncio
async def test_offline_receiver_keeps_message_sent(db, spy_manager):
    sender = create_user(db, 1, UserRole.admin, "admin")
    receiver = create_user(db, 2, UserRole.client, "client")
    message = create_message(db, sender, receiver)

    payload = await ChatEndpoint._finalize_delivery_state(message.id, delivered=False)

    db.expire_all()
    stored = db.get(Message, message.id)
    assert stored.delivered_at is None
    assert payload["status"] == "sent"
    assert payload["delivered_at"] is None
    assert spy_manager.sent == []
