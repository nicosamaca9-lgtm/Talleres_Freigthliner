from sqlalchemy.orm import Session
from app.models.VehicleEntity import Vehicle
from app.models.VehicleUserEntity import VehicleUser
from app.models.VehicleInvitationEntity import VehicleInvitation
from app.schemas.VehicleSchema import VehicleCreate
from fastapi import HTTPException, status
import random
import string
from datetime import datetime, timedelta

class VehicleService:

    @staticmethod
    def get_vehicle_by_placa(db: Session, placa: str):
        """Busca un vehículo en la base de datos por su placa"""
        return db.query(Vehicle).filter(Vehicle.placa == placa).first()

    @staticmethod
    def create_vehicle(db: Session, vehicle_data: VehicleCreate, user_id: int):
        """Registra un nuevo vehículo y asigna al creador como Propietario"""

        db_vehicle = Vehicle(
            placa=vehicle_data.placa.upper(),
            marca=vehicle_data.marca,
            modelo=vehicle_data.modelo,
            tipo_vehiculo=vehicle_data.tipo_vehiculo
        )
        
        db.add(db_vehicle)
        db.commit()
        db.refresh(db_vehicle)
        
        # Asignar como Propietario
        vehicle_user = VehicleUser(
            id_usuario=user_id,
            id_vehiculo=db_vehicle.id_vehiculo,
            rol_vehiculo="Propietario"
        )
        db.add(vehicle_user)
        db.commit()
        
        return db_vehicle

    @staticmethod
    def get_all_vehicles(db: Session, skip: int = 0, limit: int = 100):
        """Retorna la lista de todos los vehículos registrados"""
        return db.query(Vehicle).offset(skip).limit(limit).all()

    @staticmethod
    def generate_invitation(db: Session, placa: str, user_id: int):
        """Genera un código de invitación para un vehículo si el usuario es el dueño"""
        vehicle = VehicleService.get_vehicle_by_placa(db, placa)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")
            
        # Verificar que el usuario sea el dueño
        owner = db.query(VehicleUser).filter(
            VehicleUser.id_vehiculo == vehicle.id_vehiculo,
            VehicleUser.id_usuario == user_id,
            VehicleUser.rol_vehiculo == "Propietario"
        ).first()
        
        if not owner:
            raise HTTPException(status_code=403, detail="No eres el propietario de este vehículo")
            
        # Generar código alfanumérico aleatorio de 6 caracteres
        codigo = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        
        # Expiración: 12 horas (según solicitud)
        expiracion = datetime.utcnow() + timedelta(hours=12)
        
        invitacion = VehicleInvitation(
            id_vehiculo=vehicle.id_vehiculo,
            id_usuario_creador=user_id,
            codigo_secreto=codigo,
            fecha_expiracion=expiracion
        )
        
        db.add(invitacion)
        db.commit()
        
        return {"codigo_secreto": codigo, "fecha_expiracion": expiracion}

    @staticmethod
    def redeem_invitation(db: Session, codigo_secreto: str, user_id: int):
        """Permite a un usuario canjear un código para convertirse en conductor"""
        invitacion = db.query(VehicleInvitation).filter(VehicleInvitation.codigo_secreto == codigo_secreto).first()
        
        if not invitacion:
            raise HTTPException(status_code=404, detail="Código de invitación inválido")
            
        if invitacion.fue_usada:
            raise HTTPException(status_code=400, detail="Este código ya fue utilizado")
            
        if datetime.utcnow() > invitacion.fecha_expiracion:
            raise HTTPException(status_code=400, detail="Este código ha expirado")
            
        # Verificar si ya está asignado al vehículo
        existing_user = db.query(VehicleUser).filter(
            VehicleUser.id_vehiculo == invitacion.id_vehiculo,
            VehicleUser.id_usuario == user_id
        ).first()
        
        if existing_user:
            raise HTTPException(status_code=400, detail="Ya estás asignado a este vehículo")
            
        # Asignar como conductor
        vehicle_user = VehicleUser(
            id_usuario=user_id,
            id_vehiculo=invitacion.id_vehiculo,
            rol_vehiculo="Conductor"
        )
        
        invitacion.fue_usada = True
        
        db.add(vehicle_user)
        db.commit()
        
        vehicle = db.query(Vehicle).filter(Vehicle.id_vehiculo == invitacion.id_vehiculo).first()
        
        return {"mensaje": "Te has unido al vehículo exitosamente", "placa_vehiculo": vehicle.placa}

    @staticmethod
    def get_my_vehicles(db: Session, user_id: int):
        """Retorna los vehículos asignados al usuario con su rol (Propietario o Conductor)"""
        results = db.query(Vehicle, VehicleUser.rol_vehiculo).join(
            VehicleUser, Vehicle.id_vehiculo == VehicleUser.id_vehiculo
        ).filter(
            VehicleUser.id_usuario == user_id
        ).all()

        return [
            {
                "id_vehiculo": vehicle.id_vehiculo,
                "placa": vehicle.placa,
                "marca": vehicle.marca,
                "modelo": vehicle.modelo,
                "tipo_vehiculo": vehicle.tipo_vehiculo,
                "rol_vehiculo": rol
            }
            for vehicle, rol in results
        ]