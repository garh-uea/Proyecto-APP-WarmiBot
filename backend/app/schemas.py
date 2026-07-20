from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from .models import JobStatus, UserRole


class RegisterRequest(BaseModel):
    email: EmailStr
    display_name: str = Field(min_length=2, max_length=100)
    password: str = Field(min_length=10, max_length=128)


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=20)


class LogoutRequest(RefreshRequest):
    pass


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    display_name: str
    role: UserRole
    is_active: bool
    created_at: datetime


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_in: int
    user: UserOut


class MessageCreate(BaseModel):
    sender: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=8000)


class MessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sender: str
    content: str
    created_at: datetime


class ConversationCreate(BaseModel):
    title: str = Field(min_length=1, max_length=160)


class ConversationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    created_at: datetime
    updated_at: datetime
    messages: list[MessageOut]


class JobOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    kind: str
    status: JobStatus
    result: dict[str, Any] | None
    error: str | None
    created_at: datetime
    updated_at: datetime


class SeedRequest(BaseModel):
    conversations: int = Field(default=10, ge=1, le=100)
    messages_per_conversation: int = Field(default=5, ge=1, le=100)


class StrategyMetric(BaseModel):
    queries: int
    milliseconds: float
    conversations: int
    messages: int


class OptimizationComparison(BaseModel):
    before_n_plus_one: StrategyMetric
    after_eager_loading: StrategyMetric
    query_reduction_percent: float

