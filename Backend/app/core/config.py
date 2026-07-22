from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "API Taller Automotriz"
    BACKEND_CORS_ORIGINS: list[str] = ["*"]

    # Base de datos
    DATABASE_URL: str

    # JWT
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Firebase
    FIREBASE_CREDENTIALS_JSON: str | None = None

    # Cloudinary
    CLOUDINARY_CLOUD_NAME: str | None = None
    CLOUDINARY_API_KEY: str | None = None
    CLOUDINARY_API_SECRET: str | None = None

    # SMTP (correos)
    SMTP_USER: str | None = None
    SMTP_PASSWORD: str | None = None
    BASE_URL: str = "http://localhost:8000"

    class Config:
        env_file = ".env"


settings = Settings()