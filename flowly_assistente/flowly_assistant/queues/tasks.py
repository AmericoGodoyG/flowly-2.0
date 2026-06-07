from __future__ import annotations

from typing import Any, Dict

from flowly_assistant.queues.celery_app import celery_app
from flowly_assistant.workers.analytics_worker import process_message_analytics


if celery_app is not None:

    @celery_app.task(name="flowly_assistant.mine_message")
    def mine_message_task(event: Dict[str, Any]) -> Dict[str, Any]:
        return process_message_analytics(event)

else:
    mine_message_task = None

