from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache


def _csv(name: str, default: str) -> tuple[str, ...]:
    value = os.getenv(name, default)
    return tuple(item.strip() for item in value.split(",") if item.strip())


def validate_jwt_secret(app_env: str, jwt_secret: str) -> None:
    if app_env.lower() != "production":
        return
    insecure_values = {
        "development-only-change-me",
        "change-this-secret-before-production",
    }
    if jwt_secret in insecure_values or len(jwt_secret) < 32:
        raise ValueError(
            "JWT_SECRET debe tener al menos 32 caracteres aleatorios en producción"
        )


def normalize_database_url(database_url: str) -> str:
    """Use the psycopg 3 driver for PostgreSQL URLs supplied by hosts."""
    if database_url.startswith("postgres://"):
        return database_url.replace("postgres://", "postgresql+psycopg://", 1)
    if database_url.startswith("postgresql://"):
        return database_url.replace(
            "postgresql://", "postgresql+psycopg://", 1
        )
    return database_url


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
    app_env = os.getenv("APP_ENV", "development")
    jwt_secret = os.getenv("JWT_SECRET", "development-only-change-me")
    validate_jwt_secret(app_env, jwt_secret)
    default_access_minutes = "15" if app_env.lower() == "production" else "1"
    return Settings(
        app_name=os.getenv("APP_NAME", "WarmiBot API"),
        app_env=app_env,
        database_url=normalize_database_url(
            os.getenv("DATABASE_URL", "sqlite:///./warmibot_backend.db")
        ),
        jwt_secret=jwt_secret,
        jwt_algorithm="HS256",
        access_token_minutes=int(
            os.getenv("ACCESS_TOKEN_MINUTES", default_access_minutes)
        ),
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
