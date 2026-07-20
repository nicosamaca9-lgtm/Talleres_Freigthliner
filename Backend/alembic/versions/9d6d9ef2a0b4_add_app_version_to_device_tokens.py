"""add app version to device tokens

Revision ID: 9d6d9ef2a0b4
Revises: c7e2a91d5f13
Create Date: 2026-07-19 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "9d6d9ef2a0b4"
down_revision: Union[str, Sequence[str], None] = "c7e2a91d5f13"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "device_tokens",
        sa.Column("app_version", sa.String(length=32), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("device_tokens", "app_version")
