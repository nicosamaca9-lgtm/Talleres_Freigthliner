from sqlalchemy.orm import Session
from app.Core.security import hash_password
from app.Repositories.UserRepository import (
    get_user_by_email,
    create_user,
    get_user_by_email_or_phone,
)
from app.Models.UserEntity import User
from app.Core.Enum import UserRole
from app.Core.Exceptions import UserAlreadyExistsError
from app.Schemas.UserSchema import MechanicRegister


def register_mechanic(db: Session, data: MechanicRegister):
    """Registra un nuevo usuario con rol mecánico."""
    if not data.especialidad or not data.especialidad.strip():
        raise ValueError("La especialidad es obligatoria para registrar un mecánico")

    existing_user = get_user_by_email_or_phone(db, data.correo, data.telefono)

    if existing_user:
        if existing_user.correo == data.correo:
            raise UserAlreadyExistsError("El correo ya está registrado")
        if existing_user.telefono == data.telefono:
            raise UserAlreadyExistsError("El teléfono ya está registrado")

    user = User(
        nombre=data.nombre,
        apellido=data.apellido,
        telefono=data.telefono,
        correo=data.correo,
        password_hash=hash_password(data.password),
        rol=UserRole.mechanic,
        especialidad=data.especialidad,
    )

    return create_user(db, user)
