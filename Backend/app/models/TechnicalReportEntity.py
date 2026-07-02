from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.base import Base


class TechnicalReport(Base):
    __tablename__ = "informes_tecnicos"

    id_informe_tecnico = Column(Integer, primary_key=True, index=True)
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=False)
    id_orden = Column(Integer, ForeignKey("ordenes_servicio.id_orden"), nullable=False)
    fecha_reporte = Column(DateTime(timezone=True), server_default=func.now())
    diagnostico = Column(String(500), nullable=False)
    recomendaciones = Column(String(1500), nullable=True)
    repuestos_usados = Column(String(1000), nullable=True)
    
    # Campos de revisión del administrador
    estado_revision = Column(String(50), default="PENDIENTE", nullable=False)
    observaciones_admin = Column(String(1000), nullable=True)
