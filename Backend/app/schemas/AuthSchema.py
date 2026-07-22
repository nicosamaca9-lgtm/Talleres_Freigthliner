from pydantic.fields import Field
from pydantic import BaseModel, EmailStr


class ClientRegister(BaseModel):
    nombre: str
    apellido: str
    telefono: str = Field(min_length=7, max_length=15)
    cedula: str
    correo: EmailStr
    password: str


class UpdateProfileRequest(BaseModel):
    nombre: str
    apellido: str
    telefono: str = Field(min_length=7, max_length=15)
    cedula: str


class LoginRequest(BaseModel):
    correo: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str