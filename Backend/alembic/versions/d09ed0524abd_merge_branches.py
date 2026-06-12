"""Merge branches

Revision ID: d09ed0524abd
Revises: 32e3f78521dc, 5f42467f58e6
Create Date: 2026-06-12 12:37:18.078863

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd09ed0524abd'
down_revision: Union[str, Sequence[str], None] = ('32e3f78521dc', '5f42467f58e6')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
