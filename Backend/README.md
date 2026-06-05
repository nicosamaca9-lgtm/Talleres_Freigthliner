# Backend - API Taller Automotriz

API REST construida con **FastAPI** para la gestión de un taller automotriz Freightliner.  
Maneja clientes, mecánicos, órdenes de servicio, citas y reportes.

---

## Tecnologías

| Tecnología | Uso |
|---|---|
| **FastAPI** | Framework web (async, auto-documentación con Swagger) |
| **SQLAlchemy** | ORM para interactuar con la base de datos |
| **Alembic** | Migraciones de base de datos (versionado de esquema) |
| **Pydantic** | Validación de datos y serialización |
| **PostgreSQL** | Base de datos relacional |
| **python-jose** | Manejo de tokens JWT para autenticación |
| **Passlib + bcrypt** | Hashing seguro de contraseñas |

---

## Estructura del proyecto

```
Backend/
├── alembic/                  # Migraciones de base de datos
│   ├── versions/             # Archivos de migración generados
│   └── env.py                # Configuración de Alembic (lee del .env)
├── alembic.ini               # Configuración general de Alembic
├── app/
│   ├── api/                  # Capa de presentación (endpoints HTTP)
│   │   ├── deps.py           # Dependencias compartidas (get_current_user, etc.)
│   │   └── v1/
│   │       ├── router.py     # Router principal que agrupa todos los endpoints
│   │       └── endpoints/    # Controladores por recurso
│   │           └── auth.py
│   ├── core/                 # Configuración central de la aplicación
│   │   ├── config.py         # Settings (lee variables del .env)
│   │   └── security.py       # Utilidades JWT y hashing de contraseñas
│   ├── db/                   # Capa de base de datos
│   │   ├── base.py           # Base declarativa de SQLAlchemy
│   │   └── session.py        # Engine y SessionLocal (fábrica de conexiones)
│   ├── models/               # Modelos ORM (tablas de la BD)
│   ├── schemas/              # Esquemas Pydantic (contratos de datos)
│   ├── repositories/         # Acceso a datos (queries a la BD)
│   ├── services/             # Lógica de negocio
│   └── integrations/         # Integraciones con servicios externos
├── .env                      # Variables de entorno (NO se sube a Git)
├── .env.example              # Plantilla de variables de entorno
└── requirements.txt          # Dependencias de Python
```

---

## Capas de la arquitectura

El proyecto sigue una arquitectura en capas. Cada capa tiene una responsabilidad
clara y solo se comunica con la capa inmediatamente inferior:

```
Request HTTP
    │
    ▼
┌──────────────┐
│   API        │  Endpoints (controllers) — reciben el request, validan con schemas,
│   endpoints/ │  llaman al service y devuelven la respuesta.
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Services   │  Lógica de negocio — reglas, cálculos, validaciones complejas.
│   services/  │  No sabe nada de HTTP ni de SQL.
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Repositories │  Acceso a datos — las queries SQL van aquí.
│ repositories/│  Usa los modelos ORM para leer/escribir en la BD.
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Models     │  Modelos ORM — representan las tablas de PostgreSQL.
│   models/    │  Definen columnas, tipos, relaciones y constraints.
└──────────────┘
```

---

## Detalle de cada carpeta

### `models/` — Modelos ORM (las tablas)

Representan las tablas de la base de datos. Cada clase es una tabla.
Alembic lee estos modelos para generar migraciones automáticamente.

```python
# app/models/usuario.py
from sqlalchemy import Column, Integer, String
from app.db.base import Base

class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
```

---

### `schemas/` — Esquemas Pydantic (los contratos)

Son como las **interfaces/DTOs**. Definen la forma de los datos que
entran y salen de la API. Validan automáticamente los tipos.

```python
# app/schemas/usuario.py
from pydantic import BaseModel, EmailStr

# Lo que el cliente envía para crear un usuario
class UsuarioCreate(BaseModel):
    nombre: str
    email: EmailStr
    password: str

# Lo que la API devuelve (sin la contraseña)
class UsuarioResponse(BaseModel):
    id: int
    nombre: str
    email: EmailStr

    class Config:
        from_attributes = True  # Permite convertir desde el modelo ORM
```

---

### `repositories/` — Repositorios (acceso a datos)

Encapsulan las **queries a la base de datos**. Son la única capa que
interactúa directamente con SQLAlchemy. Si mañana cambias de PostgreSQL
a MySQL, solo modificas esta capa.

```python
# app/repositories/usuario_repository.py
from sqlalchemy.orm import Session
from app.models.usuario import Usuario

def get_by_email(db: Session, email: str) -> Usuario | None:
    return db.query(Usuario).filter(Usuario.email == email).first()

def create(db: Session, usuario: Usuario) -> Usuario:
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    return usuario
```

---

### `services/` — Servicios (lógica de negocio)

Contienen las **reglas de negocio**. Orquestan llamadas a uno o más
repositorios, aplican validaciones y transformaciones de datos.
No conocen HTTP ni SQL directamente.

```python
# app/services/usuario_service.py
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.usuario import Usuario
from app.repositories import usuario_repository
from app.schemas.usuario import UsuarioCreate
from app.core.security import hash_password

def registrar_usuario(db: Session, data: UsuarioCreate) -> Usuario:
    # Regla de negocio: no permitir emails duplicados
    existente = usuario_repository.get_by_email(db, data.email)
    if existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El email ya está registrado"
        )

    nuevo = Usuario(
        nombre=data.nombre,
        email=data.email,
        password_hash=hash_password(data.password),
    )
    return usuario_repository.create(db, nuevo)
```

---

### `api/v1/endpoints/` — Endpoints (controladores)

Son los **controladores HTTP**. Reciben el request, lo validan
con un schema, llaman al service correspondiente y devuelven la respuesta.
Deben ser lo más delgados posible.

```python
# app/api/v1/endpoints/usuarios.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.usuario import UsuarioCreate, UsuarioResponse
from app.services import usuario_service

router = APIRouter()

@router.post("/", response_model=UsuarioResponse, status_code=201)
def crear_usuario(data: UsuarioCreate, db: Session = Depends(get_db)):
    return usuario_service.registrar_usuario(db, data)
```

---

### `api/deps.py` — Dependencias compartidas

Funciones reutilizables que se inyectan en los endpoints con `Depends()`.
Ejemplos comunes: obtener el usuario autenticado, verificar permisos, etc.

```python
# app/api/deps.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.security import decode_access_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
        )
    # buscar usuario en BD y retornarlo...
```

---

### `core/` — Configuración central

| Archivo | Descripción |
|---|---|
| `config.py` | Carga las variables de entorno del `.env` usando Pydantic Settings |
| `security.py` | Funciones para hashear contraseñas y crear/verificar tokens JWT |

---

### `db/` — Base de datos

| Archivo | Descripción |
|---|---|
| `base.py` | `Base` declarativa de SQLAlchemy. Todos los modelos heredan de ella |
| `session.py` | Crea el `engine` (conexión) y `SessionLocal` (fábrica de sesiones) |

---

### `integrations/` — Integraciones externas

Para conectar con servicios de terceros: pasarelas de pago,
APIs de notificaciones (email/SMS), servicios de archivos, etc.

---

### `alembic/` — Migraciones

Versionado del esquema de la base de datos. Comandos principales:

```bash
# Generar migración al agregar/modificar un modelo
alembic revision --autogenerate -m "descripcion del cambio"

# Aplicar todas las migraciones pendientes
alembic upgrade head

# Revertir la última migración
alembic downgrade -1

# Ver estado actual
alembic current
```

---

## Configuración inicial

```bash
# 1. Crear y activar el entorno virtual
python -m venv venv
venv\Scripts\activate        # Windows
source venv/bin/activate     # Linux/Mac

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# 4. Aplicar migraciones
alembic upgrade head

# 5. Iniciar el servidor de desarrollo
uvicorn app.main:app --reload
```

La documentación interactiva estará disponible en:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## Flujo de un request (ejemplo)

```
POST /api/v1/usuarios/
Body: { "nombre": "Juan", "email": "juan@mail.com", "password": "1234" }

1. FastAPI recibe el request en endpoints/usuarios.py
2. Pydantic valida el body con UsuarioCreate (schema)
3. El endpoint llama a usuario_service.registrar_usuario()
4. El service verifica que el email no exista (regla de negocio)
5. El service hashea la contraseña con security.hash_password()
6. El service llama a usuario_repository.create() para guardar en la BD
7. El repository ejecuta el INSERT con SQLAlchemy
8. FastAPI serializa la respuesta con UsuarioResponse (sin contraseña)

Response: { "id": 1, "nombre": "Juan", "email": "juan@mail.com" }
```
