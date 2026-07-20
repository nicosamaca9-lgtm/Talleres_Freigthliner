from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.UserEntity import User
from app.schemas.DeviceTokenSchema import (
    DeviceTokenRegisterRequest,
    DeviceTokenResponse,
)
from app.services.DeviceTokenService import DeviceTokenService

router = APIRouter()


@router.post(
    "/register",
    response_model=DeviceTokenResponse,
    status_code=status.HTTP_200_OK,
)
def register_device_token(
    data: DeviceTokenRegisterRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return DeviceTokenService.register_token(
        db,
        user_id=current_user.id_usuario,
        data=data,
    )


@router.delete("/{device_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_device_token(
    device_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    DeviceTokenService.deactivate_token(
        db,
        user_id=current_user.id_usuario,
        device_id=device_id,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
