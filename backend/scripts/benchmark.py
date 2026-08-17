from __future__ import annotations

import argparse
import json
import time

import httpx


def main() -> None:
    parser = argparse.ArgumentParser(description="Benchmark reproducible de WarmiBot")
    parser.add_argument("--base-url", default="http://127.0.0.1:800")
    parser.add_argument("--email", default="admin@warmibot.com")
    parser.add_argument("--password", default="ChangeMe123!")
    args = parser.parse_args()

    with httpx.Client(base_url=args.base_url, timeout=20) as client:
        login = client.post(
            "/api/v1/auth/login",
            data={"username": args.email, "password": args.password},
        )
        login.raise_for_status()
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        seed = client.post(
            "/api/v1/diagnostics/seed",
            headers=headers,
            json={"conversations": 20, "messages_per_conversation": 5},
        )
        seed.raise_for_status()

        comparison = client.get(
            "/api/v1/diagnostics/n-plus-one", headers=headers
        )
        comparison.raise_for_status()

        conversations = client.get("/api/v1/conversations", headers=headers)
        conversations.raise_for_status()
        conversation_id = conversations.json()[0]["id"]

        cache_results = []
        for attempt in ("primera_lectura", "segunda_lectura"):
            started = time.perf_counter()
            response = client.get(
                f"/api/v1/conversations/{conversation_id}", headers=headers
            )
            elapsed = (time.perf_counter() - started) * 1000
            response.raise_for_status()
            cache_results.append(
                {
                    "attempt": attempt,
                    "cache": response.headers.get("X-Cache"),
                    "milliseconds": round(elapsed, 3),
                }
            )

        print(
            json.dumps(
                {
                    "seed": seed.json(),
                    "n_plus_one": comparison.json(),
                    "cache_aside": cache_results,
                },
                indent=2,
                ensure_ascii=False,
            )
        )


if __name__ == "__main__":
    main()
