import os
import sys

from alembic import context
from sqlalchemy import engine_from_config, pool

# Read DATABASE_URL from environment variable
database_url = os.environ.get("DATABASE_URL")

if database_url:
    os.environ["SQLALCHEMY_URL"] = database_url
    sqlalchemy_url = database_url
else:
    # Fallback for local development - should be set via env var in production
    sqlalchemy_url = os.environ.get(
        "SQLALCHEMY_URL", 
        "postgresql://localhost:5432/upskilling"
    )
    os.environ["SQLALCHEMY_URL"] = sqlalchemy_url

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