import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.core.config import settings

# DATABASE_URL can be set via environment variable or .env
# Format: sqlite:///./upskilling.db or postgresql://user:password@host:port/database
database_url = os.environ.get("DATABASE_URL") or settings.DATABASE_URL

if not database_url:
    raise ValueError("DATABASE_URL environment variable not set")
Base = declarative_base()

if database_url.startswith("sqlite"):
    engine = create_engine(
        database_url,
        connect_args={"check_same_thread": False},
    )
else:
    engine = create_engine(
        database_url,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20,
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)