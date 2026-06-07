"""Celery worker entrypoint.

Run with:
    celery -A worker.celery_app worker --loglevel=INFO
"""

from flowly_assistant.queues.celery_app import celery_app
from flowly_assistant.queues import tasks  # noqa: F401 - registers tasks


if celery_app is None:  # pragma: no cover
    raise RuntimeError("Celery is not installed. Run `pip install -r requirements.txt`.")
