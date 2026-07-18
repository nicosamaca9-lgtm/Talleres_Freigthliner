from datetime import date, time

from app.core.Enum import UserRole
from app.models.ServiceOrderEntity import ServiceOrder, ServiceOrderState
from app.models.VehicleEntity import TipoVehiculoEnum, Vehicle
from app.services.AdminService import AdminService
from app.services.NotificationService import NotificationService, NotificationType
from tests.conftest import auth_header, create_user


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


def create_service_order(
    db,
    *,
    order_id: int = 1,
    vehicle: Vehicle,
    mechanic_id: int | None = None,
) -> ServiceOrder:
    order = ServiceOrder(
        id_orden=order_id,
        numero_orden=f"ORD-{order_id:04d}",
        id_vehiculo=vehicle.id_vehiculo,
        id_mecanico=mechanic_id,
        fecha_ingreso=date(2026, 7, 17),
        hora_ingreso=time(8, 0),
        cliente_nombre="Cliente Demo",
        cliente_identificacion="123456",
        cliente_telefono="3000000000",
        kilometraje_ingreso=1000,
        nivel_combustible="Medio",
        trabajos_a_realizar="Diagnostico inicial",
        estado_orden=ServiceOrderState.EN_DIAGNOSTICO,
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    return order


def test_assign_order_notifies_only_assigned_mechanic(db, monkeypatch):
    create_user(db, 1, UserRole.admin, "admin")
    mechanic = create_user(db, 2, UserRole.mechanic, "mechanic")
    create_user(db, 3, UserRole.client, "client")
    vehicle = create_vehicle(db)
    order = create_service_order(db, vehicle=vehicle)
    calls = []

    def fake_notify(**kwargs):
        calls.append(kwargs)

    monkeypatch.setattr(NotificationService, "notify", fake_notify)

    updated_order = AdminService.assign_mechanic_to_order(
        db,
        order.id_orden,
        mechanic.id_usuario,
    )

    assert updated_order.id_mecanico == mechanic.id_usuario
    assert len(calls) == 1
    assert calls[0]["user_ids"] == [mechanic.id_usuario]
    assert calls[0]["type"] == NotificationType.order_assigned
    assert calls[0]["data"] == {
        "type": "order_assigned",
        "order_id": str(order.id_orden),
    }


def test_reassign_order_notifies_new_mechanic_only(db, monkeypatch):
    old_mechanic = create_user(db, 2, UserRole.mechanic, "old-mechanic")
    new_mechanic = create_user(db, 3, UserRole.mechanic, "new-mechanic")
    vehicle = create_vehicle(db)
    order = create_service_order(
        db,
        vehicle=vehicle,
        mechanic_id=old_mechanic.id_usuario,
    )
    calls = []

    def fake_notify(**kwargs):
        calls.append(kwargs)

    monkeypatch.setattr(NotificationService, "notify", fake_notify)

    updated_order = AdminService.assign_mechanic_to_order(
        db,
        order.id_orden,
        new_mechanic.id_usuario,
    )

    assert updated_order.id_mecanico == new_mechanic.id_usuario
    assert [call["user_ids"] for call in calls] == [[new_mechanic.id_usuario]]


def test_non_admin_cannot_assign_or_trigger_notification(client, db, monkeypatch):
    secretary = create_user(db, 1, UserRole.secretary, "secretary")
    mechanic = create_user(db, 2, UserRole.mechanic, "mechanic")
    vehicle = create_vehicle(db)
    order = create_service_order(db, vehicle=vehicle)
    calls = []

    def fake_notify(**kwargs):
        calls.append(kwargs)

    monkeypatch.setattr(NotificationService, "notify", fake_notify)

    response = client.patch(
        f"/api/v1/admin/service-orders/{order.id_orden}/assign",
        json={"id_mecanico": mechanic.id_usuario},
        headers=auth_header(secretary),
    )

    db.refresh(order)
    assert response.status_code == 403
    assert order.id_mecanico is None
    assert calls == []
