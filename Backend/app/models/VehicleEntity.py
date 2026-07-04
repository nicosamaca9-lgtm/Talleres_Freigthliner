import enum
from sqlalchemy import Column, Integer, String, Enum as SQLEnum
from sqlalchemy.orm import relationship
from app.db.base import Base

# 1. Conservamos el Enum que creó Nicolás
class TipoVehiculoEnum(str, enum.Enum):
    camion = "Camion"
    volqueta = "Volqueta"
    patineta = "Patineta"
    mula = "Mula"
    bus = "Bus"
    otro = "Otro"

class Vehicle(Base):
    __tablename__ = "vehiculos"  # Nicolás lo cambió a singular

    id_vehiculo = Column(Integer, primary_key=True, index=True)
    placa = Column(String(10), unique=True, index=True, nullable=False)
    marca = Column(String(50), nullable=False)
    modelo = Column(String(50), nullable=False)
    
    # Usamos el Enum estricto de Nicolás
    tipo_vehiculo = Column(SQLEnum(TipoVehiculoEnum), nullable=False)
    

    # 2. Conservamos tu relación para los agendamientos
    bookings = relationship("Booking", back_populates="vehicle")
    vehicle_users = relationship("VehicleUser", back_populates="vehicle")

    @property
    def propietario_nombre(self):
        owner = next((vu.usuario for vu in self.vehicle_users if vu.rol_vehiculo == "Propietario"), None)
        return owner.nombre + " " + owner.apellido if owner else None

    @property
    def propietario_telefono(self):
        owner = next((vu.usuario for vu in self.vehicle_users if vu.rol_vehiculo == "Propietario"), None)
        return owner.telefono if owner else None

    @property
    def propietario_cedula(self):
        owner = next((vu.usuario for vu in self.vehicle_users if vu.rol_vehiculo == "Propietario"), None)
        return owner.cedula if owner else None