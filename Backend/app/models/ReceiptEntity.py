from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.base import Base

class Receipt(Base):
    __tablename__ = "recibos"

    id_recibo = Column(Integer, primary_key=True, index=True)
    numero_recibo = Column(String(20), unique=True, index=True, nullable=False)
    id_orden = Column(Integer, ForeignKey("ordenes_servicio.id_orden", ondelete="SET NULL"), nullable=True)
    
    fecha_emision = Column(DateTime(timezone=True), server_default=func.now())
    fecha_vencimiento = Column(DateTime(timezone=True), nullable=True)
    
    tipo_documento = Column(String(50), default="RECIBO", nullable=False) # COTIZACION o RECIBO
    estado = Column(String(50), default="BORRADOR", nullable=False) # BORRADOR o FINALIZADO

    # Snapshot fields (in case the client changes later)
    cliente_nombre = Column(String(100), nullable=False)
    cliente_nit = Column(String(50), nullable=False)
    cliente_telefono = Column(String(20), nullable=True)
    cliente_direccion = Column(String(150), nullable=True)
    cliente_ciudad = Column(String(100), default="DUITAMA")
    vendedor = Column(String(100), nullable=True)
    placa = Column(String(20), nullable=False)
    forma_pago = Column(String(50), nullable=True) # E.g. Contado, Credito
    
    concepto = Column(String(200), default="TRABAJO REALIZADO")
    
    # Totals
    subtotal = Column(Float, default=0.0)
    iva_total = Column(Float, default=0.0)
    total = Column(Float, default=0.0)
    valor_en_letras = Column(String(255), nullable=True)
    nota_pie = Column(String(255), default="COTIZACION VALIDA POR 15 DIAS")
    
    # Relationships
    orden_servicio = relationship("ServiceOrder")
    items = relationship("ReceiptItem", back_populates="recibo", cascade="all, delete-orphan")

class ReceiptItem(Base):
    __tablename__ = "detalles_recibo"

    id_detalle = Column(Integer, primary_key=True, index=True)
    id_recibo = Column(Integer, ForeignKey("recibos.id_recibo", ondelete="CASCADE"), nullable=False)
    
    descripcion = Column(String(255), nullable=False)
    cantidad = Column(Integer, default=1, nullable=False)
    valor_unitario = Column(Float, nullable=False)
    porcentaje_iva = Column(Float, default=19.0) # 19%
    total = Column(Float, nullable=False)
    
    recibo = relationship("Receipt", back_populates="items")
