import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# DATABASE_URL should be set via environment variable
# Format: postgresql://user:password@host:port/database
database_url = os.environ.get(
    "DATABASE_URL", 
    "postgresql://localhost:5432/upskilling"
)

Base = declarative_base()

engine = create_engine(
    database_url,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)