from __future__ import annotations

import base64
import hashlib
import hmac
import os
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

import jwt
from fastapi import HTTPException, status

from .config import settings
from .models import User


_SCRYPT_N = 2**14
_SCRYPT_R = 8
_SCRYPT_P = 1
_KEY_LENGTH = 64


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    digest = hashlib.scrypt(
        password.encode("utf-8"),
        salt=salt,
        n=_SCRYPT_N,
        r=_SCRYPT_R,
        p=_SCRYPT_P,
        dklen=_KEY_LENGTH,
    )
    return "scrypt${}${}${}${}${}".format(
        _SCRYPT_N,
        _SCRYPT_R,
        _SCRYPT_P,
        base64.urlsafe_b64encode(salt).decode("ascii"),
        base64.urlsafe_b64encode(digest).decode("ascii"),
    )


def verify_password(password: str, encoded: str) -> bool:
    try:
        algorithm, n, r, p, salt_b64, digest_b64 = encoded.split("$", 5)
        if algorithm != "scrypt":
            return False
        salt = base64.urlsafe_b64decode(salt_b64.encode("ascii"))
        expected = base64.urlsafe_b64decode(digest_b64.encode("ascii"))
        actual = hashlib.scrypt(
            password.encode("utf-8"),
            salt=salt,
            n=int(n),
            r=int(r),
            p=int(p),
            dklen=len(expected),
        )
    except (ValueError, TypeError):
        return False
    return hmac.compare_digest(actual, expected)


def _encode_token(
    user: User,
    token_type: str,
    expires_delta: timedelta,
) -> tuple[str, datetime]:
    now = datetime.now(timezone.utc)
    expires_at = now + expires_delta
    payload = {
        "sub": str(user.id),
        "role": user.role.value,
        "type": token_type,
        "ver": user.token_version,
        "iat": now,
        "exp": expires_at,
        "jti": str(uuid.uuid4()),
    }
    return (
        jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm),
        expires_at,
    )


def create_access_token(user: User) -> tuple[str, datetime]:
    return _encode_token(
        user,
        "access",
        timedelta(minutes=settings.access_token_minutes),
    )


def create_refresh_token(user: User) -> tuple[str, datetime]:
    return _encode_token(
        user,
        "refresh",
        timedelta(days=settings.refresh_token_days),
    )


def decode_token(token: str, expected_type: str) -> dict[str, Any]:
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token ausente, inválido o expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
            options={"require": ["sub", "type", "exp", "jti", "ver"]},
        )
    except jwt.PyJWTError as exc:
        raise credentials_error from exc
    if payload.get("type") != expected_type:
        raise credentials_error
    return payload


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
