from pydantic import BaseModel, Field
from datetime import date, time
from typing import Optional
from app.models.BookingEntity import ConfirmationState

class BookingBase(BaseModel):
    id_usuario: int = Field(..., description="ID del usuario que solicita la cita")
    id_vehiculo: int = Field(..., description="ID del vehículo involucrado")
    fecha_solicitud: date = Field(..., description="Fecha en que se crea la solicitud (YYYY-MM-DD)")
    fecha_cita: date = Field(..., description="Fecha programada para la cita (YYYY-MM-DD)")
    hora_cita: time = Field(..., description="Hora programada para la cita (HH:MM:SS)")
    observaciones: Optional[str] = Field(None, max_length=255, description="Notas o fallas reportadas")

class BookingCreate(BookingBase):
    pass

class BookingResponse(BookingBase):
    id_agendamiento: int
    estado_confirmacion: ConfirmationState

    class Config:
        from_attributes = True