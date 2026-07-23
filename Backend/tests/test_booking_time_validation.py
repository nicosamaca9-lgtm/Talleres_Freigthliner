from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

import pytest
from fastapi import HTTPException

from app.core.Enum import UserRole
from app.models.BookingEntity import Booking, ConfirmationState
from app.models.VehicleEntity import TipoVehiculoEnum, Vehicle
from app.schemas.BookingSchema import BookingCreate, BookingUpdate
from app.services.BookingService import BookingService
from app.services.BookingValidationService import BookingValidationService
from tests.conftest import create_user


BOGOTA = ZoneInfo("America/Bogota")


def future_date(days: int = 7) -> date:
    return date.today() + timedelta(days=days)


def create_vehicle(db, vehicle_id: int = 1) -> Vehicle:
    vehicle = Vehicle(
        id_vehiculo=vehicle_id,
        placa=f"ABC{vehicle_id:03d}",
        marca="Freightliner",
        modelo="Cascadia",
        tipo_vehiculo=TipoVehiculoEnum.camion,
    )
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


def create_existing_booking(db, *, user_id: int, vehicle_id: int) -> Booking:
    booking = Booking(
        id_agendamiento=1,
        id_usuario=user_id,
        id_vehiculo=vehicle_id,
        fecha_solicitud=date.today(),
        fecha_cita=future_date(),
        hora_cita=time(10, 0),
        observaciones="Revision inicial",
        estado_confirmacion=ConfirmationState.CONFIRMADO,
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return booking


def test_booking_time_validation_allows_next_hour_without_one_hour_notice():
    BookingValidationService.validate_booking_time(
        fecha_cita=date(2026, 7, 23),
        hora_cita=time(9, 0),
        now=datetime(2026, 7, 23, 8, 30, tzinfo=BOGOTA),
    )


def test_booking_time_validation_allows_future_minutes_in_current_hour():
    BookingValidationService.validate_booking_time(
        fecha_cita=date(2026, 7, 23),
        hora_cita=time(8, 45),
        now=datetime(2026, 7, 23, 8, 30, tzinfo=BOGOTA),
    )


def test_booking_time_validation_rejects_current_or_past_minute():
    with pytest.raises(HTTPException) as exc_info:
        BookingValidationService.validate_booking_time(
            fecha_cita=date(2026, 7, 23),
            hora_cita=time(8, 30),
            now=datetime(2026, 7, 23, 8, 30, tzinfo=BOGOTA),
        )

    assert exc_info.value.status_code == 400
    assert "hora actual" in exc_info.value.detail


def test_booking_time_validation_rejects_past_date():
    with pytest.raises(HTTPException) as exc_info:
        BookingValidationService.validate_booking_time(
            fecha_cita=date(2026, 7, 22),
            hora_cita=time(10, 0),
            now=datetime(2026, 7, 23, 8, 30, tzinfo=BOGOTA),
        )

    assert exc_info.value.status_code == 400
    assert "hora pasada" in exc_info.value.detail


def test_booking_time_validation_rejects_outside_business_hours():
    with pytest.raises(HTTPException) as exc_info:
        BookingValidationService.validate_booking_time(
            fecha_cita=date(2026, 7, 24),
            hora_cita=time(12, 0),
            now=datetime(2026, 7, 23, 8, 30, tzinfo=BOGOTA),
        )

    assert exc_info.value.status_code == 400
    assert "08:00" in exc_info.value.detail


def test_booking_time_validation_accepts_aware_utc_now_for_valid_local_time():
    BookingValidationService.validate_booking_time(
        fecha_cita=date(2026, 7, 23),
        hora_cita=time(10, 0),
        now=datetime(2026, 7, 23, 13, 30, tzinfo=ZoneInfo("UTC")),
    )


def test_create_booking_rejects_invalid_business_hour_before_persisting(db):
    client_user = create_user(db, 1, UserRole.client, "client")
    vehicle = create_vehicle(db)

    with pytest.raises(HTTPException) as exc_info:
        BookingService.create_booking(
            db,
            BookingCreate(
                id_usuario=client_user.id_usuario,
                id_vehiculo=vehicle.id_vehiculo,
                fecha_solicitud=date.today(),
                fecha_cita=future_date(),
                hora_cita=time(13, 30),
                observaciones="Revision fuera de horario",
            ),
        )

    assert exc_info.value.status_code == 400
    assert db.query(Booking).count() == 0


def test_reschedule_rejects_invalid_business_hour_without_changing_booking(db):
    client_user = create_user(db, 1, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_existing_booking(
        db,
        user_id=client_user.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
    )

    with pytest.raises(HTTPException) as exc_info:
        BookingService.update_booking(
            db,
            booking.id_agendamiento,
            BookingUpdate(
                fecha_cita=future_date(8),
                hora_cita=time(18, 0),
                observaciones="Intento fuera de horario",
            ),
            current_user=client_user,
        )

    db.refresh(booking)
    assert exc_info.value.status_code == 400
    assert booking.fecha_cita == future_date()
    assert booking.hora_cita == time(10, 0)
    assert booking.observaciones == "Revision inicial"
