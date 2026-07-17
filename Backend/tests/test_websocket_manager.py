import pytest

from app.services.websocket_manager import ConnectionManager


class FakeWebSocket:
    def __init__(self, fail_on_send: bool = False):
        self.accepted = False
        self.sent_json = []
        self.fail_on_send = fail_on_send

    async def accept(self):
        self.accepted = True

    async def send_json(self, data: dict):
        if self.fail_on_send:
            raise RuntimeError("closed")
        self.sent_json.append(data)


@pytest.mark.asyncio
async def test_sends_to_all_active_connections_for_user():
    manager = ConnectionManager()
    first = FakeWebSocket()
    second = FakeWebSocket()

    await manager.connect(first, user_id=1)
    await manager.connect(second, user_id=1)

    sent = await manager.send_personal_json({"type": "ping"}, user_id=1)

    assert sent is True
    assert first.sent_json == [{"type": "ping"}]
    assert second.sent_json == [{"type": "ping"}]
    assert manager.is_user_online(1) is True


@pytest.mark.asyncio
async def test_disconnect_removes_only_that_websocket_instance():
    manager = ConnectionManager()
    first = FakeWebSocket()
    second = FakeWebSocket()

    await manager.connect(first, user_id=1)
    await manager.connect(second, user_id=1)

    manager.disconnect(1, first)
    await manager.send_personal_json({"type": "ping"}, user_id=1)

    assert first.sent_json == []
    assert second.sent_json == [{"type": "ping"}]
    assert manager.is_user_online(1) is True


@pytest.mark.asyncio
async def test_failed_connection_is_removed_without_affecting_healthy_connections():
    manager = ConnectionManager()
    failed = FakeWebSocket(fail_on_send=True)
    healthy = FakeWebSocket()

    await manager.connect(failed, user_id=1)
    await manager.connect(healthy, user_id=1)

    sent = await manager.send_personal_json({"type": "ping"}, user_id=1)
    await manager.send_personal_json({"type": "again"}, user_id=1)

    assert sent is True
    assert healthy.sent_json == [{"type": "ping"}, {"type": "again"}]
    assert manager.is_user_online(1) is True
