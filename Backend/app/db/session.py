from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

engine = create_engine(settings.DATABASE_URL)

# SessionLocal es la "fábrica" que nos dará conexiones a la base de datos
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


# Dependencia para inyectar la base de datos en las rutas (FastAPI)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
