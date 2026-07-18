import inspect

import pytest

from app.core.Enum import UserRole
from app.integrations import firebase_client
from app.models.DeviceTokenEntity import DeviceToken
from app.services.NotificationService import NotificationService, NotificationType
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


@pytest.mark.asyncio
async def test_notify_batches_multiple_user_tokens_in_one_firebase_call(
    db,
    monkeypatch,
):
    user = create_user(db, 1, UserRole.client, "client")
    add_device_token(db, user_id=user.id_usuario, token="token-a", device_id="phone-a")
    add_device_token(db, user_id=user.id_usuario, token="token-b", device_id="phone-b")
    calls = []

    async def fake_send_multicast_notification(*, tokens, title, body, data):
        calls.append(
            {
                "tokens": tokens,
                "title": title,
                "body": body,
                "data": data,
            }
        )
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
    NotificationService.notify(
        db=db,
        user_ids=[user.id_usuario],
        type=NotificationType.new_message,
        title="Nuevo mensaje",
        body="Tienes un mensaje nuevo",
        data={"chat_id": "dm:1:2"},
        background_tasks=background_tasks,
    )

    assert calls == []
    assert len(background_tasks.tasks) == 1

    await run_background_task(background_tasks.tasks[0])

    assert calls == [
        {
            "tokens": ["token-a", "token-b"],
            "title": "Nuevo mensaje",
            "body": "Tienes un mensaje nuevo",
            "data": {"type": "new_message", "chat_id": "dm:1:2"},
        }
    ]


@pytest.mark.asyncio
async def test_invalid_firebase_tokens_are_deleted_after_send(db, monkeypatch):
    user = create_user(db, 1, UserRole.client, "client")
    add_device_token(db, user_id=user.id_usuario, token="valid-token", device_id="phone-a")
    add_device_token(db, user_id=user.id_usuario, token="invalid-token", device_id="phone-b")

    async def fake_send_multicast_notification(*, tokens, title, body, data):
        return firebase_client.FirebaseMulticastResult(
            success_count=1,
            failure_count=1,
            invalid_tokens=["invalid-token"],
        )

    monkeypatch.setattr(
        firebase_client,
        "send_multicast_notification",
        fake_send_multicast_notification,
    )

    background_tasks = FakeBackgroundTasks()
    NotificationService.notify(
        db=db,
        user_ids=[user.id_usuario],
        type=NotificationType.new_message,
        title="Nuevo mensaje",
        body="Tienes un mensaje nuevo",
        data={"chat_id": "dm:1:2"},
        background_tasks=background_tasks,
    )

    await run_background_task(background_tasks.tasks[0])

    assert (
        db.query(DeviceToken).filter(DeviceToken.fcm_token == "invalid-token").first()
        is None
    )
    assert (
        db.query(DeviceToken).filter(DeviceToken.fcm_token == "valid-token").first()
        is not None
    )


@pytest.mark.asyncio
async def test_user_without_registered_tokens_does_not_break_notification_flow(
    db,
    monkeypatch,
):
    user = create_user(db, 1, UserRole.client, "client")
    calls = []

    async def fake_send_multicast_notification(*, tokens, title, body, data):
        calls.append(tokens)
        return firebase_client.FirebaseMulticastResult(
            success_count=0,
            failure_count=0,
            invalid_tokens=[],
        )

    monkeypatch.setattr(
        firebase_client,
        "send_multicast_notification",
        fake_send_multicast_notification,
    )

    background_tasks = FakeBackgroundTasks()
    NotificationService.notify(
        db=db,
        user_ids=[user.id_usuario],
        type=NotificationType.order_assigned,
        title="Orden asignada",
        body="Tienes una orden asignada",
        data={"order_id": "10"},
        background_tasks=background_tasks,
    )

    assert len(background_tasks.tasks) == 1

    await run_background_task(background_tasks.tasks[0])

    assert calls == []


def test_notify_schedules_background_work_without_calling_firebase_immediately(
    db,
    monkeypatch,
):
    user = create_user(db, 1, UserRole.client, "client")
    add_device_token(db, user_id=user.id_usuario, token="token-a", device_id="phone-a")
    calls = []

    async def fake_send_multicast_notification(*, tokens, title, body, data):
        calls.append(tokens)
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
    NotificationService.notify(
        db=db,
        user_ids=[user.id_usuario],
        type=NotificationType.order_ready,
        title="Orden lista",
        body="Tu vehiculo esta listo",
        data={"order_id": "10"},
        background_tasks=background_tasks,
    )

    assert calls == []
    assert len(background_tasks.tasks) == 1
