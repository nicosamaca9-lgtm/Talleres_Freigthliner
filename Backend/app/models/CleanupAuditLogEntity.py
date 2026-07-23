from sqlalchemy import Column, DateTime, Index, Integer, JSON, String
from sqlalchemy.sql import func

from app.db.base import Base


class CleanupAuditLog(Base):
    __tablename__ = "cleanup_audit_logs"
    __table_args__ = (
        Index("ix_cleanup_audit_job_created_at", "job_name", "created_at"),
    )

    id_cleanup_audit = Column(Integer, primary_key=True, index=True)
    job_name = Column(String(100), nullable=False, index=True)
    entity_name = Column(String(100), nullable=False, index=True)
    entity_id = Column(String(100), nullable=False)
    reason = Column(String(255), nullable=False)
    cutoff_at = Column(DateTime(timezone=True), nullable=False)
    metadata_json = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
