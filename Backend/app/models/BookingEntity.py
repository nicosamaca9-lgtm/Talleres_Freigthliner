import enum
from sqlalchemy import Column, Integer, String, Date, Time, Enum, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base 

# Definimos los estados para las pruebas de Postman
class ConfirmationState(str, enum.Enum):
    PENDIENTE = "PENDIENTE"
    CONFIRMADO = "CONFIRMADO"
    CANCELADO = "CANCELADO"

class Booking(Base):
    __tablename__ = "agendamientos"

    id_agendamiento = Column(Integer, primary_key=True, index=True)
    
    # Llaves foráneas (id_usuario queda como Integer por ahora)
    id_usuario = Column(Integer, nullable=False) 
    id_vehiculo = Column(Integer, ForeignKey("vehiculos.id_vehiculo"), nullable=False)

    # Campos del diagrama
    fecha_solicitud = Column(Date, nullable=False)
    fecha_cita = Column(Date, nullable=False)
    hora_cita = Column(Time, nullable=False)
    observaciones = Column(String(255), nullable=True)
    estado_confirmacion = Column(Enum(ConfirmationState), default=ConfirmationState.PENDIENTE, nullable=False)

    # Relación orientada a objetos con la clase de tu compañero
    vehicle = relationship("Vehicle", back_populates="bookings")