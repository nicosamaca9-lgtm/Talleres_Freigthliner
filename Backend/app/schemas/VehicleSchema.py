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

class VehicleResponse(VehicleBase):
    id_vehiculo: int

class MyVehicleResponse(VehicleBase):
    id_vehiculo: int
    rol_vehiculo: str  # 'Propietario' o 'Conductor'