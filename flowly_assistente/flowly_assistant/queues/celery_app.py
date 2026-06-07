from __future__ import annotations

import os

try:
    from celery import Celery
except ModuleNotFoundError:  # pragma: no cover
    Celery = None  # type: ignore


def create_celery_app():
    if Celery is None:
        return None

    broker_url = os.getenv("FLOWLY_REDIS_URL", "redis://localhost:6379/0")
    result_backend = os.getenv("FLOWLY_CELERY_RESULT_BACKEND", broker_url)
    return Celery("flowly_assistant", broker=broker_url, backend=result_backend)


celery_app = create_celery_app()

if celery_app is not None:
    celery_app.conf.update(
        task_serializer="json",
        accept_content=["json"],
        result_serializer="json",
        timezone="UTC",
        enable_utc=True,
    )

