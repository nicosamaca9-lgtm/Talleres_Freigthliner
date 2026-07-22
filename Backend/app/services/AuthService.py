import uuid
from sqlalchemy.orm import Session
from sqlalchemy import or_

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

    # Verificar cuenta activa solo para clientes
    if user.rol == UserRole.client and not user.is_active:
        raise InvalidCredentialsError(
            "Cuenta no activa. Revisa tu correo electrónico y haz clic en el enlace de activación que te enviamos."
        )

    access_token = create_access_token(
        subject=user.id_usuario,
        extra_data={
            "role": user.rol.value,
            "name": user.nombre,
            "last_name": user.apellido,
            "correo": user.correo,
            "telefono": user.telefono,
            "cedula": user.cedula,
        },
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }


def register_client(db: Session, data: ClientRegister):
    """Registra un nuevo cliente como inactivo y envia correo de verificacion.
    Si encuentra cuentas inactivas con los mismos datos, las elimina para permitir el registro."""
    
    # Buscar todos los usuarios que choquen con correo, telefono o cedula
    existing_users = db.query(User).filter(
        or_(
            User.correo == data.correo,
            User.telefono == data.telefono,
            User.cedula == data.cedula
        )
    ).all()

    for u in existing_users:
        if u.is_active:
            # Si el usuario activo choca, rechazamos el registro
            if u.correo == data.correo:
                raise UserAlreadyExistsError("El correo ya está registrado y activo")
            if u.telefono == data.telefono:
                raise UserAlreadyExistsError("El teléfono ya está registrado y activo")
            if u.cedula == data.cedula:
                raise UserAlreadyExistsError("La cédula ya está registrada y activa")
        else:
            # Si el usuario está inactivo, es 'basura' no confirmada. La borramos para dejar libre el dato.
            db.delete(u)
            
    # Hacemos commit de las eliminaciones para liberar las restricciones de unicidad
    if existing_users:
        db.commit()

    token = str(uuid.uuid4())

    user = User(
        nombre=data.nombre,
        apellido=data.apellido,
        telefono=data.telefono,
        cedula=data.cedula,
        correo=data.correo,
        password_hash=hash_password(data.password),
        rol=UserRole.client,
        is_active=False,
        verification_token=token,
    )

    created = create_user(db, user)

    # Enviar correo de verificacion (no bloqueante si falla)
    try:
        from app.services.EmailService import send_verification_email
        send_verification_email(data.correo, data.nombre, token)
    except Exception as e:
        print(f"[AuthService] No se pudo enviar el correo de verificacion: {e}")

    return created

def change_password(db: Session, user: User, old_password: str, new_password: str):
    if not verify_password(old_password, user.password_hash):
        raise InvalidCredentialsError("Contraseña actual incorrecta")
    user.password_hash = hash_password(new_password)
    db.commit()
    return {"message": "Contraseña actualizada exitosamente"}

from app.schemas.AuthSchema import UpdateProfileRequest

def update_profile(db: Session, user: User, data: UpdateProfileRequest):
    """Actualiza la informacion del usuario y retorna un nuevo token."""
    # Revisar que el nuevo telefono o cedula no existan en OTRO usuario
    if data.telefono and data.telefono != user.telefono:
        if db.query(User).filter(User.telefono == data.telefono, User.id_usuario != user.id_usuario).first():
            raise UserAlreadyExistsError("El teléfono ya está registrado por otro usuario")
            
    if data.cedula and data.cedula != user.cedula:
        if db.query(User).filter(User.cedula == data.cedula, User.id_usuario != user.id_usuario).first():
            raise UserAlreadyExistsError("La cédula ya está registrada por otro usuario")

    user.nombre = data.nombre
    user.apellido = data.apellido
    user.telefono = data.telefono
    user.cedula = data.cedula

    db.commit()
    db.refresh(user)

    # Crear nuevo token con datos actualizados
    access_token = create_access_token(
        subject=user.id_usuario,
        extra_data={
            "role": user.rol.value,
            "name": user.nombre,
            "last_name": user.apellido,
            "correo": user.correo,
            "telefono": user.telefono,
            "cedula": user.cedula,
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }