# app/Services/VehicleService.py

from sqlalchemy.orm import Session
from app.models.VehicleEntity import Vehicle
from app.schemas.VehicleSchema import VehicleCreate

class VehicleService:

    @staticmethod
    def get_vehicle_by_placa(db: Session, placa: str):
        """Busca un vehículo en la base de datos por su placa"""
        return db.query(Vehicle).filter(Vehicle.placa == placa).first()

    @staticmethod
    def create_vehicle(db: Session, vehicle_data: VehicleCreate):
        """Registra un nuevo vehículo en la base de datos"""
        # Creamos la instancia del modelo SQLAlchemy con los datos del Schema
        db_vehicle = Vehicle(
            placa=vehicle_data.placa.upper(),  # Guardamos la placa siempre en mayúsculas
            marca=vehicle_data.marca,
            modelo=vehicle_data.modelo,
            tipo_vehiculo=vehicle_data.tipo_vehiculo,
            kilometraje_actual=vehicle_data.kilometraje_actual
        )
        
        # Lo agregamos a la sesión y hacemos el commit para impactar la BD
        db.add(db_vehicle)
        db.commit()
        db.refresh(db_vehicle)  # Refrescamos para obtener el id_vehiculo asignado
        
        return db_vehicle

    @staticmethod
    def get_all_vehicles(db: Session, skip: int = 0, limit: int = 100):
        """Retorna la lista de todos los vehículos registrados"""
        return db.query(Vehicle).offset(skip).limit(limit).all()