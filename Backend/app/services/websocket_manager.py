from typing import Dict, Iterable, Set
from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        # Maps each user_id to all active WebSocket connections for multi-device support.
        self.active_connections: Dict[int, Set[WebSocket]] = {}
        self._device_by_websocket: Dict[WebSocket, tuple[int, str]] = {}
        self._active_chat_by_device: Dict[tuple[int, str], str] = {}

    async def connect(self, websocket: WebSocket, user_id: int, device_id: str | None = None):
        await websocket.accept()
        self.active_connections.setdefault(user_id, set()).add(websocket)
        if device_id:
            self._device_by_websocket[websocket] = (user_id, device_id)

    def disconnect(self, user_id: int, websocket: WebSocket | None = None):
        if user_id not in self.active_connections:
            return

        if websocket is None:
            for device_key in list(self._active_chat_by_device):
                if device_key[0] == user_id:
                    del self._active_chat_by_device[device_key]
            for tracked_socket, device_key in list(self._device_by_websocket.items()):
                if device_key[0] == user_id:
                    del self._device_by_websocket[tracked_socket]
            del self.active_connections[user_id]
            return

        self.active_connections[user_id].discard(websocket)
        device_key = self._device_by_websocket.pop(websocket, None)
        if device_key is not None:
            self._active_chat_by_device.pop(device_key, None)
        if not self.active_connections[user_id]:
            del self.active_connections[user_id]

    def is_user_online(self, user_id: int) -> bool:
        return bool(self.active_connections.get(user_id))

    def mark_chat_opened(self, user_id: int, device_id: str, contact_id: object):
        self._active_chat_by_device[(user_id, device_id)] = str(contact_id).lower()

    def mark_chat_closed(self, user_id: int, device_id: str):
        self._active_chat_by_device.pop((user_id, device_id), None)

    def devices_with_open_chat(
        self,
        user_id: int,
        contact_ids: Iterable[object],
    ) -> list[str]:
        normalized_contacts = {str(contact_id).lower() for contact_id in contact_ids}
        return [
            device_id
            for (active_user_id, device_id), active_contact_id
            in self._active_chat_by_device.items()
            if active_user_id == user_id and active_contact_id in normalized_contacts
        ]

    async def send_personal_message(self, message: str, user_id: int) -> bool:
        """
        Sends a text message to all active user connections.
        Returns True if at least one connection received it.
        """
        connections = list(self.active_connections.get(user_id, set()))
        sent_any = False

        for websocket in connections:
            try:
                await websocket.send_text(message)
                sent_any = True
            except Exception:
                self.disconnect(user_id, websocket)

        return sent_any

    async def send_personal_json(self, data: dict, user_id: int) -> bool:
        connections = list(self.active_connections.get(user_id, set()))
        sent_any = False

        for websocket in connections:
            try:
                await websocket.send_json(data)
                sent_any = True
            except Exception:
                self.disconnect(user_id, websocket)

        return sent_any

# Global instance to be used across the app
manager = ConnectionManager()
