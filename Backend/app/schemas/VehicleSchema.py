from pydantic import BaseModel
from app.models.VehicleEntity import TipoVehiculoEnum # Importamos el Enum del modelo

class VehicleBase(BaseModel):
    placa: str
    marca: str
    modelo: str
    tipo_vehiculo: TipoVehiculoEnum 

class VehicleCreate(VehicleBase):
    pass


class VehicleResponse(VehicleBase):
    id_vehiculo: int

    class Config:
        from_attributes = True