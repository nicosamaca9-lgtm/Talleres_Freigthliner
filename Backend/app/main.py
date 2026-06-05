from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.v1.router import api_router
from app.core.config import settings
from app.db.session import engine


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: verificar conexión a la base de datos
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        print("[OK] Conexion con PostgreSQL exitosa")
    except Exception as error:
        print(f"[ERROR] Error al conectar con PostgreSQL: {error}")
        raise
    yield
    # Shutdown
    engine.dispose()


app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Sistema de gestión para clientes, mecánicos, órdenes de servicio, citas y reportes.",
    version="1.0.0",
    docs_url="/docs",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")


@app.get("/", tags=["Health"])
def root():
    return {
        "status": "online",
        "message": "API Taller Automotriz funcionando correctamente. Visita /docs para la documentación.",
    }
