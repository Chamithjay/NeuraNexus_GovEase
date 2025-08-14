from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from realtime.websocket_manager import manager

ws_router = APIRouter()


@ws_router.websocket("/ws/notifications")
async def websocket_notifications(websocket: WebSocket, citizen_id: str = Query(...)):
    await manager.connect(citizen_id, websocket)
    try:
        while True:
            # Keep the connection alive and optionally receive pings
            await websocket.receive_text()
    except WebSocketDisconnect:
        await manager.disconnect(citizen_id, websocket)
