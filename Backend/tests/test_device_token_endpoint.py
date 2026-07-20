from app.core.Enum import UserRole
from app.models.DeviceTokenEntity import DeviceToken
from tests.conftest import auth_header, create_user


def token_payload(
    *,
    token: str = "fcm-token-123",
    device_id: str = "device-123",
) -> dict:
    return {
        "device_id": device_id,
        "fcm_token": token,
        "platform": "android",
        "app_version": "1.0.0+1",
    }


def test_register_device_token_requires_authentication(client):
    response = client.post(
        "/api/v1/device-tokens/register",
        json=token_payload(),
    )

    assert response.status_code == 401


def test_register_device_token_upserts_for_authenticated_user(client, db):
    user = create_user(db, 1, UserRole.client, "client")

    first_response = client.post(
        "/api/v1/device-tokens/register",
        json=token_payload(token="fcm-token-a"),
        headers=auth_header(user),
    )
    second_response = client.post(
        "/api/v1/device-tokens/register",
        json=token_payload(token="fcm-token-b"),
        headers=auth_header(user),
    )

    rows = db.query(DeviceToken).all()
    assert first_response.status_code == 200
    assert second_response.status_code == 200
    assert len(rows) == 1
    assert rows[0].user_id == user.id_usuario
    assert rows[0].device_id == "device-123"
    assert rows[0].fcm_token == "fcm-token-b"
    assert rows[0].app_version == "1.0.0+1"
    assert rows[0].is_active is True


def test_register_device_token_moves_token_to_current_user(client, db):
    old_user = create_user(db, 1, UserRole.client, "old-client")
    new_user = create_user(db, 2, UserRole.client, "new-client")
    client.post(
        "/api/v1/device-tokens/register",
        json=token_payload(token="shared-token", device_id="old-device"),
        headers=auth_header(old_user),
    )

    response = client.post(
        "/api/v1/device-tokens/register",
        json=token_payload(token="shared-token", device_id="new-device"),
        headers=auth_header(new_user),
    )

    rows = db.query(DeviceToken).all()
    assert response.status_code == 200
    assert len(rows) == 1
    assert rows[0].user_id == new_user.id_usuario
    assert rows[0].device_id == "new-device"


def test_remove_device_token_deactivates_only_current_user_device(client, db):
    user = create_user(db, 1, UserRole.client, "client")
    other_user = create_user(db, 2, UserRole.client, "other-client")
    client.post(
        "/api/v1/device-tokens/register",
        json=token_payload(token="fcm-token-a", device_id="device-a"),
        headers=auth_header(user),
    )
    client.post(
        "/api/v1/device-tokens/register",
        json=token_payload(token="fcm-token-b", device_id="device-a"),
        headers=auth_header(other_user),
    )

    response = client.delete(
        "/api/v1/device-tokens/device-a",
        headers=auth_header(user),
    )

    current_user_token = (
        db.query(DeviceToken)
        .filter(DeviceToken.user_id == user.id_usuario)
        .one()
    )
    other_user_token = (
        db.query(DeviceToken)
        .filter(DeviceToken.user_id == other_user.id_usuario)
        .one()
    )
    assert response.status_code == 204
    assert current_user_token.is_active is False
    assert other_user_token.is_active is True
