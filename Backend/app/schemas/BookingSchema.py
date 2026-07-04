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

class BookingUpdate(BaseModel):
    fecha_cita: date = Field(..., description="Nueva fecha programada para la cita (YYYY-MM-DD)")
    hora_cita: time = Field(..., description="Nueva hora programada para la cita (HH:MM:SS)")
    observaciones: Optional[str] = Field(None, max_length=255, description="Nuevas notas o fallas reportadas")

class BookingReject(BaseModel):
    motivo_rechazo: str = Field(..., min_length=1, max_length=255, description="Motivo por el cual se rechaza la cita")

class BookingResponse(BookingBase):
    id_agendamiento: int
    estado_confirmacion: ConfirmationState
    motivo_rechazo: Optional[str] = None
    cliente_nombre: Optional[str] = None
    cliente_telefono: Optional[str] = None
    cliente_cedula: Optional[str] = None
    placa_vehiculo: Optional[str] = None

    class Config:
        from_attributes = True