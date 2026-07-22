# app/Api/v1/endpoints/AuthEndpoint.py

from fastapi import APIRouter, Depends, status, HTTPException, Request, BackgroundTasks
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.AuthSchema import ClientRegister, LoginRequest, TokenResponse, ChangePasswordRequest, UpdateProfileRequest
from app.schemas.UserSchema import UserResponse
from app.services.AuthService import register_client, login_user, change_password, update_profile
from app.api.deps import get_current_user
from app.services.EmailService import send_password_recovery_email
from pydantic import BaseModel
import random
import string
from app.models.UserEntity import User


from app.core.Exceptions import UserAlreadyExistsError, InvalidCredentialsError
from sqlalchemy.exc import IntegrityError


router = APIRouter()


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def register(data: ClientRegister, db: Session = Depends(get_db)):
    try:
        return register_client(db, data)
    except UserAlreadyExistsError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El correo, teléfono o cédula ya están registrados",
        )


@router.post(
    "/login",
    response_model=TokenResponse,
)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    try:
        return login_user(db, data)
    except InvalidCredentialsError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )


class ForgotPasswordRequest(BaseModel):
    correo: str

class ResetPasswordRequest(BaseModel):
    correo: str
    codigo: str
    nueva_password: str

@router.post("/forgot-password")
def forgot_password(data: ForgotPasswordRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.correo == data.correo).first()
    if not user:
        # Prevent email enumeration by returning a generic success message
        return {"message": "Si el correo está registrado, se ha enviado un código de recuperación."}
    
    # Generate 6-digit PIN
    pin = ''.join(random.choices(string.digits, k=6))
    user.verification_token = pin
    db.commit()

    # Send email
    background_tasks.add_task(send_password_recovery_email, user.correo, pin)
    return {"message": "Si el correo está registrado, se ha enviado un código de recuperación."}


@router.post("/reset-password")
def reset_password(data: ResetPasswordRequest, db: Session = Depends(get_db)):
    from app.core.security import hash_password
    user = db.query(User).filter(User.correo == data.correo).first()
    if not user or user.verification_token != data.codigo:
        raise HTTPException(status_code=400, detail="Código inválido o expirado.")
    
    # Reset password
    user.password_hash = hash_password(data.nueva_password)
    user.verification_token = None  # Clear PIN
    db.commit()
    return {"message": "Contraseña actualizada exitosamente."}

@router.post("/change-password")
def change_password_endpoint(
    data: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        return change_password(db, current_user, data.old_password, data.new_password)
    except InvalidCredentialsError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.put("/profile", response_model=TokenResponse)
def update_profile_endpoint(
    data: UpdateProfileRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        return update_profile(db, current_user, data)
    except UserAlreadyExistsError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get("/verify-email", response_class=HTMLResponse)
def verify_email(token: str, db: Session = Depends(get_db)):
    """Activa la cuenta del cliente al hacer clic en el enlace del correo."""
    user = db.query(User).filter(User.verification_token == token).first()

    if not user:
        return HTMLResponse(
            content="""
            <html><head><meta charset='UTF-8'><title>Enlace Inválido</title></head>
            <body style='font-family:Arial,sans-serif;text-align:center;padding:60px;background:#f4f4f4;'>
              <div style='max-width:480px;margin:0 auto;background:#fff;border-radius:10px;padding:40px;box-shadow:0 2px 12px rgba(0,0,0,.1);'>
                <h1 style='color:#e74c3c;'>Enlace Inválido</h1>
                <p style='color:#555;'>Este enlace de verificación no es válido o ya fue utilizado.</p>
                <p style='color:#888;font-size:13px;'>Si ya activaste tu cuenta, puedes cerrar esta ventana.</p>
              </div>
            </body></html>""",
            status_code=400
        )

    if user.is_active:
        return HTMLResponse(
            content="""
            <html><head><meta charset='UTF-8'><title>Ya Activada</title></head>
            <body style='font-family:Arial,sans-serif;text-align:center;padding:60px;background:#f4f4f4;'>
              <div style='max-width:480px;margin:0 auto;background:#fff;border-radius:10px;padding:40px;box-shadow:0 2px 12px rgba(0,0,0,.1);'>
                <h1 style='color:#F6C90E;'>Cuenta Ya Activada</h1>
                <p style='color:#555;'>Tu cuenta ya estaba activa. Puedes iniciar sesión en la app.</p>
              </div>
            </body></html>"""
        )

    user.is_active = True
    user.verification_token = None
    db.commit()

    return HTMLResponse(
        content="""
        <html><head><meta charset='UTF-8'><title>Cuenta Activada</title></head>
        <body style='font-family:Arial,sans-serif;text-align:center;padding:60px;background:#f4f4f4;'>
          <div style='max-width:480px;margin:0 auto;background:#fff;border-radius:10px;padding:40px;box-shadow:0 2px 12px rgba(0,0,0,.1);'>
            <div style='font-size:60px;'>&#x2705;</div>
            <h1 style='color:#27ae60;margin-top:16px;'>&#x00a1;Cuenta Activada!</h1>
            <p style='color:#555;font-size:15px;line-height:1.6;'>
              Tu cuenta en <strong>TF Centro Automotriz</strong> ha sido activada exitosamente.
              Ya puedes iniciar sesión en la aplicación.
            </p>
            <p style='color:#888;font-size:13px;margin-top:24px;'>Puedes cerrar esta ventana.</p>
          </div>
        </body></html>"""
    )
