from pydantic.fields import Field
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.schemas.UserSchema import UserResponse


class CommentRegister(BaseModel):
    id_usuario: int
    rating: int = Field(..., ge=1, le=5)
    comentario: str


class CommentUpdate(BaseModel):
    rating: int | None = Field(None, ge=1, le=5)
    comentario: str | None = None


class CommentResponse(BaseModel):
    id_comentario: int
    id_usuario: int
    rating: int
    comentario: str
    fecha_registro: datetime
    usuario: UserResponse

    model_config = ConfigDict(from_attributes=True)
