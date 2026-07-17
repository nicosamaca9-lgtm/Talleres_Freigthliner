from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends, HTTPException, status
from typing import Optional, List
import asyncio
import json
import logging
from datetime import datetime, timezone
from time import time
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc

from app.core.security import decode_access_token
from app.api.v1.deps import get_current_user
from app.core.Enum import UserRole
from app.db.session import SessionLocal, get_db
from app.models.MessageEntity import Message
from app.models.UserEntity import User
from app.services.websocket_manager import manager
from app.integrations.firebase_client import send_push_notification

router = APIRouter()
logger = logging.getLogger(__name__)


def _serialize_read_receipt(message: Message) -> dict:
    return {
        "id": message.id,
        "is_read": message.is_read,
        "read_at": message.read_at.isoformat() if message.read_at else None,
    }


def _message_status(message: Message) -> str:
    if message.is_read is True or message.read_at is not None:
        return "read"
    if message.delivered_at is not None:
        return "delivered"
    return "sent"


def _serialize_message_payload(message: Message) -> dict:
    return {
        "id": message.id,
        "sender_id": message.sender_id,
        "receiver_id": message.receiver_id,
        "content": message.content,
        "timestamp": message.timestamp.isoformat() if message.timestamp else None,
        "is_read": message.is_read,
        "delivered_at": message.delivered_at.isoformat() if message.delivered_at else None,
        "read_at": message.read_at.isoformat() if message.read_at else None,
        "status": _message_status(message),
    }


async def _finalize_delivery_state(message_id: int, delivered: bool) -> dict | None:
    with SessionLocal() as db:
        message = db.query(Message).filter(Message.id == message_id).first()
        if not message:
            return None

        newly_delivered = False
        if delivered and message.delivered_at is None:
            message.delivered_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(message)
            newly_delivered = True

        payload = _serialize_message_payload(message)

        if newly_delivered:
            await manager.send_personal_json(
                {
                    "type": "message_delivered",
                    "message_id": message.id,
                    "receiver_id": message.receiver_id,
                    "delivered_at": message.delivered_at.isoformat()
                    if message.delivered_at
                    else None,
                },
                message.sender_id
            )

        return payload


def _process_message_in_db(sender_id: int, sender_role: str, raw_receiver_id: any, content: str) -> dict:
    """
    Ejecuta toda la lógica de base de datos de forma síncrona.
    Maneja el caso donde receiver_id es "admin" y obtiene el ID real.
    """
    with SessionLocal() as db:
        receiver_id = None
        receiver_role = None

        if str(raw_receiver_id).lower() == "admin":
            # Buscar al primer administrador disponible
            admin_user = db.query(User).filter(User.rol == UserRole.admin).first()
            if not admin_user:
                return {"error": "No hay administradores disponibles en el sistema"}
            receiver_id = admin_user.id_usuario
            receiver_role = admin_user.rol.value
        else:
            try:
                receiver_id = int(raw_receiver_id)
            except ValueError:
                return {"error": "ID de destinatario inválido"}

            receiver = db.query(User).filter(User.id_usuario == receiver_id).first()
            if not receiver:
                return {"error": "Destinatario no encontrado"}
            receiver_role = receiver.rol.value

        # Prevenir auto-envío (luego de resolver "admin")
        if receiver_id == sender_id:
            return {"error": "No puedes enviarte mensajes a ti mismo"}

        # --- Validar Reglas de Comunicación ---
        if sender_role != UserRole.admin.value:
            if receiver_role != UserRole.admin.value:
                return {"error": "No tienes permisos para comunicarte con este usuario"}

        # Persistir el mensaje
        new_message = Message(
            sender_id=sender_id,
            receiver_id=receiver_id,
            content=content
        )
        db.add(new_message)
        db.commit()
        db.refresh(new_message)

        return {
            "ok": True,
            "payload": _serialize_message_payload(new_message),
            "actual_receiver_id": receiver_id
        }


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: Optional[str] = Query(None)
):
    if not token:
        await websocket.close(code=1008, reason="Missing token")
        return

    payload = decode_access_token(token)
    if not payload:
        await websocket.close(code=1008, reason="Invalid token")
        return

    user_id_str = payload.get("sub")
    sender_role = payload.get("role")

    if not user_id_str or not sender_role:
        await websocket.close(code=1008, reason="Invalid token payload")
        return

    try:
        sender_id = int(user_id_str)
    except ValueError:
        await websocket.close(code=1008, reason="Invalid user ID in token")
        return

    await manager.connect(websocket, sender_id)

    try:
        while True:
            data = await websocket.receive_text()

            # Rate Limiting
            now = time()
            last_msg_time = getattr(websocket, '_last_msg', 0)
            if now - last_msg_time < 0.5:
                await websocket.send_json({"error": "Demasiados mensajes, espera un momento"})
                continue
            websocket._last_msg = now

            try:
                message_data = json.loads(data)
            except json.JSONDecodeError:
                await websocket.send_json({"error": "Formato JSON inválido"})
                continue

            raw_receiver_id = message_data.get("receiver_id")
            content = message_data.get("content")

            if raw_receiver_id is None or not isinstance(content, str) or not content.strip():
                logger.debug("WS Error: Faltan campos obligatorios")
                await websocket.send_json({"error": "Faltan campos obligatorios (receiver_id, content)"})
                continue
            
            content = content.strip()
            logger.debug(f"WS Recibido: sender={sender_id}, receiver={raw_receiver_id}, content={content}")

            try:
                result = await asyncio.to_thread(
                    _process_message_in_db, sender_id, sender_role, raw_receiver_id, content
                )
                logger.debug(f"WS Guardado DB: result={result}")
            except Exception as db_e:
                logger.error(f"WS Error DB: {db_e}")
                await websocket.send_json({"error": f"Error interno: {db_e}"})
                continue

            if "error" in result:
                await websocket.send_json({"error": result["error"]})
                continue

            msg_payload = result["payload"]
            actual_receiver_id = result["actual_receiver_id"]

            sent_ws = await manager.send_personal_json(msg_payload, actual_receiver_id)
            delivery_payload = await _finalize_delivery_state(msg_payload["id"], delivered=sent_ws)
            if delivery_payload is not None:
                msg_payload = delivery_payload

            if not sent_ws:
                await send_push_notification(actual_receiver_id, content)

            # Echo: enviar confirmación al sender para que vea su propio mensaje
            await manager.send_personal_json(msg_payload, sender_id)

    except WebSocketDisconnect:
        manager.disconnect(sender_id, websocket)
        logger.info(f"User {sender_id} disconnected")
    except Exception as e:
        manager.disconnect(sender_id, websocket)
        logger.error(f"WebSocket error for user {sender_id}: {e}")


@router.patch("/messages/{message_id}/read")
async def mark_message_as_read(
    message_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    message = db.query(Message).filter(Message.id == message_id).first()
    if not message:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mensaje no encontrado")

    if message.receiver_id != current_user.id_usuario:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el receptor puede marcar este mensaje como leido"
        )

    was_already_read = message.is_read is True
    if not was_already_read:
        message.is_read = True
        message.read_at = datetime.now(timezone.utc)
        if message.delivered_at is None:
            message.delivered_at = message.read_at
        db.commit()
        db.refresh(message)

        await manager.send_personal_json(
            {
                "type": "message_read",
                "message_id": message.id,
                "reader_id": current_user.id_usuario,
                "read_at": message.read_at.isoformat() if message.read_at else None,
            },
            message.sender_id
        )

    return _serialize_read_receipt(message)


@router.get("/history/{contact_id}")
def get_chat_history(
    contact_id: str,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obtiene el historial de chat paginado.
    Si contact_id es 'admin', devuelve el historial con CUALQUIER administrador.
    """
    if contact_id.lower() == "admin":
        admin_ids = [u.id_usuario for u in db.query(User).filter(User.rol == UserRole.admin).all()]
        if not admin_ids:
            raise HTTPException(status_code=404, detail="No hay administradores en el sistema")
        
        messages = db.query(Message).filter(
            or_(
                (Message.sender_id == current_user.id_usuario) & (Message.receiver_id.in_(admin_ids)),
                (Message.sender_id.in_(admin_ids)) & (Message.receiver_id == current_user.id_usuario)
            )
        ).order_by(desc(Message.timestamp)).offset(skip).limit(limit).all()
    else:
        try:
            actual_contact_id = int(contact_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="ID de contacto inválido")

        # Validar permisos: si el current_user no es admin, solo puede hablar con el admin.
        if current_user.rol != UserRole.admin:
            contact_user = db.query(User).filter(User.id_usuario == actual_contact_id).first()
            if not contact_user or contact_user.rol != UserRole.admin:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Solo puedes ver el historial con administradores."
                )

        messages = db.query(Message).filter(
            or_(
                (Message.sender_id == current_user.id_usuario) & (Message.receiver_id == actual_contact_id),
                (Message.sender_id == actual_contact_id) & (Message.receiver_id == current_user.id_usuario)
            )
        ).order_by(desc(Message.timestamp)).offset(skip).limit(limit).all()

    # Retornar los mensajes en el formato esperado (ascendente para la UI si es necesario,
    # aunque normalmente la UI los ordena. Aquí los enviamos en orden descendente por fecha
    # y la UI los puede renderizar inversamente o revertirlos).
    return [
        _serialize_message_payload(msg)
        for msg in messages
    ]
