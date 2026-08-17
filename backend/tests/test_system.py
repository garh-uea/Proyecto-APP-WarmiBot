from __future__ import annotations

from starlette.testclient import TestClient

from app.config import validate_jwt_secret


def test_health_reports_backend_status(client: TestClient) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_openapi_exposes_auth_and_conversation_routes(
    client: TestClient,
) -> None:
    response = client.get("/openapi.json")

    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/auth/login" in paths
    assert "/api/v1/auth/refresh" in paths
    assert "/api/v1/conversations" in paths


def test_production_rejects_an_insecure_jwt_secret() -> None:
    try:
        validate_jwt_secret("production", "short-secret")
    except ValueError as error:
        assert "32 caracteres" in str(error)
    else:
        raise AssertionError("Se aceptó un JWT_SECRET inseguro en producción")


def test_development_allows_local_demo_secret() -> None:
    validate_jwt_secret("development", "local-demo")
