"""merge branches

Revision ID: f3b3f989589a
Revises: 3589a886172f, d09ed0524abd
Create Date: 2026-06-13 11:40:56.542131

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f3b3f989589a'
down_revision: Union[str, Sequence[str], None] = ('3589a886172f', 'd09ed0524abd')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
