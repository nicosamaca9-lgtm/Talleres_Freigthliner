# app/Api/v1/endpoints/AuthEndpoint.py

from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.AuthSchema import ClientRegister, LoginRequest, TokenResponse
from app.schemas.UserSchema import UserResponse
from app.services.AuthService import register_client, login_user


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
