from datetime import date, time, timedelta

from app.core.Enum import UserRole
from app.models.BookingEntity import Booking, ConfirmationState
from app.models.VehicleEntity import TipoVehiculoEnum, Vehicle
from app.schemas.BookingSchema import BookingUpdate
from app.services.BookingService import BookingService
from tests.conftest import auth_header, create_user


def future_date(days: int = 5) -> date:
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


def create_booking(
    db,
    *,
    booking_id: int = 1,
    user_id: int,
    vehicle_id: int,
    state: ConfirmationState,
    appointment_date: date | None = None,
    appointment_time: time = time(14, 0),
) -> Booking:
    booking = Booking(
        id_agendamiento=booking_id,
        id_usuario=user_id,
        id_vehiculo=vehicle_id,
        fecha_solicitud=date.today(),
        fecha_cita=appointment_date or future_date(),
        hora_cita=appointment_time,
        observaciones="Revision inicial",
        estado_confirmacion=state,
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return booking


def booking_update(
    *,
    appointment_date: date,
    appointment_time: time,
    observaciones: str = "Revision reprogramada",
) -> BookingUpdate:
    return BookingUpdate(
        fecha_cita=appointment_date,
        hora_cita=appointment_time,
        observaciones=observaciones,
    )


def test_confirmed_booking_reschedule_resets_state_to_pending(db):
    client_user = create_user(db, 1, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_booking(
        db,
        user_id=client_user.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
        state=ConfirmationState.CONFIRMADO,
    )

    updated = BookingService.update_booking(
        db,
        booking.id_agendamiento,
        booking_update(
            appointment_date=future_date(8),
            appointment_time=time(16, 30),
        ),
        current_user=client_user,
    )

    assert updated.estado_confirmacion == ConfirmationState.PENDIENTE
    assert updated.fecha_cita == future_date(8)
    assert updated.hora_cita == time(16, 30)


def test_confirmed_booking_same_schedule_does_not_reset_state(db):
    client_user = create_user(db, 1, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_booking(
        db,
        user_id=client_user.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
        state=ConfirmationState.CONFIRMADO,
        appointment_date=future_date(6),
        appointment_time=time(10, 0),
    )

    updated = BookingService.update_booking(
        db,
        booking.id_agendamiento,
        booking_update(
            appointment_date=booking.fecha_cita,
            appointment_time=booking.hora_cita,
            observaciones="Solo cambia la observacion",
        ),
        current_user=client_user,
    )

    assert updated.estado_confirmacion == ConfirmationState.CONFIRMADO
    assert updated.observaciones == "Solo cambia la observacion"


def test_cancelled_booking_reschedule_does_not_overwrite_state(db):
    client_user = create_user(db, 1, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_booking(
        db,
        user_id=client_user.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
        state=ConfirmationState.CANCELADO,
    )

    updated = BookingService.update_booking(
        db,
        booking.id_agendamiento,
        booking_update(
            appointment_date=future_date(9),
            appointment_time=time(11, 0),
        ),
        current_user=client_user,
    )

    assert updated.estado_confirmacion == ConfirmationState.CANCELADO


def test_user_cannot_reschedule_another_users_booking(client, db):
    owner = create_user(db, 1, UserRole.client, "owner")
    other_user = create_user(db, 2, UserRole.client, "other")
    vehicle = create_vehicle(db)
    booking = create_booking(
        db,
        user_id=owner.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
        state=ConfirmationState.CONFIRMADO,
    )

    response = client.put(
        f"/api/v1/bookings/{booking.id_agendamiento}",
        json={
            "fecha_cita": future_date(7).isoformat(),
            "hora_cita": "13:30:00",
            "observaciones": "Intento externo",
        },
        headers=auth_header(other_user),
    )

    db.refresh(booking)
    assert response.status_code == 403
    assert booking.estado_confirmacion == ConfirmationState.CONFIRMADO
    assert booking.observaciones == "Revision inicial"
