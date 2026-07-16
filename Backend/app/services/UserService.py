from sqlalchemy.orm import Session
from app.core.security import hash_password
from app.repositories.UserRepository import (
    get_user_by_email,
    create_user,
    get_user_by_unique_fields,
)
from app.models.UserEntity import User
from app.core.Enum import UserRole
from app.core.Exceptions import UserAlreadyExistsError
from app.schemas.UserSchema import MechanicRegister


def register_mechanic(db: Session, data: MechanicRegister):
    """Registra un nuevo usuario con rol mecánico o secretario."""
    # La especialidad solo es obligatoria para mecánicos
    if data.rol == UserRole.mechanic:
        if not data.especialidad or not data.especialidad.strip():
            raise ValueError("La especialidad es obligatoria para registrar un mecánico")

    existing_user = get_user_by_unique_fields(
        db, data.correo, data.telefono, getattr(data, "cedula", None)
    )

    if existing_user:
        if existing_user.correo == data.correo:
            raise UserAlreadyExistsError("El correo ya está registrado")
        if existing_user.telefono == data.telefono:
            raise UserAlreadyExistsError("El teléfono ya está registrado")
        if (
            getattr(existing_user, "cedula", None) == getattr(data, "cedula", None)
            and getattr(data, "cedula", None) is not None
        ):
            raise UserAlreadyExistsError("La cédula ya está registrada")

    user = User(
        nombre=data.nombre,
        apellido=data.apellido,
        telefono=data.telefono,
        correo=data.correo,
        cedula=data.cedula,
        password_hash=hash_password(data.password),
        rol=data.rol,  # Usar el rol enviado en vez de hardcodear mechanic
        especialidad=data.especialidad if data.rol == UserRole.mechanic else None,
    )

    return create_user(db, user)
