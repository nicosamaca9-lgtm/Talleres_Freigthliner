"""add device tokens

Revision ID: c7e2a91d5f13
Revises: b4e9d1a7c6f2
Create Date: 2026-07-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c7e2a91d5f13"
down_revision: Union[str, Sequence[str], None] = "b4e9d1a7c6f2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "device_tokens",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("device_id", sa.String(length=128), nullable=False),
        sa.Column("fcm_token", sa.String(length=512), nullable=False),
        sa.Column("platform", sa.String(length=32), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["usuarios.id_usuario"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("fcm_token", name="uq_device_tokens_fcm_token"),
        sa.UniqueConstraint("user_id", "device_id", name="uq_device_tokens_user_device"),
    )
    op.create_index(op.f("ix_device_tokens_id"), "device_tokens", ["id"], unique=False)
    op.create_index(op.f("ix_device_tokens_user_id"), "device_tokens", ["user_id"], unique=False)
    op.create_index("ix_device_tokens_user_active", "device_tokens", ["user_id", "is_active"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_device_tokens_user_active", table_name="device_tokens")
    op.drop_index(op.f("ix_device_tokens_user_id"), table_name="device_tokens")
    op.drop_index(op.f("ix_device_tokens_id"), table_name="device_tokens")
    op.drop_table("device_tokens")
