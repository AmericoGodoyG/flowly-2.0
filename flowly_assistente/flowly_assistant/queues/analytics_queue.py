from __future__ import annotations

import os
from concurrent.futures import ThreadPoolExecutor
from typing import Any, Dict

from flowly_assistant.queues.tasks import mine_message_task
from flowly_assistant.workers.analytics_worker import process_message_analytics


_LOCAL_EXECUTOR = ThreadPoolExecutor(max_workers=int(os.getenv("FLOWLY_LOCAL_WORKER_THREADS", "2")))


def _log_local_worker_error(future) -> None:
    try:
        future.result()
    except Exception as exc:
        print(f"[ASSISTANT][analytics] erro ao salvar insight: {exc}")


class AnalyticsQueue:
    """Publishes safe messages to the analytics background pipeline."""

    def __init__(self) -> None:
        self.mode = os.getenv("FLOWLY_ANALYTICS_QUEUE_MODE", "local").strip().lower()

    def publish_message(self, event: Dict[str, Any]) -> Dict[str, Any]:
        if self.mode == "celery":
            if mine_message_task is None:
                raise RuntimeError("Celery is not installed. Install requirements and set FLOWLY_REDIS_URL.")
            async_result = mine_message_task.delay(event)
            return {"queued": True, "mode": "celery", "job_id": async_result.id}

        # Local/dev mode keeps the asynchronous contract without requiring Redis.
        # Production should use FLOWLY_ANALYTICS_QUEUE_MODE=celery.
        future = _LOCAL_EXECUTOR.submit(process_message_analytics, event)
        future.add_done_callback(_log_local_worker_error)
        return {"queued": True, "mode": "local_thread"}
