# app/Api/VehicleEndpoint.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db  # Dependencia para obtener la sesión de la BD
from app.Schemas.VehicleSchema import VehicleCreate, VehicleResponse
from app.Services.VehicleService import VehicleService

router = APIRouter()

@router.post("/", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
def register_vehicle(vehicle: VehicleCreate, db: Session = Depends(get_db)):
    """
    Endpoint para registrar un nuevo vehículo.
    Valida que la placa no esté duplicada antes de guardarlo.
    """
    # 1. Verificar si el vehículo ya existe por placa
    db_vehicle = VehicleService.get_vehicle_by_placa(db, placa=vehicle.placa)
    if db_vehicle:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un vehículo registrado con esta placa."
        )
    
    # 2. Si no existe, lo creamos a través del servicio
    return VehicleService.create_vehicle(db=db, vehicle_data=vehicle)


@router.get("/", response_model=List[VehicleResponse])
def list_vehicles(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Endpoint para listar todos los vehículos registrados en el sistema.
    """
    return VehicleService.get_all_vehicles(db=db, skip=skip, limit=limit)


@router.get("/{placa}", response_model=VehicleResponse)
def get_vehicle(placa: str, db: Session = Depends(get_db)):
    """
    Endpoint para buscar un vehículo específico usando su placa.
    """
    db_vehicle = VehicleService.get_vehicle_by_placa(db, placa=placa)
    if not db_vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehículo no encontrado."
        )
    return db_vehicle