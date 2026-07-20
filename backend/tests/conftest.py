from __future__ import annotations

import os

os.environ["APP_ENV"] = "test"
os.environ["DATABASE_URL"] = "sqlite:///./test_warmibot_backend.db"
os.environ["JWT_SECRET"] = "test-secret-at-least-32-characters-long"
os.environ["BOOTSTRAP_ADMIN_EMAIL"] = "admin@warmibot.com"
os.environ["BOOTSTRAP_ADMIN_PASSWORD"] = "AdminTest123!"
os.environ["CACHE_TTL_SECONDS"] = "60"

import pytest
from starlette.testclient import TestClient

from app.cache import cache
from app.database import Base, engine
from app.main import app


@pytest.fixture()
def client():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as test_client:
        test_client.portal.call(cache.clear)
        yield test_client


@pytest.fixture()
def admin_tokens(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/login",
        data={"username": "admin@warmibot.com", "password": "AdminTest123!"},
    )
    assert response.status_code == 200, response.text
    return response.json()


@pytest.fixture()
def admin_headers(admin_tokens: dict[str, str]) -> dict[str, str]:
    return {"Authorization": f"Bearer {admin_tokens['access_token']}"}
