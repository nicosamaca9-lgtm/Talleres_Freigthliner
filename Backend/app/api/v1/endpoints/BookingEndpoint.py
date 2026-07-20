from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.api.v1.deps import get_current_user
from app.models.UserEntity import User
from app.schemas.BookingSchema import BookingCreate, BookingResponse, BookingUpdate
from app.services.BookingService import BookingService



router = APIRouter()

@router.post("/", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
def register_booking(
    booking: BookingCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """
    Endpoint para crear una nueva cita/agendamiento mecánico.
    Valida primero que el vehículo exista antes de agendar.
    """
    # Validamos si el vehículo existe cruzando con el servicio de tu compañero
    from app.services.VehicleService import VehicleService
    # Como no tenemos buscar por id directo, podemos intentar por su ID usando query rápido
    from app.models.VehicleEntity import Vehicle
    db_vehicle = db.query(Vehicle).filter(Vehicle.id_vehiculo == booking.id_vehiculo).first()
    
    if not db_vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se puede agendar cita. El vehículo especificado no existe."
        )

    # Si pasa la validación, lo creamos
    return BookingService.create_booking(
        db=db,
        booking_data=booking,
        background_tasks=background_tasks,
    )


@router.get("/", response_model=List[BookingResponse])
def list_bookings(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Endpoint para listar todos los agendamientos del sistema.
    """
    return BookingService.get_all_bookings(db=db, skip=skip, limit=limit)

@router.get("/user/{id_usuario}", response_model=List[BookingResponse])
def list_bookings_by_user(id_usuario: int, db: Session = Depends(get_db)):
    """
    Endpoint para listar agendamientos activos de un usuario específico.
    """
    return BookingService.get_bookings_by_user(db=db, id_usuario=id_usuario)

@router.put("/{id_agendamiento}", response_model=BookingResponse)
def update_booking(
    id_agendamiento: int,
    booking: BookingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Endpoint para reprogramar una cita (sujeto a regla de 3 horas).
    """
    return BookingService.update_booking(
        db=db,
        id_agendamiento=id_agendamiento,
        booking_data=booking,
        current_user=current_user,
    )

@router.delete("/{id_agendamiento}")
def cancel_booking(id_agendamiento: int, db: Session = Depends(get_db)):
    """
    Endpoint para cancelar una cita (sujeto a regla de 3 horas).
    """
    return BookingService.cancel_booking(db=db, id_agendamiento=id_agendamiento)
