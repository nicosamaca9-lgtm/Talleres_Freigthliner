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
    
    # Mantener el kilometraje (¡ojo!, a Nicolás se le había borrado en su cambio)
    kilometraje_actual = Column(Integer, nullable=False, default=0)

    # 2. Conservamos tu relación para los agendamientos
    bookings = relationship("Booking", back_populates="vehicle")