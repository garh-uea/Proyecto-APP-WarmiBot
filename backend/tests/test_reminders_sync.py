from __future__ import annotations

from datetime import datetime, timezone

from starlette.testclient import TestClient


def _user_headers(client: TestClient) -> dict[str, str]:
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "offline@example.com",
            "display_name": "Modo sin conexión",
            "password": "ClaveSegura123!",
        },
    )
    login = client.post(
        "/api/v1/auth/login",
        data={"username": "offline@example.com", "password": "ClaveSegura123!"},
    ).json()
    return {"Authorization": f"Bearer {login['access_token']}"}


def _payload(**overrides):
    payload = {
        "client_id": "client-test-reminder-001",
        "operation": "upsert",
        "text": "Presentar el proyecto",
        "scheduled_at": "2026-09-06T15:00:00Z",
        "reminder_type": "reminder",
        "is_completed": False,
        "base_version": 0,
        "client_updated_at": datetime.now(timezone.utc).isoformat(),
    }
    payload.update(overrides)
    return payload


def test_sync_is_idempotent_and_detects_version_conflict(client: TestClient) -> None:
    headers = _user_headers(client)

    created = client.post("/api/v1/reminders/sync", headers=headers, json=_payload())
    assert created.status_code == 200
    assert created.json()["version"] == 1

    updated = client.post(
        "/api/v1/reminders/sync",
        headers=headers,
        json=_payload(base_version=1, text="Presentar WarmiBot"),
    )
    assert updated.status_code == 200
    assert updated.json()["version"] == 2

    conflict = client.post(
        "/api/v1/reminders/sync",
        headers=headers,
        json=_payload(base_version=1, text="Cambio sin conexión"),
    )
    assert conflict.status_code == 409
    assert conflict.json()["detail"]["server"]["text"] == "Presentar WarmiBot"

    listed = client.get("/api/v1/reminders", headers=headers)
    assert listed.status_code == 200
    assert [item["text"] for item in listed.json()] == ["Presentar WarmiBot"]
