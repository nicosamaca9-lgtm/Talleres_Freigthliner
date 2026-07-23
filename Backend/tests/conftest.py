import os

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_chat.db")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret")
os.environ.setdefault("JWT_ALGORITHM", "HS256")
os.environ.setdefault("DATA_CLEANUP_JOBS_ENABLED", "false")

import pytest
from fastapi.testclient import TestClient

from app.api.v1.deps import get_current_user
from app.core.security import create_access_token
from app.db.base import Base
from app.db.session import SessionLocal, engine, get_db
from app.main import app
from app.models import Message, User


@pytest.fixture(autouse=True)
def reset_database():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides.pop(get_current_user, None)
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def auth_header(user: User) -> dict[str, str]:
    token = create_access_token(
        subject=user.id_usuario,
        extra_data={"role": user.rol.value},
    )
    return {"Authorization": f"Bearer {token}"}


def create_user(db, user_id: int, role, email_prefix: str) -> User:
    user = User(
        id_usuario=user_id,
        nombre=email_prefix.title(),
        apellido="User",
        telefono=f"30000000{user_id:02d}",
        cedula=f"100000{user_id}",
        correo=f"{email_prefix}@example.com",
        password_hash="hash",
        rol=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def create_message(db, sender: User, receiver: User, content: str = "Hola") -> Message:
    message = Message(
        sender_id=sender.id_usuario,
        receiver_id=receiver.id_usuario,
        content=content,
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message
