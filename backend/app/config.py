from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache


def _csv(name: str, default: str) -> tuple[str, ...]:
    value = os.getenv(name, default)
    return tuple(item.strip() for item in value.split(",") if item.strip())


@dataclass(frozen=True)
class Settings:
    app_name: str
    app_env: str
    database_url: str
    jwt_secret: str
    jwt_algorithm: str
    access_token_minutes: int
    refresh_token_days: int
    cache_ttl_seconds: int
    allowed_origins: tuple[str, ...]
    bootstrap_admin_email: str | None
    bootstrap_admin_password: str | None

    @property
    def diagnostics_enabled(self) -> bool:
        return self.app_env.lower() != "production"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings(
        app_name=os.getenv("APP_NAME", "WarmiBot API"),
        app_env=os.getenv("APP_ENV", "development"),
        database_url=os.getenv(
            "DATABASE_URL", "sqlite:///./warmibot_backend.db"
        ),
        jwt_secret=os.getenv("JWT_SECRET", "development-only-change-me"),
        jwt_algorithm="HS256",
        access_token_minutes=int(os.getenv("ACCESS_TOKEN_MINUTES", "15")),
        refresh_token_days=int(os.getenv("REFRESH_TOKEN_DAYS", "7")),
        cache_ttl_seconds=int(os.getenv("CACHE_TTL_SECONDS", "60")),
        allowed_origins=_csv(
            "ALLOWED_ORIGINS",
            "http://localhost,http://127.0.0.1,http://localhost:3000",
        ),
        bootstrap_admin_email=os.getenv("BOOTSTRAP_ADMIN_EMAIL"),
        bootstrap_admin_password=os.getenv("BOOTSTRAP_ADMIN_PASSWORD"),
    )


settings = get_settings()

