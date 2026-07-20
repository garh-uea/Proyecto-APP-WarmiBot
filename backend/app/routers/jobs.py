from __future__ import annotations

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from ..dependencies import CurrentUser, DbSession
from ..models import AsyncJob
from ..schemas import JobOut
from ..services.conversations import conversation_for_user
from ..worker import job_queue


router = APIRouter(prefix="/jobs", tags=["Tareas asíncronas"])


@router.post(
    "/conversation-summary/{conversation_id}",
    response_model=JobOut,
    status_code=status.HTTP_202_ACCEPTED,
)
async def create_summary_job(
    conversation_id: int,
    current_user: CurrentUser,
    db: DbSession,
) -> AsyncJob:
    conversation_for_user(db, conversation_id, current_user.id)
    job = AsyncJob(
        user_id=current_user.id,
        conversation_id=conversation_id,
        kind="conversation_summary",
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    await job_queue.enqueue(job.id)
    return job


@router.get("/{job_id}", response_model=JobOut)
def get_job(job_id: str, current_user: CurrentUser, db: DbSession) -> AsyncJob:
    job = db.scalar(
        select(AsyncJob).where(
            AsyncJob.id == job_id,
            AsyncJob.user_id == current_user.id,
        )
    )
    if job is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tarea no encontrada",
        )
    return job

