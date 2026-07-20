from datetime import date, time, timedelta

from app.core.Enum import UserRole
from app.models.BookingEntity import Booking, ConfirmationState
from app.models.VehicleEntity import TipoVehiculoEnum, Vehicle
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


def create_pending_booking(db, *, user_id: int, vehicle_id: int) -> Booking:
    booking = Booking(
        id_agendamiento=1,
        id_usuario=user_id,
        id_vehiculo=vehicle_id,
        fecha_solicitud=date.today(),
        fecha_cita=future_date(),
        hora_cita=time(9, 0),
        observaciones="Revision inicial",
        estado_confirmacion=ConfirmationState.PENDIENTE,
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return booking


def test_admin_can_reject_booking_with_reason(client, db):
    admin = create_user(db, 1, UserRole.admin, "admin")
    owner = create_user(db, 2, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_pending_booking(
        db,
        user_id=owner.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
    )

    response = client.patch(
        f"/api/v1/admin/bookings/{booking.id_agendamiento}/reject",
        json={"motivo_rechazo": "No hay cupo disponible"},
        headers=auth_header(admin),
    )

    db.refresh(booking)
    assert response.status_code == 200
    assert booking.estado_confirmacion == ConfirmationState.RECHAZADO
    assert booking.motivo_rechazo == "No hay cupo disponible"


def test_admin_cannot_reject_booking_with_reason_over_30_characters(client, db):
    admin = create_user(db, 1, UserRole.admin, "admin")
    owner = create_user(db, 2, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_pending_booking(
        db,
        user_id=owner.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
    )

    response = client.patch(
        f"/api/v1/admin/bookings/{booking.id_agendamiento}/reject",
        json={"motivo_rechazo": "Motivo demasiado largo para rechazar"},
        headers=auth_header(admin),
    )

    db.refresh(booking)
    assert response.status_code == 422
    assert booking.estado_confirmacion == ConfirmationState.PENDIENTE
    assert booking.motivo_rechazo is None


def test_non_admin_cannot_reject_booking(client, db):
    owner = create_user(db, 2, UserRole.client, "client")
    vehicle = create_vehicle(db)
    booking = create_pending_booking(
        db,
        user_id=owner.id_usuario,
        vehicle_id=vehicle.id_vehiculo,
    )

    response = client.patch(
        f"/api/v1/admin/bookings/{booking.id_agendamiento}/reject",
        json={"motivo_rechazo": "Intento no autorizado"},
        headers=auth_header(owner),
    )

    db.refresh(booking)
    assert response.status_code == 403
    assert booking.estado_confirmacion == ConfirmationState.PENDIENTE
