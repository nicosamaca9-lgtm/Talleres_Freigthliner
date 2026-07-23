from datetime import timedelta
from zoneinfo import ZoneInfoNotFoundError

from app.core import timezone as timezone_module


def test_get_timezone_falls_back_when_tzdata_is_missing(monkeypatch):
    def raise_missing_timezone(timezone_name):
        raise ZoneInfoNotFoundError(timezone_name)

    monkeypatch.setattr(timezone_module, "ZoneInfo", raise_missing_timezone)

    tz = timezone_module.get_timezone("America/Bogota")

    assert tz.utcoffset(None) == -timedelta(hours=5)
