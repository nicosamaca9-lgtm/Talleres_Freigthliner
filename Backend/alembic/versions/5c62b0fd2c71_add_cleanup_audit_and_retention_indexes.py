"""add cleanup audit and retention indexes

Revision ID: 5c62b0fd2c71
Revises: 23e9f9f2022d
Create Date: 2026-07-23 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "5c62b0fd2c71"
down_revision: Union[str, Sequence[str], None] = "23e9f9f2022d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "cleanup_audit_logs",
        sa.Column("id_cleanup_audit", sa.Integer(), nullable=False),
        sa.Column("job_name", sa.String(length=100), nullable=False),
        sa.Column("entity_name", sa.String(length=100), nullable=False),
        sa.Column("entity_id", sa.String(length=100), nullable=False),
        sa.Column("reason", sa.String(length=255), nullable=False),
        sa.Column("cutoff_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id_cleanup_audit"),
    )
    op.create_index(
        "ix_cleanup_audit_logs_id_cleanup_audit",
        "cleanup_audit_logs",
        ["id_cleanup_audit"],
        unique=False,
    )
    op.create_index(
        "ix_cleanup_audit_logs_job_name",
        "cleanup_audit_logs",
        ["job_name"],
        unique=False,
    )
    op.create_index(
        "ix_cleanup_audit_logs_entity_name",
        "cleanup_audit_logs",
        ["entity_name"],
        unique=False,
    )
    op.create_index(
        "ix_cleanup_audit_job_created_at",
        "cleanup_audit_logs",
        ["job_name", "created_at"],
        unique=False,
    )
    op.create_index("ix_messages_timestamp", "messages", ["timestamp"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_messages_timestamp", table_name="messages")
    op.drop_index("ix_cleanup_audit_job_created_at", table_name="cleanup_audit_logs")
    op.drop_index("ix_cleanup_audit_logs_entity_name", table_name="cleanup_audit_logs")
    op.drop_index("ix_cleanup_audit_logs_job_name", table_name="cleanup_audit_logs")
    op.drop_index("ix_cleanup_audit_logs_id_cleanup_audit", table_name="cleanup_audit_logs")
    op.drop_table("cleanup_audit_logs")
