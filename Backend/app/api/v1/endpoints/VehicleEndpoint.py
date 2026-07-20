from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.schemas.VehicleSchema import (
    VehicleCreate,
    VehicleResponse,
    MyVehicleResponse,
)
from app.schemas.InvitationSchema import (
    InvitationCreateResponse,
    InvitationRedeemRequest,
    InvitationRedeemResponse,
)
from app.services.VehicleService import VehicleService
from app.api.v1.deps import get_current_user
from app.models.UserEntity import User

# Corrige esto al principio del archivo:
from app.db.base import Base
from app.db.session import engine

# Esto creara las tablas apenas se recargue el servidor si no existen
Base.metadata.create_all(bind=engine)

router = APIRouter()


@router.post("/", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
def register_vehicle(
    vehicle: VehicleCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Endpoint para registrar un nuevo vehiculo.
    El usuario logueado quedara automaticamente asignado como el Propietario.
    """
    return VehicleService.register_or_claim_vehicle(
        db=db,
        vehicle_data=vehicle,
        user_id=current_user.id_usuario,
    )


@router.post("/{placa}/invitations", response_model=InvitationCreateResponse)
def create_invitation(
    placa: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Genera un codigo aleatorio para invitar a un conductor al vehiculo.
    Solo el propietario del vehiculo puede ejecutar esto.
    """
    return VehicleService.generate_invitation(
        db=db,
        placa=placa,
        user_id=current_user.id_usuario,
    )


@router.post("/invitations/redeem", response_model=InvitationRedeemResponse)
def redeem_invitation(
    data: InvitationRedeemRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Permite a un usuario (Conductor) unirse a un vehiculo ingresando el codigo secreto de 6 digitos.
    """
    return VehicleService.redeem_invitation(
        db=db,
        codigo_secreto=data.codigo_secreto,
        user_id=current_user.id_usuario,
    )


@router.delete("/{placa}/driver")
def remove_driver(
    placa: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Elimina al conductor asignado a un vehiculo.
    Solo el propietario puede ejecutar esta accion.
    """
    return VehicleService.remove_driver(
        db=db,
        placa=placa,
        user_id=current_user.id_usuario,
    )


@router.get("/mine", response_model=List[MyVehicleResponse])
def my_vehicles(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retorna los vehiculos del usuario logueado con su rol (Propietario o Conductor).
    """
    return VehicleService.get_my_vehicles(db=db, user_id=current_user.id_usuario)


@router.get("/", response_model=List[VehicleResponse])
def list_vehicles(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Endpoint para listar todos los vehiculos registrados en el sistema.
    """
    return VehicleService.get_all_vehicles(db=db, skip=skip, limit=limit)


@router.get("/{placa}", response_model=VehicleResponse)
def get_vehicle(placa: str, db: Session = Depends(get_db)):
    """
    Endpoint para buscar un vehiculo especifico usando su placa.
    """
    db_vehicle = VehicleService.get_vehicle_by_placa(db, placa=placa)
    if not db_vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehiculo no encontrado.",
        )
    return db_vehicle
