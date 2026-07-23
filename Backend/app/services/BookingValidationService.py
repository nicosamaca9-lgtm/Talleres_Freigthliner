from datetime import date, datetime, time

from fastapi import HTTPException, status

from app.core.timezone import get_bogota_timezone


class BookingValidationService:
    BUSINESS_TIME_WINDOWS = (
        (time(8, 0), time(12, 0)),
        (time(14, 0), time(18, 0)),
    )
    LOCAL_TIMEZONE = get_bogota_timezone()
    CURRENT_TIME_MESSAGE = (
        "No puedes agendar o reprogramar una cita en la hora actual o en una hora pasada."
    )
    BUSINESS_HOURS_MESSAGE = (
        "El horario de atencion es de 08:00 a 12:00 y de 14:00 a 18:00."
    )

    @classmethod
    def validate_booking_time(
        cls,
        *,
        fecha_cita: date,
        hora_cita: time,
        now: datetime | None = None,
    ) -> None:
        appointment_at = cls._appointment_datetime(fecha_cita, hora_cita)
        current_time = cls._local_now(now)

        if not cls._is_within_business_hours(hora_cita):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=cls.BUSINESS_HOURS_MESSAGE,
            )

        if cls._is_current_or_past_time_slot(appointment_at, current_time):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=cls.CURRENT_TIME_MESSAGE,
            )

    @classmethod
    def _appointment_datetime(cls, appointment_date: date, appointment_time: time) -> datetime:
        return datetime.combine(
            appointment_date,
            appointment_time,
            tzinfo=cls.LOCAL_TIMEZONE,
        )

    @classmethod
    def _local_now(cls, now: datetime | None) -> datetime:
        if now is None:
            return datetime.now(cls.LOCAL_TIMEZONE)
        if now.tzinfo is None:
            return now.replace(tzinfo=cls.LOCAL_TIMEZONE)
        return now.astimezone(cls.LOCAL_TIMEZONE)

    @classmethod
    def _is_current_or_past_time_slot(
        cls,
        appointment_at: datetime,
        current_time: datetime,
    ) -> bool:
        return appointment_at <= current_time

    @classmethod
    def _is_within_business_hours(cls, appointment_time: time) -> bool:
        return any(
            start <= appointment_time < end
            for start, end in cls.BUSINESS_TIME_WINDOWS
        )
