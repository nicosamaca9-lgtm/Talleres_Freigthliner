from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "API Taller Automotriz"
    BACKEND_CORS_ORIGINS: list[str] = ["*"]

    # Base de datos
    DATABASE_URL: str

    # JWT
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 5256000 # 10 años para que nunca se cierre sola

    # Firebase
    FIREBASE_CREDENTIALS_JSON: str | None = None

    # Limpieza automatica de datos
    DATA_CLEANUP_JOBS_ENABLED: bool = True
    DATA_CLEANUP_RETENTION_DAYS: int = 30
    DATA_CLEANUP_BATCH_SIZE: int = 500
    DATA_CLEANUP_SCHEDULER_TIMEZONE: str = "America/Bogota"
    DATA_CLEANUP_MESSAGES_CRON_HOUR: int = 3
    DATA_CLEANUP_MESSAGES_CRON_MINUTE: int = 0

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
