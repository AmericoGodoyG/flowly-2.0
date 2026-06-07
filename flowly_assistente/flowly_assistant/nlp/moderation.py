from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class ModerationResult:
    allowed: bool
    reason: str = ""
    score: float = 0.0


class ModerationService:
    """Lightweight moderation gate.

    This is intentionally small and deterministic for the initial codebase.
    Replace `moderate` internals with OpenAI Moderation, Perspective API, or
    a local classifier when production requirements are defined.
    """

    def __init__(self) -> None:
        self._blocked_patterns = [
            re.compile(pattern, re.IGNORECASE)
            for pattern in (
                r"\b(matar|espancar|viol[eê]ncia|amea[cç]a)\b",
                r"\b(filho da puta|idiota|burro|lixo)\b",
                r"\b(spam|promo[cç][aã]o imperd[ií]vel|clique aqui)\b",
            )
        ]

    def moderate(self, text: str) -> ModerationResult:
        normalized = " ".join((text or "").split())
        if not normalized:
            return ModerationResult(allowed=False, reason="empty_content", score=1.0)

        for pattern in self._blocked_patterns:
            if pattern.search(normalized):
                return ModerationResult(allowed=False, reason="unsafe_content", score=0.95)

        if len(normalized) > 4000:
            return ModerationResult(allowed=False, reason="possible_spam", score=0.8)

        return ModerationResult(allowed=True, score=0.02)

