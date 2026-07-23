import logging
from datetime import timedelta, timezone, tzinfo
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

logger = logging.getLogger(__name__)

BOGOTA_FIXED_OFFSET = timezone(timedelta(hours=-5), "America/Bogota")


def get_timezone(timezone_name: str, fallback: tzinfo = BOGOTA_FIXED_OFFSET) -> tzinfo:
    try:
        return ZoneInfo(timezone_name)
    except ZoneInfoNotFoundError:
        logger.warning(
            "No se encontro tzdata para %s. Usando fallback fijo UTC-05:00.",
            timezone_name,
        )
        return fallback


def get_bogota_timezone() -> tzinfo:
    return get_timezone("America/Bogota")
