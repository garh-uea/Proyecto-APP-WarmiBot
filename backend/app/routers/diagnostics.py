from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from ..cache import cache
from ..config import settings
from ..dependencies import DbSession, require_roles
from ..models import Conversation, Message, User, UserRole
from ..schemas import OptimizationComparison, SeedRequest
from ..services.conversations import compare_loading_strategies


router = APIRouter(prefix="/diagnostics", tags=["Diagnóstico"])
AdminUser = Annotated[User, Depends(require_roles(UserRole.admin))]


def _ensure_enabled() -> None:
    if not settings.diagnostics_enabled:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ruta no disponible",
        )


@router.post("/seed", status_code=status.HTTP_201_CREATED)
async def seed_data(
    payload: SeedRequest,
    admin: AdminUser,
    db: DbSession,
) -> dict[str, int]:
    _ensure_enabled()
    created_messages = 0
    for number in range(1, payload.conversations + 1):
        conversation = Conversation(
            user_id=admin.id,
            title=f"Conversación de prueba {number}",
        )
        db.add(conversation)
        db.flush()
        for message_number in range(1, payload.messages_per_conversation + 1):
            db.add(
                Message(
                    conversation_id=conversation.id,
                    sender="user" if message_number % 2 else "assistant",
                    content=(
                        f"Mensaje {message_number} de optimización, caché y "
                        "rendimiento para WarmiBot"
                    ),
                )
            )
            created_messages += 1
    db.commit()
    await cache.invalidate_prefix(f"conversation:{admin.id}:")
    return {
        "conversations_created": payload.conversations,
        "messages_created": created_messages,
    }


@router.get("/n-plus-one", response_model=OptimizationComparison)
def n_plus_one_comparison(admin: AdminUser) -> OptimizationComparison:
    _ensure_enabled()
    return compare_loading_strategies(admin.id)


@router.get("/cache")
async def cache_statistics(admin: AdminUser) -> dict[str, int]:
    _ensure_enabled()
    return await cache.stats()
