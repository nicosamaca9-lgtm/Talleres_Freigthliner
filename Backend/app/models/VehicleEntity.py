# app/Models/VehicleEntity.py
from sqlalchemy.orm import relationship

from sqlalchemy import Column, Integer, String
from app.db.base import Base 

class Vehicle(Base):
    __tablename__ = "vehicles"

    id_vehiculo = Column(Integer, primary_key=True, index=True)
    placa = Column(String(10), unique=True, index=True, nullable=False)
    marca = Column(String(50), nullable=False)
    modelo = Column(String(50), nullable=False)
    tipo_vehiculo = Column(String(50), nullable=False) # Ej: Camión, Tractomula, Particular
    kilometraje_actual = Column(Integer, nullable=False)

    bookings = relationship("Booking", back_populates="vehicle")