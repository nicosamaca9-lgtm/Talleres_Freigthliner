from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db  # Dependencia oficial de su proyecto
from app.schemas.BookingSchema import BookingCreate, BookingResponse
from app.services.BookingService import BookingService



router = APIRouter()

@router.post("/", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
def register_booking(booking: BookingCreate, db: Session = Depends(get_db)):
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
    return BookingService.create_booking(db=db, booking_data=booking)


@router.get("/", response_model=List[BookingResponse])
def list_bookings(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Endpoint para listar todos los agendamientos del sistema.
    """
    return BookingService.get_all_bookings(db=db, skip=skip, limit=limit)