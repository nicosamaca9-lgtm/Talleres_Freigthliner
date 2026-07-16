# app/core/enum.py

from enum import Enum


class UserRole(str, Enum):
    admin = "Administrador"
    mechanic = "Tecnico"
    secretary = "Secretario"
    client = "Cliente"
