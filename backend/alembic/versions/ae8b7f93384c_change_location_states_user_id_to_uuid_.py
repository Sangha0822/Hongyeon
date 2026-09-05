"""change location_states.user_id to UUID foreign key

Revision ID: ae8b7f93384c
Revises: 6be18ec970b6
Create Date: 2026-09-05 15:42:56.088374

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ae8b7f93384c'
down_revision: Union[str, Sequence[str], None] = '6be18ec970b6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.drop_table('location_states')
    op.create_table(
        'location_states',
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('lat', sa.Float(), nullable=False),
        sa.Column('lng', sa.Float(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.PrimaryKeyConstraint('user_id'),
    )



def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('location_states')
    op.create_table(
        'location_states',
        sa.Column('user_id', sa.VARCHAR(), nullable=False),
        sa.Column('lat', sa.Float(), nullable=False),
        sa.Column('lng', sa.Float(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('user_id'),
    )
