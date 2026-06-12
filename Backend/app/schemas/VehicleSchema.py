# app/Schemas/VehicleSchema.py

from pydantic import BaseModel, Field
from typing import Optional

# Esquema base con los campos que se comparten al crear o leer
class VehicleBase(BaseModel):
    placa: str = Field(..., max_length=10, description="Placa única del vehículo")
    marca: str = Field(..., max_length=50, description="Marca del vehículo (ej. Hyundai)")
    modelo: str = Field(..., max_length=50, description="Modelo del vehículo (ej. Creta)")
    tipo_vehiculo: str = Field(..., max_length=50, description="Tipo (ej. Camión, Particular)")
    kilometraje_actual: int = Field(..., ge=0, description="Kilometraje actual, debe ser mayor o igual a 0")

# Esquema para cuando vayan a registrar un vehículo nuevo (el cliente envía esto)
class VehicleCreate(VehicleBase):
    pass

# Esquema para cuando FastAPI responda con los datos del vehículo (incluye el ID de la BD)
class VehicleResponse(VehicleBase):
    id_vehiculo: int

    class Config:
        from_attributes = True # Permite a Pydantic leer modelos de SQLAlchemy directamente