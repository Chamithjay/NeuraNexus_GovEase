from typing import Dict, Set
from fastapi import WebSocket
from collections import defaultdict
import asyncio

class WebSocketManager:
    """Tracks active WebSocket connections by citizen_id and broadcasts messages."""

    def __init__(self) -> None:
        self._connections: Dict[str, Set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(self, citizen_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._connections[citizen_id].add(websocket)

    async def disconnect(self, citizen_id: str, websocket: WebSocket) -> None:
        async with self._lock:
            conns = self._connections.get(citizen_id)
            if conns and websocket in conns:
                conns.remove(websocket)
                if not conns:
                    self._connections.pop(citizen_id, None)

    async def send_to(self, citizen_id: str, message: dict) -> None:
        async with self._lock:
            conns = list(self._connections.get(citizen_id, []))
        dead: list[WebSocket] = []
        for ws in conns:
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        if dead:
            async with self._lock:
                for ws in dead:
                    for cid, set_ in list(self._connections.items()):
                        if ws in set_:
                            set_.remove(ws)
                            if not set_:
                                self._connections.pop(cid, None)

manager = WebSocketManager()
