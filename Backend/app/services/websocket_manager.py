from typing import Dict, Set
from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        # Maps each user_id to all active WebSocket connections for multi-device support.
        self.active_connections: Dict[int, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        self.active_connections.setdefault(user_id, set()).add(websocket)

    def disconnect(self, user_id: int, websocket: WebSocket | None = None):
        if user_id not in self.active_connections:
            return

        if websocket is None:
            del self.active_connections[user_id]
            return

        self.active_connections[user_id].discard(websocket)
        if not self.active_connections[user_id]:
            del self.active_connections[user_id]

    def is_user_online(self, user_id: int) -> bool:
        return bool(self.active_connections.get(user_id))

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
