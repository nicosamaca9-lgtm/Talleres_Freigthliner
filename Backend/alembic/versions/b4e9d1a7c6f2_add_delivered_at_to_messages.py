"""add delivered_at to messages

Revision ID: b4e9d1a7c6f2
Revises: a3d8f0b2c9e1
Create Date: 2026-07-17 00:00:01.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "b4e9d1a7c6f2"
down_revision: Union[str, Sequence[str], None] = "a3d8f0b2c9e1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("messages", sa.Column("delivered_at", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("messages", "delivered_at")
