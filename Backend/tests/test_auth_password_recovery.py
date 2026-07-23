from app.core.Enum import UserRole
from app.models.UserEntity import User
from app.services import AuthService
from tests.conftest import create_user


GENERIC_MESSAGE = {
    "message": "Si el correo está registrado, se ha enviado un código de recuperación."
}


def test_forgot_password_sends_recovery_code_for_existing_email(
    client,
    db,
    monkeypatch,
):
    user = create_user(db, 1, UserRole.client, "client")
    email_calls = []

    monkeypatch.setattr(
        AuthService,
        "send_password_recovery_email",
        lambda to_email, pin: email_calls.append((to_email, pin)),
    )

    existing_response = client.post(
        "/api/v1/auth/forgot-password",
        json={"correo": user.correo},
    )

    db.refresh(user)
    assert existing_response.status_code == 200
    assert existing_response.json() == GENERIC_MESSAGE
    assert len(email_calls) == 1
    assert email_calls[0][0] == user.correo
    assert email_calls[0][1].isdigit()
    assert len(email_calls[0][1]) == 6
    assert user.verification_token == email_calls[0][1]


def test_forgot_password_unknown_email_does_not_create_token_or_send_email(
    client,
    db,
    monkeypatch,
):
    existing_user = create_user(db, 1, UserRole.client, "client")
    email_calls = []

    monkeypatch.setattr(
        AuthService,
        "send_password_recovery_email",
        lambda to_email, pin: email_calls.append((to_email, pin)),
    )

    response = client.post(
        "/api/v1/auth/forgot-password",
        json={"correo": "nadie@example.com"},
    )

    db.refresh(existing_user)
    assert response.status_code == 404
    assert response.json() == {"detail": "El correo no existe"}
    assert email_calls == []
    assert existing_user.verification_token is None
    assert db.query(User).filter(User.correo == "nadie@example.com").first() is None
