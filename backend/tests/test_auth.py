from __future__ import annotations

from contextlib import contextmanager

from starlette.testclient import TestClient
from sqlalchemy import event

from app.database import engine


def test_register_login_refresh_rotation_and_protected_route(
    client: TestClient,
) -> None:
    register = client.post(
        "/api/v1/auth/register",
        json={
            "email": "ana@example.com",
            "display_name": "Ana",
            "password": "ClaveSegura123!",
        },
    )
    assert register.status_code == 201

    login = client.post(
        "/api/v1/auth/login",
        data={"username": "ana@example.com", "password": "ClaveSegura123!"},
    )
    assert login.status_code == 200
    tokens = login.json()

    me = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert me.status_code == 200
    assert me.json()["email"] == "ana@example.com"

    rotated = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert rotated.status_code == 200
    assert rotated.json()["refresh_token"] != tokens["refresh_token"]

    reused = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert reused.status_code == 401


def test_missing_token_is_401(client: TestClient) -> None:
    assert client.get("/api/v1/auth/me").status_code == 401


def test_user_cannot_use_admin_diagnostics(
    client: TestClient,
) -> None:
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "user@example.com",
            "display_name": "Usuario",
            "password": "ClaveSegura123!",
        },
    )
    login = client.post(
        "/api/v1/auth/login",
        data={"username": "user@example.com", "password": "ClaveSegura123!"},
    ).json()
    response = client.get(
        "/api/v1/diagnostics/cache",
        headers={"Authorization": f"Bearer {login['access_token']}"},
    )
    assert response.status_code == 403


def test_current_user_validation_executes_one_user_query(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    statements: list[str] = []

    def before_cursor_execute(
        _conn, _cursor, statement, _parameters, _context, _executemany
    ) -> None:
        statements.append(statement)

    event.listen(engine, "before_cursor_execute", before_cursor_execute)
    try:
        response = client.get("/api/v1/auth/me", headers=admin_headers)
    finally:
        event.remove(engine, "before_cursor_execute", before_cursor_execute)

    assert response.status_code == 200
    user_selects = [sql for sql in statements if "FROM users" in sql]
    assert len(user_selects) == 1
