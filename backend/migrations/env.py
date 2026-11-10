import os
import sys

from alembic import context
from sqlalchemy import engine_from_config, pool

# Read DATABASE_URL from environment variable - required
# Raises ValueError if not set, preventing silent connection to wrong database
database_url = os.environ.get("DATABASE_URL")

if not database_url:
    raise ValueError("DATABASE_URL environment variable not set. "
                   "Set DATABASE_URL before running Alembic migrations.")

os.environ["SQLALCHEMY_URL"] = database_url
sqlalchemy_url = database_url

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))
from database.models import Base

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    context.configure(
        url=sqlalchemy_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    connectable = engine_from_config(
        {"sqlalchemy.url": sqlalchemy_url},
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()