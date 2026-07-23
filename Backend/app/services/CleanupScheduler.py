import logging

from apscheduler.schedulers.background import BackgroundScheduler

from app.core.config import settings
from app.core.timezone import get_timezone
from app.db.session import SessionLocal
from app.services.DataCleanupService import DataCleanupService

logger = logging.getLogger(__name__)

_scheduler: BackgroundScheduler | None = None


def start_cleanup_scheduler() -> BackgroundScheduler | None:
    global _scheduler

    if not settings.DATA_CLEANUP_JOBS_ENABLED:
        logger.info("Jobs de limpieza automatica deshabilitados por configuracion.")
        return None

    if _scheduler and _scheduler.running:
        return _scheduler

    scheduler = BackgroundScheduler(
        timezone=get_timezone(settings.DATA_CLEANUP_SCHEDULER_TIMEZONE)
    )
    scheduler.add_job(
        _run_old_chat_messages_cleanup,
        trigger="cron",
        hour=settings.DATA_CLEANUP_MESSAGES_CRON_HOUR,
        minute=settings.DATA_CLEANUP_MESSAGES_CRON_MINUTE,
        id=DataCleanupService.OLD_MESSAGES_JOB,
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )
    scheduler.start()
    _scheduler = scheduler
    logger.info("Jobs de limpieza automatica iniciados correctamente.")
    return scheduler


def stop_cleanup_scheduler() -> None:
    global _scheduler

    if _scheduler and _scheduler.running:
        _scheduler.shutdown(wait=False)
        logger.info("Jobs de limpieza automatica detenidos correctamente.")
    _scheduler = None


def _run_old_chat_messages_cleanup() -> None:
    with SessionLocal() as db:
        DataCleanupService.cleanup_old_chat_messages(
            db,
            retention_days=settings.DATA_CLEANUP_RETENTION_DAYS,
            batch_size=settings.DATA_CLEANUP_BATCH_SIZE,
        )
