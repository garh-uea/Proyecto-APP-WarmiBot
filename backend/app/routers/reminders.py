from __future__ import annotations

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from ..dependencies import CurrentUser, DbSession
from ..models import ReminderRecord, utcnow
from ..schemas import ReminderOut, ReminderSyncRequest


router = APIRouter(prefix="/reminders", tags=["Recordatorios"])


@router.get("", response_model=list[ReminderOut])
def list_reminders(
    current_user: CurrentUser,
    db: DbSession,
) -> list[ReminderRecord]:
    return list(
        db.scalars(
            select(ReminderRecord)
            .where(
                ReminderRecord.user_id == current_user.id,
                ReminderRecord.deleted.is_(False),
            )
            .order_by(ReminderRecord.scheduled_at.asc())
        ).all()
    )


@router.post("/sync", response_model=ReminderOut)
def sync_reminder(
    payload: ReminderSyncRequest,
    current_user: CurrentUser,
    db: DbSession,
) -> ReminderRecord:
    reminder = db.scalar(
        select(ReminderRecord).where(
            ReminderRecord.user_id == current_user.id,
            ReminderRecord.client_id == payload.client_id,
        )
    )

    if reminder is None:
        reminder = ReminderRecord(
            user_id=current_user.id,
            client_id=payload.client_id,
            text=payload.text,
            scheduled_at=payload.scheduled_at,
            reminder_type=payload.reminder_type,
            is_completed=payload.is_completed,
            deleted=payload.operation == "delete",
            version=1,
            client_updated_at=payload.client_updated_at,
        )
        db.add(reminder)
        db.commit()
        db.refresh(reminder)
        return reminder

    if payload.base_version != reminder.version:
        server_copy = ReminderOut.model_validate(reminder).model_dump(mode="json")
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "version_conflict",
                "message": "El registro cambió en otro dispositivo.",
                "server": server_copy,
            },
        )

    reminder.text = payload.text
    reminder.scheduled_at = payload.scheduled_at
    reminder.reminder_type = payload.reminder_type
    reminder.is_completed = payload.is_completed
    reminder.deleted = payload.operation == "delete"
    reminder.client_updated_at = payload.client_updated_at
    reminder.version += 1
    reminder.updated_at = utcnow()
    db.commit()
    db.refresh(reminder)
    return reminder
