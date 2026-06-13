# app/Api/v1/endpoints/AdminEndpoint.py

from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.UserSchema import MechanicRegister
from app.schemas.UserSchema import UserResponse
from app.services.UserService import register_mechanic as register_mechanic_service
from app.core.Enum import UserRole
from app.api.deps import require_roles


from app.core.Exceptions import UserAlreadyExistsError, InvalidCredentialsError


router = APIRouter()


@router.post(
    "/mechanic/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_mechanic(
    data: MechanicRegister, 
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    try:
        return register_mechanic_service(db, data)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except UserAlreadyExistsError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
