from sqlalchemy import Column, Integer, String, ForeignKey
from app.db.base import Base

class VehicleUser(Base):
    __tablename__ = "vehiculos_usuarios"

    id = Column(Integer, primary_key=True, index=True)
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    id_vehiculo = Column(Integer, ForeignKey("vehiculos.id_vehiculo", ondelete="CASCADE"), nullable=False)
    rol_vehiculo = Column(String(50), nullable=False) # 'Propietario' o 'Conductor'

    from sqlalchemy.orm import relationship
    usuario = relationship("User")
    vehicle = relationship("Vehicle", back_populates="vehicle_users")
