from datetime import date, time, timedelta

from app.core.Enum import UserRole
from app.models.BookingEntity import Booking, ConfirmationState
from app.models.VehicleEntity import TipoVehiculoEnum, Vehicle
from app.services.AdminService import AdminService
from app.services.NotificationService import NotificationService, NotificationType
from tests.conftest import auth_header, create_user


def future_date(days: int = 4) -> date:
    return date.today() + timedelta(days=days)


def create_vehicle(db) -> Vehicle:
    vehicle = Vehicle(
        id_vehiculo=1,
        placa="ABC123",
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
    user_id: int,
    vehicle_id: int,
    state: ConfirmationState = ConfirmationState.PENDIENTE,
) -> Booking:
    booking = Booking(
        id_agendamiento=1,
        id_usuario=user_id,
        id_vehiculo=vehicle_id,
        fecha_solicitud=date.today(),
        fecha_cita=future_date(),
        hora_cita=time(9, 0),
        observaciones="Revision inicial",
        estado_confirmacion=state,
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return booking


def test_confirm_booking_notifies_booking_owner(db, monkeypatch):
    owner = create_user(db, 1, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_booking(db, user_id=owner.id_usuario, vehicle_id=vehicle.id_vehiculo)
    background_tasks = object()
    calls = []

    def fake_notify(**kwargs):
        calls.append(kwargs)

    monkeypatch.setattr(NotificationService, "notify", fake_notify)

    AdminService.confirm_booking(
        db,
        booking.id_agendamiento,
        background_tasks=background_tasks,
    )

    assert len(calls) == 1
    assert calls[0]["user_ids"] == [owner.id_usuario]
    assert calls[0]["type"] == NotificationType.booking_confirmed
    assert calls[0]["title"] == "Cita confirmada"
    assert calls[0]["data"] == {
        "type": "booking_confirmed",
        "booking_id": str(booking.id_agendamiento),
    }
    assert calls[0]["background_tasks"] is background_tasks


def test_reject_booking_notifies_booking_owner(db, monkeypatch):
    owner = create_user(db, 1, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_booking(db, user_id=owner.id_usuario, vehicle_id=vehicle.id_vehiculo)
    calls = []

    def fake_notify(**kwargs):
        calls.append(kwargs)

    monkeypatch.setattr(NotificationService, "notify", fake_notify)

    AdminService.reject_booking(
        db,
        booking.id_agendamiento,
        "No hay cupo disponible",
    )

    assert len(calls) == 1
    assert calls[0]["user_ids"] == [owner.id_usuario]
    assert calls[0]["type"] == NotificationType.booking_rejected
    assert calls[0]["title"] == "Cita rechazada"
    assert calls[0]["data"] == {
        "type": "booking_rejected",
        "booking_id": str(booking.id_agendamiento),
    }


def test_confirm_booking_already_confirmed_does_not_duplicate_notification(
    db,
    monkeypatch,
):
    owner = create_user(db, 1, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_booking(
        db,
        user_id=owner.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
        state=ConfirmationState.CONFIRMADO,
    )
    calls = []

    monkeypatch.setattr(NotificationService, "notify", lambda **kwargs: calls.append(kwargs))

    AdminService.confirm_booking(db, booking.id_agendamiento)

    assert calls == []


def test_non_admin_cannot_confirm_or_trigger_booking_notification(
    client,
    db,
    monkeypatch,
):
    owner = create_user(db, 1, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_booking(
        db,
        user_id=owner.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
    )
    calls = []

    monkeypatch.setattr(NotificationService, "notify", lambda **kwargs: calls.append(kwargs))

    response = client.patch(
        f"/api/v1/admin/bookings/{booking.id_agendamiento}/confirm",
        headers=auth_header(owner),
    )

    db.refresh(booking)
    assert response.status_code == 403
    assert booking.estado_confirmacion == ConfirmationState.PENDIENTE
    assert calls == []
