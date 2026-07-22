from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from pydantic import BaseModel

from app.api.deps import get_current_user
from app.models.UserEntity import User
from app.services.CloudinaryService import CloudinaryService

router = APIRouter()

class UploadResponse(BaseModel):
    url: str

@router.post("/", response_model=UploadResponse, status_code=status.HTTP_201_CREATED)
def upload_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Sube una imagen a Cloudinary y devuelve la URL segura para accederla.
    """
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El archivo debe ser una imagen válida."
        )

    # Subir imagen a Cloudinary usando el servicio
    url = CloudinaryService.upload_image(file.file)

    return UploadResponse(url=url)
