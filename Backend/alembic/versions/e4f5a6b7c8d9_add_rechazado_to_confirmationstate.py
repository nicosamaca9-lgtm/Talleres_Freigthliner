"""Add RECHAZADO to confirmationstate

Revision ID: e4f5a6b7c8d9
Revises: 9d6d9ef2a0b4
Create Date: 2026-07-20 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "e4f5a6b7c8d9"
down_revision: Union[str, Sequence[str], None] = "9d6d9ef2a0b4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    with op.get_context().autocommit_block():
        op.execute("ALTER TYPE confirmationstate ADD VALUE IF NOT EXISTS 'RECHAZADO'")


def downgrade() -> None:
    """Downgrade schema."""
    # PostgreSQL no permite eliminar valores de un enum sin recrear el tipo.
    # Se deja como no-op para evitar tocar datos existentes en produccion.
    pass
