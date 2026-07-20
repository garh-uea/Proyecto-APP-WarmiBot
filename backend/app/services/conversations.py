from __future__ import annotations

from contextlib import contextmanager
from time import perf_counter
from typing import Any, Iterator

from fastapi import HTTPException, status
from sqlalchemy import event, select
from sqlalchemy.orm import Session, lazyload, selectinload

from ..database import SessionLocal, engine
from ..models import Conversation
from ..schemas import ConversationOut, OptimizationComparison, StrategyMetric


def conversation_for_user(
    db: Session,
    conversation_id: int,
    user_id: int,
) -> Conversation:
    conversation = db.scalar(
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(
            Conversation.id == conversation_id,
            Conversation.user_id == user_id,
        )
    )
    if conversation is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversación no encontrada",
        )
    return conversation


def serialize_conversation(conversation: Conversation) -> dict[str, Any]:
    return ConversationOut.model_validate(conversation).model_dump(mode="json")


@contextmanager
def _count_queries() -> Iterator[dict[str, int]]:
    counter = {"value": 0}

    def before_cursor_execute(*_: Any) -> None:
        counter["value"] += 1

    event.listen(engine, "before_cursor_execute", before_cursor_execute)
    try:
        yield counter
    finally:
        event.remove(engine, "before_cursor_execute", before_cursor_execute)


def _measure(user_id: int, optimized: bool) -> StrategyMetric:
    with SessionLocal() as db, _count_queries() as query_counter:
        option = (
            selectinload(Conversation.messages)
            if optimized
            else lazyload(Conversation.messages)
        )
        started = perf_counter()
        conversations = db.scalars(
            select(Conversation)
            .options(option)
            .where(Conversation.user_id == user_id)
            .order_by(Conversation.id)
        ).all()
        message_count = sum(len(item.messages) for item in conversations)
        elapsed_ms = (perf_counter() - started) * 1000
        return StrategyMetric(
            queries=query_counter["value"],
            milliseconds=round(elapsed_ms, 3),
            conversations=len(conversations),
            messages=message_count,
        )


def compare_loading_strategies(user_id: int) -> OptimizationComparison:
    before = _measure(user_id, optimized=False)
    after = _measure(user_id, optimized=True)
    reduction = (
        ((before.queries - after.queries) / before.queries) * 100
        if before.queries
        else 0.0
    )
    return OptimizationComparison(
        before_n_plus_one=before,
        after_eager_loading=after,
        query_reduction_percent=round(reduction, 2),
    )

