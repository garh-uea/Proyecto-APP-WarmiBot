from __future__ import annotations

from fastapi import APIRouter, Response, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ..cache import cache
from ..config import settings
from ..dependencies import CurrentUser, DbSession
from ..models import Conversation, Message, utcnow
from ..schemas import (
    ConversationCreate,
    ConversationOut,
    MessageCreate,
    MessageOut,
)
from ..services.conversations import conversation_for_user, serialize_conversation


router = APIRouter(prefix="/conversations", tags=["Conversaciones"])


def _cache_key(user_id: int, conversation_id: int) -> str:
    return f"conversation:{user_id}:{conversation_id}"


@router.post("", response_model=ConversationOut, status_code=status.HTTP_201_CREATED)
def create_conversation(
    payload: ConversationCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> Conversation:
    conversation = Conversation(user_id=current_user.id, title=payload.title.strip())
    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    return conversation


@router.get("", response_model=list[ConversationOut])
def list_conversations(
    current_user: CurrentUser,
    db: DbSession,
) -> list[Conversation]:
    # Eager loading fixes the former 1 + N query pattern.
    return list(
        db.scalars(
            select(Conversation)
            .options(selectinload(Conversation.messages))
            .where(Conversation.user_id == current_user.id)
            .order_by(Conversation.updated_at.desc())
        ).all()
    )


@router.get("/{conversation_id}", response_model=ConversationOut)
async def get_conversation(
    conversation_id: int,
    response: Response,
    current_user: CurrentUser,
    db: DbSession,
) -> ConversationOut:
    key = _cache_key(current_user.id, conversation_id)
    cached = await cache.get(key)
    if cached is not None:
        response.headers["X-Cache"] = "HIT"
        return ConversationOut.model_validate(cached)

    conversation = conversation_for_user(db, conversation_id, current_user.id)
    serialized = serialize_conversation(conversation)
    await cache.set(key, serialized, settings.cache_ttl_seconds)
    response.headers["X-Cache"] = "MISS"
    response.headers["X-Cache-TTL"] = str(settings.cache_ttl_seconds)
    # The API owns invalidation; clients must not keep an independent stale copy.
    response.headers["Cache-Control"] = "no-store"
    return ConversationOut.model_validate(serialized)


@router.post(
    "/{conversation_id}/messages",
    response_model=MessageOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_message(
    conversation_id: int,
    payload: MessageCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> Message:
    conversation = conversation_for_user(db, conversation_id, current_user.id)
    message = Message(
        conversation_id=conversation.id,
        sender=payload.sender,
        content=payload.content.strip(),
    )
    conversation.updated_at = utcnow()
    db.add(message)
    db.commit()
    db.refresh(message)
    # Explicit invalidation prevents stale conversation details.
    await cache.delete(_cache_key(current_user.id, conversation_id))
    return message


@router.delete("/{conversation_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_conversation(
    conversation_id: int,
    current_user: CurrentUser,
    db: DbSession,
) -> Response:
    conversation = conversation_for_user(db, conversation_id, current_user.id)
    db.delete(conversation)
    db.commit()
    await cache.delete(_cache_key(current_user.id, conversation_id))
    return Response(status_code=status.HTTP_204_NO_CONTENT)
