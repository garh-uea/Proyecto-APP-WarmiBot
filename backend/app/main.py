from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select

from .config import settings
from .database import Base, SessionLocal, engine
from .models import User, UserRole
from .routers import auth, conversations, diagnostics, jobs
from .security import hash_password
from .worker import job_queue


def _bootstrap_admin() -> None:
    email = settings.bootstrap_admin_email
    password = settings.bootstrap_admin_password
    if not email or not password:
        return
    with SessionLocal() as db:
        existing = db.scalar(
            select(User).where(func.lower(User.email) == email.lower())
        )
        if existing is None:
            db.add(
                User(
                    email=email.lower(),
                    display_name="Administrador WarmiBot",
                    password_hash=hash_password(password),
                    role=UserRole.admin,
                )
            )
            db.commit()


@asynccontextmanager
async def lifespan(_app: FastAPI):
    Base.metadata.create_all(bind=engine)
    _bootstrap_admin()
    await job_queue.start()
    try:
        yield
    finally:
        await job_queue.stop()


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description=(
        "API segura y optimizada para WarmiBot: JWT, refresh token, caché "
        "cache-aside, eager loading y tareas asíncronas."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.allowed_origins),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

api_prefix = "/api/v1"
app.include_router(auth.router, prefix=api_prefix)
app.include_router(conversations.router, prefix=api_prefix)
app.include_router(jobs.router, prefix=api_prefix)
app.include_router(diagnostics.router, prefix=api_prefix)


@app.get("/health", tags=["Sistema"])
def health() -> dict[str, str]:
    return {"status": "ok", "environment": settings.app_env}
