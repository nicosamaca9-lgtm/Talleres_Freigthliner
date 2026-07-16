from pydantic import BaseModel, Field
from datetime import date, time
from typing import Optional
from app.models.ServiceOrderEntity import ServiceOrderState

class ServiceOrderBase(BaseModel):
    numero_orden: Optional[str] = Field(None, description="Consecutivo automático, opcional al crear")
    id_vehiculo: Optional[int] = Field(None, description="ID del vehículo")
    id_mecanico: Optional[int] = Field(None, description="ID del mecánico asignado (puede ser asignado después)")
    id_agendamiento: Optional[int] = Field(None, description="ID del agendamiento si aplica")
    
    fecha_ingreso: date
    hora_ingreso: time
    fecha_salida: Optional[date] = None
    hora_salida: Optional[time] = None

    cliente_nombre: str = Field(..., max_length=100)
    cliente_identificacion: str = Field(..., max_length=50)
    cliente_telefono: str = Field(..., max_length=20)
    
    conductor_nombre: Optional[str] = Field(None, max_length=100)
    conductor_telefono: Optional[str] = Field(None, max_length=20)

    kilometraje_ingreso: int = Field(..., ge=0)
    nivel_combustible: str = Field(..., max_length=50)

    trabajos_a_realizar: str = Field(..., description="DIAGNOSTICO Y SOLICITUD")
    informe_trabajo: Optional[str] = Field(None, description="INFORME DE TRABAJO REALIZADO")

    estado_orden: ServiceOrderState = Field(default=ServiceOrderState.EN_DIAGNOSTICO)

class ServiceOrderCreate(ServiceOrderBase):
    id_vehiculo: Optional[int] = Field(None, description="ID del vehículo (si ya está registrado)")
    placa_vehiculo_nuevo: Optional[str] = Field(None, description="Placa del vehículo a crear si no está registrado")

class ServiceOrderUpdate(BaseModel):
    id_mecanico: Optional[int] = None
    informe_trabajo: Optional[str] = None
    estado_orden: Optional[ServiceOrderState] = None
    fecha_salida: Optional[date] = None
    hora_salida: Optional[time] = None

class ServiceOrderResponse(ServiceOrderBase):
    id_orden: int
    placa_vehiculo: Optional[str] = None
    mecanico_nombre: Optional[str] = None

    class Config:
        from_attributes = True
