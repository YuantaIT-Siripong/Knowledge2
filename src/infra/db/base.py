"""
Database base configuration and session management.
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
import os

# SQLAlchemy declarative base
Base = declarative_base()

# Database URL - MSSQL connection string
# Format: mssql+pyodbc://user:password@host:port/database?driver=ODBC+Driver+18+for+SQL+Server
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "mssql+pyodbc://sa:YourStrong@Passw0rd@localhost:1433/fcn_db?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
)

# Create SQLAlchemy engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
    echo=False,
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    """
    Dependency function to get database session.
    Yields a session and ensures it's closed after use.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
