"""add cliente_correo to recibos

Revision ID: 7a2c9d4e6f10
Revises: 5c62b0fd2c71
Create Date: 2026-07-23 00:00:01.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "7a2c9d4e6f10"
down_revision: Union[str, Sequence[str], None] = "5c62b0fd2c71"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "recibos",
        sa.Column("cliente_correo", sa.String(length=150), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("recibos", "cliente_correo")
