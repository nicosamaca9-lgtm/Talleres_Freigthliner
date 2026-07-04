from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class ReceiptItemBase(BaseModel):
    descripcion: str
    cantidad: int = 1
    valor_unitario: float
    porcentaje_iva: float = 19.0

class ReceiptItemCreate(ReceiptItemBase):
    pass

class ReceiptItemResponse(ReceiptItemBase):
    id_detalle: int
    id_recibo: int
    total: float

    class Config:
        from_attributes = True

class ReceiptBase(BaseModel):
    id_orden: Optional[int] = None
    tipo_documento: str = "RECIBO"
    cliente_nombre: str
    cliente_nit: str
    cliente_telefono: Optional[str] = None
    cliente_direccion: Optional[str] = None
    cliente_ciudad: str = "DUITAMA"
    vendedor: Optional[str] = None
    placa: str
    forma_pago: Optional[str] = None
    concepto: str = "TRABAJO REALIZADO"
    nota_pie: str = "COTIZACION VALIDA POR 15 DIAS"

class ReceiptCreate(ReceiptBase):
    items: List[ReceiptItemCreate]

class ReceiptUpdate(BaseModel):
    tipo_documento: Optional[str] = None
    cliente_nombre: Optional[str] = None
    cliente_nit: Optional[str] = None
    cliente_telefono: Optional[str] = None
    cliente_direccion: Optional[str] = None
    cliente_ciudad: Optional[str] = None
    vendedor: Optional[str] = None
    placa: Optional[str] = None
    forma_pago: Optional[str] = None
    concepto: Optional[str] = None
    nota_pie: Optional[str] = None
    items: Optional[List[ReceiptItemCreate]] = None

class ReceiptResponse(ReceiptBase):
    id_recibo: int
    numero_recibo: str
    estado: str
    fecha_emision: datetime
    fecha_vencimiento: Optional[datetime] = None
    subtotal: float
    iva_total: float
    total: float
    valor_en_letras: Optional[str] = None
    items: List[ReceiptItemResponse] = []

    class Config:
        from_attributes = True
