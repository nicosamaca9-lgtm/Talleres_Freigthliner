from sqlalchemy.orm import Session
from app.models.VehicleEntity import Vehicle
from app.models.VehicleUserEntity import VehicleUser
from app.models.VehicleInvitationEntity import VehicleInvitation
from app.schemas.VehicleSchema import VehicleCreate
from fastapi import HTTPException
import random
import string
from datetime import datetime, timedelta


class VehicleService:
    VEHICLE_REGISTERED_IN_OTHER_ACCOUNT = (
        "Este vehiculo ya se encuentra registrado en otra cuenta. "
        "Si eres el conductor, pidele al propietario que te genere un codigo de invitacion."
    )

    @staticmethod
    def get_vehicle_by_placa(db: Session, placa: str):
        """Busca un vehiculo en la base de datos por su placa."""
        return db.query(Vehicle).filter(Vehicle.placa == placa.upper()).first()

    @staticmethod
    def register_or_claim_vehicle(db: Session, vehicle_data: VehicleCreate, user_id: int):
        """Registra un vehiculo nuevo o reclama uno existente sin propietario."""
        placa = vehicle_data.placa.upper()
        db_vehicle = (
            db.query(Vehicle)
            .filter(Vehicle.placa == placa)
            .with_for_update()
            .first()
        )

        if not db_vehicle:
            return VehicleService.create_vehicle(db=db, vehicle_data=vehicle_data, user_id=user_id)

        owner = (
            db.query(VehicleUser)
            .filter(
                VehicleUser.id_vehiculo == db_vehicle.id_vehiculo,
                VehicleUser.rol_vehiculo == "Propietario",
            )
            .with_for_update()
            .first()
        )

        if owner and owner.id_usuario != user_id:
            raise HTTPException(
                status_code=400,
                detail=VehicleService.VEHICLE_REGISTERED_IN_OTHER_ACCOUNT,
            )

        db_vehicle.marca = vehicle_data.marca
        db_vehicle.modelo = vehicle_data.modelo
        db_vehicle.tipo_vehiculo = vehicle_data.tipo_vehiculo

        if not owner:
            db.add(
                VehicleUser(
                    id_usuario=user_id,
                    id_vehiculo=db_vehicle.id_vehiculo,
                    rol_vehiculo="Propietario",
                )
            )

        db.commit()
        db.refresh(db_vehicle)
        return db_vehicle

    @staticmethod
    def create_vehicle(db: Session, vehicle_data: VehicleCreate, user_id: int):
        """Registra un nuevo vehiculo y asigna al creador como Propietario."""
        db_vehicle = Vehicle(
            placa=vehicle_data.placa.upper(),
            marca=vehicle_data.marca,
            modelo=vehicle_data.modelo,
            tipo_vehiculo=vehicle_data.tipo_vehiculo,
        )

        db.add(db_vehicle)
        db.commit()
        db.refresh(db_vehicle)

        vehicle_user = VehicleUser(
            id_usuario=user_id,
            id_vehiculo=db_vehicle.id_vehiculo,
            rol_vehiculo="Propietario",
        )
        db.add(vehicle_user)
        db.commit()

        return db_vehicle

    @staticmethod
    def get_all_vehicles(db: Session, skip: int = 0, limit: int = 100):
        """Retorna la lista de todos los vehiculos registrados."""
        return db.query(Vehicle).offset(skip).limit(limit).all()

    @staticmethod
    def generate_invitation(db: Session, placa: str, user_id: int):
        """Genera un codigo de invitacion para un vehiculo si el usuario es el dueno."""
        vehicle = VehicleService.get_vehicle_by_placa(db, placa)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehiculo no encontrado")

        owner = db.query(VehicleUser).filter(
            VehicleUser.id_vehiculo == vehicle.id_vehiculo,
            VehicleUser.id_usuario == user_id,
            VehicleUser.rol_vehiculo == "Propietario",
        ).first()

        if not owner:
            raise HTTPException(status_code=403, detail="No eres el propietario de este vehiculo")

        existing_driver = db.query(VehicleUser).filter(
            VehicleUser.id_vehiculo == vehicle.id_vehiculo,
            VehicleUser.rol_vehiculo == "Conductor",
        ).first()

        if existing_driver:
            raise HTTPException(status_code=400, detail="Este vehiculo ya tiene un conductor asignado")

        codigo = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        expiracion = datetime.utcnow() + timedelta(hours=12)

        invitacion = VehicleInvitation(
            id_vehiculo=vehicle.id_vehiculo,
            id_usuario_creador=user_id,
            codigo_secreto=codigo,
            fecha_expiracion=expiracion,
        )

        db.add(invitacion)
        db.commit()

        return {"codigo_secreto": codigo, "fecha_expiracion": expiracion}

    @staticmethod
    def redeem_invitation(db: Session, codigo_secreto: str, user_id: int):
        """Permite a un usuario canjear un codigo para convertirse en conductor."""
        invitacion = db.query(VehicleInvitation).filter(
            VehicleInvitation.codigo_secreto == codigo_secreto.upper()
        ).first()

        if not invitacion:
            raise HTTPException(status_code=404, detail="Codigo de invitacion invalido")

        if invitacion.fue_usada:
            raise HTTPException(status_code=400, detail="Este codigo ya fue utilizado")

        if datetime.utcnow() > invitacion.fecha_expiracion:
            raise HTTPException(status_code=400, detail="Este codigo ha expirado")

        existing_user = db.query(VehicleUser).filter(
            VehicleUser.id_vehiculo == invitacion.id_vehiculo,
            VehicleUser.id_usuario == user_id,
        ).first()

        if existing_user:
            raise HTTPException(status_code=400, detail="Ya estas asignado a este vehiculo")

        existing_driver = db.query(VehicleUser).filter(
            VehicleUser.id_vehiculo == invitacion.id_vehiculo,
            VehicleUser.rol_vehiculo == "Conductor",
        ).first()

        if existing_driver:
            raise HTTPException(status_code=400, detail="Este vehiculo ya tiene un conductor asignado")

        vehicle_user = VehicleUser(
            id_usuario=user_id,
            id_vehiculo=invitacion.id_vehiculo,
            rol_vehiculo="Conductor",
        )

        invitacion.fue_usada = True

        db.add(vehicle_user)
        db.commit()

        vehicle = db.query(Vehicle).filter(Vehicle.id_vehiculo == invitacion.id_vehiculo).first()

        return {"mensaje": "Te has unido al vehiculo exitosamente", "placa_vehiculo": vehicle.placa}

    @staticmethod
    def remove_driver(db: Session, placa: str, user_id: int):
        """Elimina al conductor de un vehiculo si el usuario actual es propietario."""
        vehicle = VehicleService.get_vehicle_by_placa(db, placa)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehiculo no encontrado")

        owner = db.query(VehicleUser).filter(
            VehicleUser.id_vehiculo == vehicle.id_vehiculo,
            VehicleUser.id_usuario == user_id,
            VehicleUser.rol_vehiculo == "Propietario",
        ).first()

        if not owner:
            raise HTTPException(status_code=403, detail="No eres el propietario de este vehiculo")

        driver = db.query(VehicleUser).filter(
            VehicleUser.id_vehiculo == vehicle.id_vehiculo,
            VehicleUser.rol_vehiculo == "Conductor",
        ).first()

        if not driver:
            raise HTTPException(status_code=404, detail="Este vehiculo no tiene conductor asignado")

        db.delete(driver)
        db.commit()

        return {"mensaje": "Conductor eliminado exitosamente"}

    @staticmethod
    def get_my_vehicles(db: Session, user_id: int):
        """Retorna los vehiculos asignados al usuario con su rol."""
        results = db.query(Vehicle, VehicleUser.rol_vehiculo).join(
            VehicleUser, Vehicle.id_vehiculo == VehicleUser.id_vehiculo
        ).filter(
            VehicleUser.id_usuario == user_id
        ).all()

        vehicles = []
        for vehicle, rol in results:
            driver = next(
                (vu.usuario for vu in vehicle.vehicle_users if vu.rol_vehiculo == "Conductor"),
                None,
            )

            vehicles.append({
                "id_vehiculo": vehicle.id_vehiculo,
                "placa": vehicle.placa,
                "marca": vehicle.marca,
                "modelo": vehicle.modelo,
                "tipo_vehiculo": vehicle.tipo_vehiculo,
                "rol_vehiculo": rol,
                "conductor_id": driver.id_usuario if driver else None,
                "conductor_nombre": f"{driver.nombre} {driver.apellido}" if driver else None,
                "conductor_telefono": driver.telefono if driver else None,
            })

        return vehicles
