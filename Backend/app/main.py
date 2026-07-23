from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
import os

from app.api.v1.router import api_router
from app.core.config import settings
from app.db.session import engine
from app.services.CleanupScheduler import start_cleanup_scheduler, stop_cleanup_scheduler

import codecs
# Fuerza a que los errores de decodificación reemplacen el caracter en vez de romper la app
codecs.register_error("strict", codecs.ignore_errors)

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
    start_cleanup_scheduler()
    yield
    # Shutdown
    stop_cleanup_scheduler()
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

# Asegurar que el directorio uploads existe antes de montarlo
os.makedirs("uploads", exist_ok=True)
app.mount("/static/uploads", StaticFiles(directory="uploads"), name="uploads")


@app.get("/", tags=["Health"])
def root():
    return {
        "status": "online",
        "message": "API Taller Automotriz funcionando correctamente. Visita /docs para la documentación.",
    }
