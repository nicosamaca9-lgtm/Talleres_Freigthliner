from sqlalchemy import Column, Integer, String, ForeignKey, Boolean, DateTime
from app.db.base import Base

class VehicleInvitation(Base):
    __tablename__ = "invitacion_vehiculo"

    id_invitacion = Column(Integer, primary_key=True, index=True)
    id_vehiculo = Column(Integer, ForeignKey("vehiculos.id_vehiculo", ondelete="CASCADE"), nullable=False)
    id_usuario_creador = Column(Integer, ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    codigo_secreto = Column(String(6), unique=True, index=True, nullable=False)
    fecha_expiracion = Column(DateTime, nullable=False)
    fue_usada = Column(Boolean, default=False)
