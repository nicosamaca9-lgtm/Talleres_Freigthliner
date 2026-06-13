from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.schemas.VehicleSchema import VehicleCreate, VehicleResponse, MyVehicleResponse
from app.schemas.InvitationSchema import InvitationCreateResponse, InvitationRedeemRequest, InvitationRedeemResponse
from app.services.VehicleService import VehicleService
from app.api.v1.deps import get_current_user
from app.models.UserEntity import User

# Corrige esto al principio del archivo:
from app.db.base import Base
from app.db.session import engine

# Esto creará las tablas apenas se recargue el servidor si no existen
Base.metadata.create_all(bind=engine)

router = APIRouter()

@router.post("/", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
def register_vehicle(vehicle: VehicleCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Endpoint para registrar un nuevo vehículo.
    El usuario logueado quedará automáticamente asignado como el Propietario.
    """
    db_vehicle = VehicleService.get_vehicle_by_placa(db, placa=vehicle.placa)
    if db_vehicle:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un vehículo registrado con esta placa."
        )
    
    return VehicleService.create_vehicle(db=db, vehicle_data=vehicle, user_id=current_user.id_usuario)


@router.post("/{placa}/invitations", response_model=InvitationCreateResponse)
def create_invitation(placa: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Genera un código aleatorio para invitar a un conductor al vehículo.
    Solo el propietario del vehículo puede ejecutar esto.
    """
    return VehicleService.generate_invitation(db=db, placa=placa, user_id=current_user.id_usuario)


@router.post("/invitations/redeem", response_model=InvitationRedeemResponse)
def redeem_invitation(data: InvitationRedeemRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Permite a un usuario (Conductor) unirse a un vehículo ingresando el código secreto de 6 dígitos.
    """
    return VehicleService.redeem_invitation(db=db, codigo_secreto=data.codigo_secreto, user_id=current_user.id_usuario)


@router.get("/mine", response_model=List[MyVehicleResponse])
def my_vehicles(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Retorna los vehículos del usuario logueado con su rol (Propietario o Conductor).
    """
    return VehicleService.get_my_vehicles(db=db, user_id=current_user.id_usuario)


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