from __future__ import annotations

import asyncio
from collections import Counter

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from .database import SessionLocal
from .models import AsyncJob, Conversation, JobStatus


class JobQueue:
    def __init__(self) -> None:
        self._queue: asyncio.Queue[str | None] | None = None
        self._worker_task: asyncio.Task[None] | None = None

    async def start(self) -> None:
        if self._worker_task is None:
            # Bind the queue to the event loop that owns this application lifespan.
            self._queue = asyncio.Queue()
            self._worker_task = asyncio.create_task(
                self._run(), name="warmibot-job-worker"
            )

    async def stop(self) -> None:
        if self._worker_task is None:
            return
        assert self._queue is not None
        await self._queue.put(None)
        await self._worker_task
        self._worker_task = None
        self._queue = None

    async def enqueue(self, job_id: str) -> None:
        if self._queue is None:
            raise RuntimeError("El worker no está iniciado")
        await self._queue.put(job_id)

    async def _run(self) -> None:
        assert self._queue is not None
        while True:
            job_id = await self._queue.get()
            try:
                if job_id is None:
                    return
                await asyncio.to_thread(self._process_job, job_id)
            finally:
                self._queue.task_done()

    @staticmethod
    def _process_job(job_id: str) -> None:
        with SessionLocal() as db:
            job = db.get(AsyncJob, job_id)
            if job is None:
                return
            job.status = JobStatus.processing
            db.commit()
            try:
                conversation = db.scalar(
                    select(Conversation)
                    .options(selectinload(Conversation.messages))
                    .where(Conversation.id == job.conversation_id)
                )
                if conversation is None:
                    raise ValueError("La conversación ya no existe")
                words = [
                    word.strip(".,;:!?¡¿()[]{}\"'").lower()
                    for message in conversation.messages
                    for word in message.content.split()
                ]
                frequencies = Counter(word for word in words if len(word) > 3)
                job.result = {
                    "conversation_id": conversation.id,
                    "message_count": len(conversation.messages),
                    "word_count": len(words),
                    "frequent_terms": [
                        {"term": term, "count": count}
                        for term, count in frequencies.most_common(5)
                    ],
                }
                job.status = JobStatus.completed
                job.error = None
            except Exception as exc:  # The job records failures for later inspection.
                job.status = JobStatus.failed
                job.error = str(exc)
            db.commit()


job_queue = JobQueue()
