import enum
from sqlalchemy import Column, Integer, String, Date, Time, Enum, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base 

# Definimos los estados para las pruebas de Postman
class ConfirmationState(str, enum.Enum):
    PENDIENTE = "PENDIENTE"
    CONFIRMADO = "CONFIRMADO"
    RECHAZADO = "RECHAZADO"
    CANCELADO = "CANCELADO"
    EN_TALLER = "EN_TALLER"
    CANCELADO_POR_SISTEMA = "CANCELADO_POR_SISTEMA"

class Booking(Base):
    __tablename__ = "agendamientos"

    id_agendamiento = Column(Integer, primary_key=True, index=True)
    
    # Llaves foráneas
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=False) 
    id_vehiculo = Column(Integer, ForeignKey("vehiculos.id_vehiculo"), nullable=False)

    # Campos del diagrama
    fecha_solicitud = Column(Date, nullable=False)
    fecha_cita = Column(Date, nullable=False)
    hora_cita = Column(Time, nullable=False)
    observaciones = Column(String(255), nullable=True)
    estado_confirmacion = Column(Enum(ConfirmationState), default=ConfirmationState.PENDIENTE, nullable=False)
    motivo_rechazo = Column(String(255), nullable=True)

    # Relación orientada a objetos con la clase de tu compañero
    vehicle = relationship("Vehicle", back_populates="bookings")
    user = relationship("User")

    @property
    def cliente_nombre(self):
        return f"{self.user.nombre} {self.user.apellido}" if self.user else "Desconocido"

    @property
    def cliente_telefono(self):
        return self.user.telefono if self.user else ""

    @property
    def cliente_cedula(self):
        return self.user.cedula if self.user else ""

    @property
    def placa_vehiculo(self):
        return self.vehicle.placa if self.vehicle else "Sin Placa"