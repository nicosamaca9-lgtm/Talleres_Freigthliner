from pydantic import BaseModel
from app.models.VehicleEntity import TipoVehiculoEnum

class VehicleBase(BaseModel):
    placa: str
    marca: str
    modelo: str
    tipo_vehiculo: TipoVehiculoEnum 
    
    class Config:
        from_attributes = True

class VehicleCreate(VehicleBase):
    pass

from typing import Optional

class VehicleResponse(VehicleBase):
    id_vehiculo: int
    propietario_nombre: Optional[str] = None
    propietario_telefono: Optional[str] = None
    propietario_cedula: Optional[str] = None

class MyVehicleResponse(VehicleBase):
    id_vehiculo: int
    rol_vehiculo: str  # 'Propietario' o 'Conductor'