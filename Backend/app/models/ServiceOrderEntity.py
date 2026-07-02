import enum
from sqlalchemy import Column, Integer, String, Text, Date, Time, Enum as SQLEnum, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base

class ServiceOrderState(str, enum.Enum):
    EN_DIAGNOSTICO = "EN_DIAGNOSTICO"
    EN_REPARACION = "EN_REPARACION"
    LISTO_PARA_ENTREGA = "LISTO_PARA_ENTREGA"
    ENTREGADO = "ENTREGADO"

class ServiceOrder(Base):
    __tablename__ = "ordenes_servicio"

    id_orden = Column(Integer, primary_key=True, index=True)
    numero_orden = Column(String(20), unique=True, index=True, nullable=False)
    id_vehiculo = Column(Integer, ForeignKey("vehiculos.id_vehiculo", ondelete="RESTRICT"), nullable=False)
    id_mecanico = Column(Integer, ForeignKey("usuarios.id_usuario", ondelete="SET NULL"), nullable=True)
    id_agendamiento = Column(Integer, ForeignKey("agendamientos.id_agendamiento", ondelete="SET NULL"), nullable=True)

    # Fechas y Horas (Snapshot del ingreso)
    fecha_ingreso = Column(Date, nullable=False)
    hora_ingreso = Column(Time, nullable=False)
    fecha_salida = Column(Date, nullable=True)
    hora_salida = Column(Time, nullable=True)

    # Datos del Cliente/Empresa (Snapshot de la hoja física)
    cliente_nombre = Column(String(100), nullable=False)
    cliente_identificacion = Column(String(50), nullable=False)
    cliente_telefono = Column(String(20), nullable=False)

    # Datos del Conductor
    conductor_nombre = Column(String(100), nullable=True)
    conductor_telefono = Column(String(20), nullable=True)

    # Estado del Vehículo al Ingreso
    kilometraje_ingreso = Column(Integer, nullable=False)
    nivel_combustible = Column(String(50), nullable=False) # Ej: "1/4", "Medio", "Full"

    # Trabajos y Diagnósticos (Secciones de la hoja física)
    trabajos_a_realizar = Column(Text, nullable=False) # 1. DIAGNOSTICO Y SOLICITUD
    informe_trabajo = Column(Text, nullable=True)      # 2. INFORME DE TRABAJO REALIZADO

    # Estado general de la orden
    estado_orden = Column(SQLEnum(ServiceOrderState), default=ServiceOrderState.EN_DIAGNOSTICO, nullable=False)

    # Relaciones (opcionales para usar en consultas ORM)
    vehiculo = relationship("Vehicle")
    mecanico = relationship("User")
