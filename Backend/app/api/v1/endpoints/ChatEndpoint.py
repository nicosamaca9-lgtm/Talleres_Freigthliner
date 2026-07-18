from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends, HTTPException, status
from typing import Optional, List
import asyncio
import json
import logging
from datetime import datetime, timezone
from time import time
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc, func

from app.core.security import decode_access_token
from app.api.v1.deps import get_current_user
from app.core.Enum import UserRole
from app.db.session import SessionLocal, get_db
from app.models.MessageEntity import Message
from app.models.UserEntity import User
from app.services.websocket_manager import manager
from app.services.NotificationService import NotificationService, NotificationType

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


def _unread_message_filter():
    return or_(Message.is_read.is_(False), Message.is_read.is_(None))


def _resolve_conversation_sender_ids(
    contact_id: str,
    current_user: User,
    db: Session,
) -> list[int]:
    if contact_id.lower() == "admin":
        admin_ids = [
            user.id_usuario
            for user in db.query(User).filter(User.rol == UserRole.admin).all()
        ]
        if not admin_ids:
            raise HTTPException(status_code=404, detail="No hay administradores en el sistema")
        return admin_ids

    try:
        actual_contact_id = int(contact_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="ID de contacto invalido")

    if current_user.rol != UserRole.admin:
        contact_user = db.query(User).filter(User.id_usuario == actual_contact_id).first()
        if not contact_user or contact_user.rol != UserRole.admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Solo puedes marcar conversaciones con administradores.",
            )

    return [actual_contact_id]


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


def _chat_id_for_direct_message(sender_id: int, recipient_ids: list[int]) -> str:
    first_recipient_id = recipient_ids[0]
    low_id = min(sender_id, first_recipient_id)
    high_id = max(sender_id, first_recipient_id)
    return f"dm:{low_id}:{high_id}"


def _sender_contact_candidates(sender_id: int, sender_role: str) -> list[object]:
    candidates: list[object] = [sender_id]
    if sender_role == UserRole.admin.value:
        candidates.append("admin")
    return candidates


def _queue_new_message_notification(
    *,
    sender_id: int,
    sender_role: str,
    recipient_ids: list[int],
    message_id: int,
    background_tasks=None,
) -> None:
    target_recipient_ids = sorted(
        {recipient_id for recipient_id in recipient_ids if recipient_id != sender_id}
    )
    if not target_recipient_ids:
        return

    contact_candidates = _sender_contact_candidates(sender_id, sender_role)
    excluded_device_ids: list[str] = []
    for recipient_id in target_recipient_ids:
        excluded_device_ids.extend(
            manager.devices_with_open_chat(recipient_id, contact_candidates)
        )

    NotificationService.notify(
        user_ids=target_recipient_ids,
        type=NotificationType.new_message,
        title="Nuevo mensaje",
        body="Tienes un mensaje nuevo",
        data={
            "type": NotificationType.new_message.value,
            "chat_id": _chat_id_for_direct_message(sender_id, target_recipient_ids),
            "contact_id": str(sender_id),
            "message_id": str(message_id),
        },
        background_tasks=background_tasks,
        exclude_device_ids=excluded_device_ids,
    )


def _is_chat_presence_event(message_data: dict) -> bool:
    return message_data.get("type") in {"chat_opened", "chat_closed"}


async def _handle_chat_presence_event(
    *,
    message_data: dict,
    user_id: int,
    device_id: str | None,
) -> None:
    if not device_id:
        return

    event_type = message_data.get("type")
    if event_type == "chat_opened":
        contact_id = message_data.get("contact_id")
        if contact_id is not None:
            manager.mark_chat_opened(user_id, device_id, contact_id)
    elif event_type == "chat_closed":
        manager.mark_chat_closed(user_id, device_id)


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: Optional[str] = Query(None),
    device_id: Optional[str] = Query(None),
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

    await manager.connect(websocket, sender_id, device_id=device_id)

    try:
        while True:
            data = await websocket.receive_text()

            try:
                message_data = json.loads(data)
            except json.JSONDecodeError:
                await websocket.send_json({"error": "Formato JSON inválido"})
                continue

            if _is_chat_presence_event(message_data):
                await _handle_chat_presence_event(
                    message_data=message_data,
                    user_id=sender_id,
                    device_id=device_id,
                )
                continue

            # Rate Limiting
            now = time()
            last_msg_time = getattr(websocket, '_last_msg', 0)
            if now - last_msg_time < 0.5:
                await websocket.send_json({"error": "Demasiados mensajes, espera un momento"})
                continue
            websocket._last_msg = now

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

            _queue_new_message_notification(
                sender_id=sender_id,
                sender_role=sender_role,
                recipient_ids=[actual_receiver_id],
                message_id=msg_payload["id"],
            )

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


@router.get("/unread-counts")
def get_unread_counts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    rows = (
        db.query(Message.sender_id, func.count(Message.id))
        .filter(
            Message.receiver_id == current_user.id_usuario,
            _unread_message_filter(),
        )
        .group_by(Message.sender_id)
        .order_by(Message.sender_id)
        .all()
    )

    counts = [
        {"contact_id": sender_id, "unread_count": int(unread_count)}
        for sender_id, unread_count in rows
    ]

    return {
        "total": sum(item["unread_count"] for item in counts),
        "counts": counts,
    }


@router.patch("/conversations/{contact_id}/read")
async def mark_conversation_as_read(
    contact_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    sender_ids = _resolve_conversation_sender_ids(contact_id, current_user, db)
    messages = (
        db.query(Message)
        .filter(
            Message.receiver_id == current_user.id_usuario,
            Message.sender_id.in_(sender_ids),
            _unread_message_filter(),
        )
        .order_by(Message.timestamp)
        .all()
    )

    if not messages:
        return {"updated_count": 0, "message_ids": [], "read_at": None}

    read_at = datetime.now(timezone.utc)
    read_at_iso = read_at.isoformat()
    events = []

    for message in messages:
        message.is_read = True
        message.read_at = read_at
        if message.delivered_at is None:
            message.delivered_at = read_at
        events.append((message.sender_id, message.id))

    db.commit()

    for sender_id, message_id in events:
        await manager.send_personal_json(
            {
                "type": "message_read",
                "message_id": message_id,
                "reader_id": current_user.id_usuario,
                "read_at": read_at_iso,
            },
            sender_id
        )

    return {
        "updated_count": len(events),
        "message_ids": [message_id for _, message_id in events],
        "read_at": read_at_iso,
    }


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
