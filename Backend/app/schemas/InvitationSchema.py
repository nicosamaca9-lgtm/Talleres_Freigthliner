from pydantic import BaseModel, Field
from datetime import datetime

class InvitationCreateResponse(BaseModel):
    codigo_secreto: str
    fecha_expiracion: datetime

class InvitationRedeemRequest(BaseModel):
    codigo_secreto: str = Field(..., min_length=6, max_length=6, description="Código alfanumérico de 6 caracteres")

class InvitationRedeemResponse(BaseModel):
    mensaje: str
    placa_vehiculo: str
