from pydantic.fields import Field
from pydantic import BaseModel, EmailStr


class ClientRegister(BaseModel):
    nombre: str
    apellido: str
    telefono: str = Field(min_length=10, max_length=10)
    cedula: str
    correo: EmailStr
    password: str


class LoginRequest(BaseModel):
    correo: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str