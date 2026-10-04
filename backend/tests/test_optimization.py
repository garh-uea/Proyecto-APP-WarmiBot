from __future__ import annotations

import time

from starlette.testclient import TestClient


def _create_conversation(
    client: TestClient,
    headers: dict[str, str],
) -> int:
    response = client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "Prueba de optimización"},
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


def test_eager_loading_reduces_n_plus_one_queries(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    seed = client.post(
        "/api/v1/diagnostics/seed",
        headers=admin_headers,
        json={"conversations": 8, "messages_per_conversation": 4},
    )
    assert seed.status_code == 201

    comparison = client.get(
        "/api/v1/diagnostics/n-plus-one", headers=admin_headers
    )
    assert comparison.status_code == 200
    result = comparison.json()
    assert result["before_n_plus_one"]["queries"] == 9
    assert result["after_eager_loading"]["queries"] == 2
    assert result["query_reduction_percent"] > 70


def test_cache_aside_hit_and_explicit_invalidation(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    conversation_id = _create_conversation(client, admin_headers)

    first = client.get(
        f"/api/v1/conversations/{conversation_id}", headers=admin_headers
    )
    second = client.get(
        f"/api/v1/conversations/{conversation_id}", headers=admin_headers
    )
    assert first.headers["X-Cache"] == "MISS"
    assert second.headers["X-Cache"] == "HIT"

    added = client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=admin_headers,
        json={"sender": "user", "content": "Mensaje que invalida la caché"},
    )
    assert added.status_code == 201

    after_write = client.get(
        f"/api/v1/conversations/{conversation_id}", headers=admin_headers
    )
    assert after_write.headers["X-Cache"] == "MISS"
    assert len(after_write.json()["messages"]) == 1


def test_async_worker_completes_summary_job(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    conversation_id = _create_conversation(client, admin_headers)
    client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=admin_headers,
        json={
            "sender": "user",
            "content": "WarmiBot mejora rendimiento mediante cache y tareas asíncronas",
        },
    )

    queued = client.post(
        f"/api/v1/jobs/conversation-summary/{conversation_id}",
        headers=admin_headers,
    )
    assert queued.status_code == 202
    job_id = queued.json()["id"]

    result = None
    for _ in range(30):
        result = client.get(f"/api/v1/jobs/{job_id}", headers=admin_headers)
        if result.json()["status"] in {"completed", "failed"}:
            break
        time.sleep(0.02)

    assert result is not None
    assert result.json()["status"] == "completed"
    assert result.json()["result"]["message_count"] == 1
