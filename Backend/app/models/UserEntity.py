# app/Models/UserEntity.py

from sqlalchemy import Column, Integer, BigInteger, String, DateTime, Enum, Boolean
from sqlalchemy.sql import func

from app.db.base import Base
from app.core.Enum import UserRole


class User(Base):
    __tablename__ = "usuarios"

    id_usuario = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    apellido = Column(String(100), nullable=False)
    telefono = Column(String(20), nullable=False)
    cedula = Column(String(20), unique=True, index=True, nullable=False)
    correo = Column(String(150), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    fecha_registro = Column(DateTime(timezone=True), server_default=func.now())
    rol = Column(
        Enum(UserRole, native_enum=False), nullable=False, default=UserRole.client
    )
    especialidad = Column(String(100), nullable=True)