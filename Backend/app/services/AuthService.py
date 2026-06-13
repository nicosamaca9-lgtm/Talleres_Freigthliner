# app/Services/AuthService.py

from sqlalchemy.orm import Session

from app.core.security import verify_password, create_access_token, hash_password
from app.repositories.UserRepository import (
    get_user_by_email,
    create_user,
    get_user_by_unique_fields,
)
from app.models.UserEntity import User
from app.core.Enum import UserRole
from app.core.Exceptions import UserAlreadyExistsError, InvalidCredentialsError
from app.schemas.AuthSchema import LoginRequest, ClientRegister


def authenticate_user(db: Session, correo: str, password: str) -> User | None:
    """Verifica las credenciales del usuario y retorna el usuario si son correctas."""
    user = get_user_by_email(db, correo)

    if not user:
        return None

    if not verify_password(password, user.password_hash):
        return None

    return user


def login_user(db: Session, data: LoginRequest):
    """Autentica al usuario y retorna el token de acceso."""
    user = authenticate_user(db, data.correo, data.password)

    if not user:
        raise InvalidCredentialsError("Correo o contraseña incorrectos")

    access_token = create_access_token(
        subject=user.id_usuario,
        extra_data={"role": user.rol.value},
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }


def register_client(db: Session, data: ClientRegister):
    """Registra un nuevo usuario con rol cliente."""
    existing_user = get_user_by_unique_fields(db, data.correo, data.telefono, data.cedula)

    if existing_user:
        if existing_user.correo == data.correo:
            raise UserAlreadyExistsError("El correo ya está registrado")
        if existing_user.telefono == data.telefono:
            raise UserAlreadyExistsError("El teléfono ya está registrado")
        if getattr(existing_user, "cedula", None) == data.cedula:
            raise UserAlreadyExistsError("La cédula ya está registrada")

    user = User(
        nombre=data.nombre,
        apellido=data.apellido,
        telefono=data.telefono,
        cedula=data.cedula,
        correo=data.correo,
        password_hash=hash_password(data.password),
        rol=UserRole.client,
    )

    return create_user(db, user)