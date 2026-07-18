import inspect

import pytest

from app.api.v1.endpoints import ChatEndpoint
from app.core.Enum import UserRole
from app.integrations import firebase_client
from app.models.DeviceTokenEntity import DeviceToken
from app.services.NotificationService import NotificationService, NotificationType
from app.services.websocket_manager import ConnectionManager
from tests.conftest import create_user


class FakeBackgroundTasks:
    def __init__(self):
        self.tasks = []

    def add_task(self, func, *args, **kwargs):
        self.tasks.append((func, args, kwargs))


async def run_background_task(task):
    func, args, kwargs = task
    result = func(*args, **kwargs)
    if inspect.isawaitable(result):
        await result


def add_device_token(db, *, user_id: int, token: str, device_id: str):
    device_token = DeviceToken(
        user_id=user_id,
        device_id=device_id,
        fcm_token=token,
        platform="android",
        is_active=True,
    )
    db.add(device_token)
    db.commit()
    db.refresh(device_token)
    return device_token


def test_new_message_notification_targets_receiver_regardless_of_role(
    db,
    monkeypatch,
):
    admin = create_user(db, 1, UserRole.admin, "admin")
    client = create_user(db, 2, UserRole.client, "client")
    mechanic = create_user(db, 3, UserRole.mechanic, "mechanic")
    secretary = create_user(db, 4, UserRole.secretary, "secretary")
    calls = []

    def fake_notify(**kwargs):
        calls.append(kwargs)

    monkeypatch.setattr(NotificationService, "notify", fake_notify)

    for receiver in [client, mechanic, secretary]:
        ChatEndpoint._queue_new_message_notification(
            sender_id=admin.id_usuario,
            sender_role=admin.rol.value,
            recipient_ids=[receiver.id_usuario],
            message_id=100 + receiver.id_usuario,
        )

    ChatEndpoint._queue_new_message_notification(
        sender_id=client.id_usuario,
        sender_role=client.rol.value,
        recipient_ids=[admin.id_usuario],
        message_id=200,
    )

    assert [call["user_ids"] for call in calls] == [[2], [3], [4], [1]]
    assert all(call["type"] == NotificationType.new_message for call in calls)
    assert all(call["data"]["type"] == "new_message" for call in calls)


@pytest.mark.asyncio
async def test_open_chat_device_is_excluded_but_other_device_is_notified(
    db,
    monkeypatch,
):
    sender = create_user(db, 1, UserRole.admin, "admin")
    receiver = create_user(db, 2, UserRole.client, "client")
    add_device_token(
        db,
        user_id=receiver.id_usuario,
        token="open-device-token",
        device_id="phone-open",
    )
    add_device_token(
        db,
        user_id=receiver.id_usuario,
        token="closed-device-token",
        device_id="phone-closed",
    )
    manager = ConnectionManager()
    manager.mark_chat_opened(
        user_id=receiver.id_usuario,
        device_id="phone-open",
        contact_id="admin",
    )
    monkeypatch.setattr(ChatEndpoint, "manager", manager)
    calls = []

    async def fake_send_multicast_notification(*, tokens, title, body, data):
        calls.append({"tokens": tokens, "data": data})
        return firebase_client.FirebaseMulticastResult(
            success_count=len(tokens),
            failure_count=0,
            invalid_tokens=[],
        )

    monkeypatch.setattr(
        firebase_client,
        "send_multicast_notification",
        fake_send_multicast_notification,
    )

    background_tasks = FakeBackgroundTasks()
    ChatEndpoint._queue_new_message_notification(
        sender_id=sender.id_usuario,
        sender_role=sender.rol.value,
        recipient_ids=[receiver.id_usuario],
        message_id=10,
        background_tasks=background_tasks,
    )

    assert len(background_tasks.tasks) == 1
    await run_background_task(background_tasks.tasks[0])

    assert calls == [
        {
            "tokens": ["closed-device-token"],
            "data": {
                "type": "new_message",
                "chat_id": "dm:1:2",
                "contact_id": "1",
                "message_id": "10",
            },
        }
    ]


@pytest.mark.asyncio
async def test_chat_presence_events_update_device_active_chat(monkeypatch):
    manager = ConnectionManager()
    monkeypatch.setattr(ChatEndpoint, "manager", manager)

    await ChatEndpoint._handle_chat_presence_event(
        message_data={"type": "chat_opened", "contact_id": "admin"},
        user_id=2,
        device_id="phone-1",
    )

    assert manager.devices_with_open_chat(2, ["admin"]) == ["phone-1"]

    await ChatEndpoint._handle_chat_presence_event(
        message_data={"type": "chat_closed"},
        user_id=2,
        device_id="phone-1",
    )

    assert manager.devices_with_open_chat(2, ["admin"]) == []


def test_new_message_notification_accepts_multiple_recipients_and_no_others(
    db,
    monkeypatch,
):
    sender = create_user(db, 1, UserRole.admin, "admin")
    client = create_user(db, 2, UserRole.client, "client")
    mechanic = create_user(db, 3, UserRole.mechanic, "mechanic")
    create_user(db, 4, UserRole.secretary, "observer")
    calls = []

    def fake_notify(**kwargs):
        calls.append(kwargs)

    monkeypatch.setattr(NotificationService, "notify", fake_notify)

    ChatEndpoint._queue_new_message_notification(
        sender_id=sender.id_usuario,
        sender_role=sender.rol.value,
        recipient_ids=[client.id_usuario, mechanic.id_usuario],
        message_id=10,
    )

    assert len(calls) == 1
    assert calls[0]["user_ids"] == [client.id_usuario, mechanic.id_usuario]
    assert calls[0]["data"]["chat_id"] == "dm:1:2"
    assert calls[0]["data"]["message_id"] == "10"
