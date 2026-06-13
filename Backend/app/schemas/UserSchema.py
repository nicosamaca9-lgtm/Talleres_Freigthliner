# app/Schemas/UserSchema.py

from datetime import datetime
from pydantic import BaseModel, EmailStr, ConfigDict
from app.core.Enum import UserRole


class MechanicRegister(BaseModel):
    nombre: str
    apellido: str
    telefono: str | None = None
    correo: EmailStr
    password: str
    rol: UserRole = UserRole.client
    especialidad: str | None = None


class UserResponse(BaseModel):
    id_usuario: int
    nombre: str
    apellido: str
    telefono: str | None
    correo: EmailStr
    fecha_registro: datetime
    rol: UserRole
    especialidad: str | None

    model_config = ConfigDict(from_attributes=True)
