from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
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


@app.get("/privacy", response_class=HTMLResponse, tags=["Public"])
def privacy_policy():
    return """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Política de Privacidad - TF Centro Automotriz</title>
<style>
body{font-family:Arial,sans-serif;max-width:800px;margin:0 auto;padding:20px;line-height:1.6;color:#333}
h1{color:#1a237e;border-bottom:2px solid #1a237e;padding-bottom:10px}
h2{color:#283593;margin-top:30px}
</style>
</head>
<body>
<h1>Política de Privacidad</h1>
<p><strong>TF Centro Automotriz</strong><br>Última actualización: septiembre 2026</p>

<h2>1. Información que recopilamos</h2>
<p>Recopilamos la siguiente información personal cuando usted utiliza nuestra aplicación:</p>
<ul>
<li>Nombre completo y datos de contacto (correo electrónico, teléfono)</li>
<li>Información de sus vehículos (placa, marca, modelo, kilometraje)</li>
<li>Historial de órdenes de servicio y citas agendadas</li>
<li>Fotografías relacionadas con los servicios realizados a su vehículo</li>
</ul>

<h2>2. Uso de la información</h2>
<p>Utilizamos su información para:</p>
<ul>
<li>Gestionar citas y órdenes de servicio de su vehículo</li>
<li>Enviar notificaciones sobre el estado de sus servicios</li>
<li>Generar reportes e historial de mantenimiento</li>
<li>Mejorar nuestros servicios y comunicarnos con usted</li>
</ul>

<h2>3. Protección de datos</h2>
<p>Sus datos están protegidos mediante cifrado y almacenados en servidores seguros. Solo el personal autorizado del taller tiene acceso a su información.</p>

<h2>4. Compartir información</h2>
<p>No vendemos, intercambiamos ni transferimos su información personal a terceros. Su información solo es accesible por el personal de TF Centro Automotriz necesario para prestar el servicio.</p>

<h2>5. Derechos del usuario</h2>
<p>Usted tiene derecho a:</p>
<ul>
<li>Acceder a sus datos personales</li>
<li>Solicitar la corrección de datos inexactos</li>
<li>Solicitar la eliminación de su cuenta y datos asociados</li>
</ul>

<h2>6. Contacto</h2>
<p>Si tiene preguntas sobre esta política de privacidad, contáctenos:</p>
<ul>
<li>Correo: serviciostf123@gmail.com</li>
<li>Dirección: Tunja, Boyacá, Colombia</li>
</ul>

<h2>7. Cambios en la política</h2>
<p>Nos reservamos el derecho de actualizar esta política. Los cambios serán notificados a través de la aplicación.</p>
</body>
</html>"""

