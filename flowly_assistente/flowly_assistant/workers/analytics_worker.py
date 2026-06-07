from __future__ import annotations

from typing import Any, Dict

from flowly_assistant.nlp.mining import NlpMiningService
from flowly_assistant.storage.analytics_repository import AnalyticsRepository


def process_message_analytics(event: Dict[str, Any]) -> Dict[str, Any]:
    """Worker use case for asynchronous PLN mining."""

    content = str(event.get("content") or "")
    insight = NlpMiningService().mine(content).to_dict()
    AnalyticsRepository().save_insight(event, insight)
    return insight

