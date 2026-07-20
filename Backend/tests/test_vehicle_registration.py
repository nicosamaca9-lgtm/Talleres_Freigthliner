from app.core.Enum import UserRole
from app.models.VehicleEntity import TipoVehiculoEnum, Vehicle
from app.models.VehicleUserEntity import VehicleUser
from tests.conftest import auth_header, create_user


def create_vehicle(
    db,
    *,
    vehicle_id: int = 1,
    placa: str = "ABC123",
    marca: str = "Sin Registrar",
    modelo: str = "Sin Registrar",
    tipo_vehiculo: TipoVehiculoEnum = TipoVehiculoEnum.otro,
) -> Vehicle:
    vehicle = Vehicle(
        id_vehiculo=vehicle_id,
        placa=placa,
        marca=marca,
        modelo=modelo,
        tipo_vehiculo=tipo_vehiculo,
    )
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


def register_payload(
    *,
    placa: str = "ABC123",
    marca: str = "Mercedes-Benz",
    modelo: str = "2026",
    tipo_vehiculo: str = "Camion",
) -> dict:
    return {
        "placa": placa,
        "marca": marca,
        "modelo": modelo,
        "tipo_vehiculo": tipo_vehiculo,
    }


def test_owner_claims_unowned_vehicle_and_real_data_overwrites_temporary_data(
    client,
    db,
):
    owner = create_user(db, 1, UserRole.client, "owner")
    vehicle = create_vehicle(db)

    response = client.post(
        "/api/v1/vehicles/",
        json=register_payload(),
        headers=auth_header(owner),
    )

    db.refresh(vehicle)
    owner_link = db.query(VehicleUser).filter(
        VehicleUser.id_vehiculo == vehicle.id_vehiculo,
        VehicleUser.id_usuario == owner.id_usuario,
        VehicleUser.rol_vehiculo == "Propietario",
    ).one_or_none()

    assert response.status_code == 201
    assert response.json()["id_vehiculo"] == vehicle.id_vehiculo
    assert vehicle.marca == "Mercedes-Benz"
    assert vehicle.modelo == "2026"
    assert vehicle.tipo_vehiculo == TipoVehiculoEnum.camion
    assert owner_link is not None


def test_register_existing_vehicle_with_other_owner_is_rejected_and_does_not_update(
    client,
    db,
):
    existing_owner = create_user(db, 1, UserRole.client, "owner")
    claimant = create_user(db, 2, UserRole.client, "claimant")
    vehicle = create_vehicle(db, marca="Freightliner", modelo="2020")
    db.add(
        VehicleUser(
            id_usuario=existing_owner.id_usuario,
            id_vehiculo=vehicle.id_vehiculo,
            rol_vehiculo="Propietario",
        )
    )
    db.commit()

    response = client.post(
        "/api/v1/vehicles/",
        json=register_payload(marca="Mercedes-Benz", modelo="2026"),
        headers=auth_header(claimant),
    )

    db.refresh(vehicle)

    assert response.status_code == 400
    assert vehicle.marca == "Freightliner"
    assert vehicle.modelo == "2020"


def test_current_owner_can_update_existing_vehicle_data_without_duplicate_owner(
    client,
    db,
):
    owner = create_user(db, 1, UserRole.client, "owner")
    vehicle = create_vehicle(db, marca="Sin Registrar", modelo="Sin Registrar")
    db.add(
        VehicleUser(
            id_usuario=owner.id_usuario,
            id_vehiculo=vehicle.id_vehiculo,
            rol_vehiculo="Propietario",
        )
    )
    db.commit()

    response = client.post(
        "/api/v1/vehicles/",
        json=register_payload(marca="Mercedes-Benz", modelo="2026"),
        headers=auth_header(owner),
    )

    owner_links = db.query(VehicleUser).filter(
        VehicleUser.id_vehiculo == vehicle.id_vehiculo,
        VehicleUser.rol_vehiculo == "Propietario",
    ).all()
    db.refresh(vehicle)

    assert response.status_code == 201
    assert vehicle.marca == "Mercedes-Benz"
    assert vehicle.modelo == "2026"
    assert len(owner_links) == 1
