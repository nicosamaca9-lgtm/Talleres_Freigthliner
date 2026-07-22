import cloudinary
import cloudinary.uploader
from fastapi import HTTPException, status
from app.core.config import settings

# Configurar Cloudinary usando las variables de entorno
if settings.CLOUDINARY_CLOUD_NAME and settings.CLOUDINARY_API_KEY and settings.CLOUDINARY_API_SECRET:
    cloudinary.config(
        cloud_name=settings.CLOUDINARY_CLOUD_NAME,
        api_key=settings.CLOUDINARY_API_KEY,
        api_secret=settings.CLOUDINARY_API_SECRET,
        secure=True
    )

class CloudinaryService:
    @staticmethod
    def upload_image(file_stream, folder: str = "talleres_freigthliner") -> str:
        """
        Sube una imagen a Cloudinary y devuelve su URL segura.
        
        :param file_stream: Objeto archivo tipo file-like (ej. file.file de FastAPI UploadFile)
        :param folder: Carpeta en Cloudinary donde se alojará la imagen
        :return: URL segura de la imagen
        """
        if not settings.CLOUDINARY_CLOUD_NAME:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Cloudinary no está configurado en el servidor."
            )

        try:
            # Subir archivo
            response = cloudinary.uploader.upload(
                file_stream,
                folder=folder
            )
            return response.get("secure_url")
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al subir imagen a Cloudinary: {str(e)}"
            )
