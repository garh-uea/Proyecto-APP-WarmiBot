from __future__ import annotations

import asyncio
import time
from copy import deepcopy
from dataclasses import dataclass
from typing import Any


@dataclass
class _Entry:
    value: Any
    expires_at: float


class TTLCache:
    """Small process-local cache implementing cache-aside semantics."""

    def __init__(self) -> None:
        self._entries: dict[str, _Entry] = {}
        self._lock = asyncio.Lock()
        self.hits = 0
        self.misses = 0

    async def get(self, key: str) -> Any | None:
        now = time.monotonic()
        async with self._lock:
            entry = self._entries.get(key)
            if entry is None:
                self.misses += 1
                return None
            if entry.expires_at <= now:
                self._entries.pop(key, None)
                self.misses += 1
                return None
            self.hits += 1
            return deepcopy(entry.value)

    async def set(self, key: str, value: Any, ttl_seconds: int) -> None:
        async with self._lock:
            self._entries[key] = _Entry(
                value=deepcopy(value),
                expires_at=time.monotonic() + ttl_seconds,
            )

    async def delete(self, key: str) -> None:
        async with self._lock:
            self._entries.pop(key, None)

    async def invalidate_prefix(self, prefix: str) -> int:
        async with self._lock:
            keys = [key for key in self._entries if key.startswith(prefix)]
            for key in keys:
                self._entries.pop(key, None)
            return len(keys)

    async def clear(self) -> None:
        async with self._lock:
            self._entries.clear()
            self.hits = 0
            self.misses = 0

    async def stats(self) -> dict[str, int]:
        async with self._lock:
            return {
                "entries": len(self._entries),
                "hits": self.hits,
                "misses": self.misses,
            }


cache = TTLCache()
