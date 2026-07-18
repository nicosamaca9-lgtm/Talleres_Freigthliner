import asyncio
import json
from dataclasses import dataclass
import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

def get_firebase_app():
    if not firebase_admin._apps:
        if settings.FIREBASE_CREDENTIALS_JSON:
            try:
                cred_dict = json.loads(settings.FIREBASE_CREDENTIALS_JSON)
                cred = credentials.Certificate(cred_dict)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase inicializado correctamente desde variable de entorno.")
            except Exception as e:
                logger.error(f"Error al inicializar Firebase: {e}")
        else:
            logger.warning("FIREBASE_CREDENTIALS_JSON no está definida en el entorno. Firebase no inicializado.")
    return firebase_admin.get_app() if firebase_admin._apps else None

# Initialize on import
get_firebase_app()


@dataclass(frozen=True)
class FirebaseMulticastResult:
    success_count: int
    failure_count: int
    invalid_tokens: list[str]


_INVALID_TOKEN_ERROR_CODES = {
    "invalid-registration-token",
    "registration-token-not-registered",
    "unregistered",
    "not-found",
}


def _stringify_data(data: dict | None) -> dict[str, str]:
    if not data:
        return {}
    return {
        str(key): str(value)
        for key, value in data.items()
        if value is not None
    }


def _is_invalid_token_error(exception: Exception | None) -> bool:
    if exception is None:
        return False

    code = str(getattr(exception, "code", "")).lower()
    if code in _INVALID_TOKEN_ERROR_CODES:
        return True

    message = str(exception).lower()
    return any(error_code in message for error_code in _INVALID_TOKEN_ERROR_CODES)


def _send_multicast_sync(
    *,
    tokens: list[str],
    title: str,
    body: str,
    data: dict[str, str],
) -> FirebaseMulticastResult:
    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(title=title, body=body),
        data=_stringify_data(data),
    )
    response = messaging.send_each_for_multicast(message)
    invalid_tokens = [
        token
        for token, send_response in zip(tokens, response.responses)
        if not send_response.success
        and _is_invalid_token_error(send_response.exception)
    ]

    return FirebaseMulticastResult(
        success_count=response.success_count,
        failure_count=response.failure_count,
        invalid_tokens=invalid_tokens,
    )


async def send_multicast_notification(
    *,
    tokens: list[str],
    title: str,
    body: str,
    data: dict[str, str],
) -> FirebaseMulticastResult:
    if not tokens:
        return FirebaseMulticastResult(
            success_count=0,
            failure_count=0,
            invalid_tokens=[],
        )

    if not firebase_admin._apps:
        logger.warning("Intento de enviar notificacion Push, pero Firebase no esta inicializado.")
        return FirebaseMulticastResult(
            success_count=0,
            failure_count=len(tokens),
            invalid_tokens=[],
        )

    return await asyncio.to_thread(
        _send_multicast_sync,
        tokens=tokens,
        title=title,
        body=body,
        data=data,
    )


def _send_fcm_sync(user_id: int, message_content: str) -> bool:
    """
    Lógica síncrona de envío FCM. Se ejecuta en un thread pool
    para no bloquear el event loop de asyncio.
    """
    topic = f"user_{user_id}"
    message = messaging.Message(
        notification=messaging.Notification(
            title="Nuevo mensaje",
            body=message_content,
        ),
        topic=topic,
    )
    try:
        response = messaging.send(message)
        logger.info(f"Notificación enviada con éxito a {topic}: {response}")
        return True
    except Exception as e:
        logger.error(f"Error al enviar notificación a {topic}: {e}")
        return False


async def send_push_notification(user_id: int, message_content: str) -> bool:
    """
    Envía una notificación Push al usuario mediante Firebase Cloud Messaging (FCM).
    Usa asyncio.to_thread() para ejecutar la llamada síncrona del SDK de Firebase
    en un thread pool, evitando bloquear el event loop de uvicorn.
    """
    if not firebase_admin._apps:
        logger.warning("Intento de enviar notificación Push, pero Firebase no está inicializado.")
        return False

    return await asyncio.to_thread(_send_fcm_sync, user_id, message_content)
