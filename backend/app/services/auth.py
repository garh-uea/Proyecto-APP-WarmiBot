from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from ..config import settings
from ..models import RefreshToken, User
from ..schemas import TokenPair, UserOut
from ..security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_token,
)


def issue_token_pair(db: Session, user: User) -> TokenPair:
    access_token, _ = create_access_token(user)
    refresh_token, refresh_expires_at = create_refresh_token(user)
    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=hash_token(refresh_token),
            expires_at=refresh_expires_at,
        )
    )
    db.commit()
    return TokenPair(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.access_token_minutes * 60,
        user=UserOut.model_validate(user),
    )


def rotate_refresh_token(db: Session, raw_token: str) -> TokenPair:
    payload = decode_token(raw_token, "refresh")
    stored = db.scalar(
        select(RefreshToken)
        .options(joinedload(RefreshToken.user))
        .where(RefreshToken.token_hash == hash_token(raw_token))
    )
    now = datetime.now(timezone.utc)
    if stored is None or stored.revoked:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de renovación inválido o revocado",
        )

    expires_at = stored.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    user = stored.user
    if (
        expires_at <= now
        or not user.is_active
        or user.id != int(payload["sub"])
        or user.token_version != int(payload["ver"])
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de renovación expirado o sesión revocada",
        )

    stored.revoked = True
    # issue_token_pair commits the revoked token and the newly rotated token together.
    return issue_token_pair(db, user)


def revoke_refresh_token(db: Session, raw_token: str, user: User) -> None:
    stored = db.scalar(
        select(RefreshToken).where(
            RefreshToken.token_hash == hash_token(raw_token),
            RefreshToken.user_id == user.id,
        )
    )
    if stored is not None and not stored.revoked:
        stored.revoked = True
        db.commit()

