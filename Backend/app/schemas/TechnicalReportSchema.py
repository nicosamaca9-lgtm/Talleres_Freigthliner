from pydantic.fields import Field
from datetime import datetime
from pydantic import BaseModel, EmailStr, ConfigDict
from app.core.Enum import UserRole


class TechnicalReportRegister(BaseModel):
    id_orden: int
    diagnostico: str
    recomendaciones: str
    repuestos_usados: str | None


class TechnicalReportUpdate(BaseModel):
    diagnostico: str | None = None
    recomendaciones: str | None = None
    repuestos_usados: str | None = None


class TechnicalReportResponse(BaseModel):
    id_informe_tecnico: int
    id_usuario: int
    id_orden: int
    fecha_reporte: datetime
    diagnostico: str
    recomendaciones: str
    repuestos_usados: str | None
    estado_revision: str
    observaciones_admin: str | None

class TechnicalReportReview(BaseModel):
    estado_revision: str
    observaciones_admin: str | None = None

    model_config = ConfigDict(from_attributes=True)
