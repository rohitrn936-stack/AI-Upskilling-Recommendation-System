import os
import sys

from alembic import context
from sqlalchemy import engine_from_config, pool

# Set the database URL explicitly
database_url = os.environ.get(
    "DATABASE_URL",
    "postgresql://rohitrnaik:@localhost:5432/upskilling"
)

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))
from database.models import Base

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    context.configure(
        url=database_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    connectable = engine_from_config(
        {"sqlalchemy.url": database_url},
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


# Remove the module-level context.is_offline_mode() check
# When alembic runs, it handles the mode automatically