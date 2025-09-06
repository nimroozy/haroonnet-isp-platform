"""
HaroonNet ISP Platform - Database Configuration
"""

from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import settings

# Application database
app_engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    pool_recycle=300,
    pool_size=10,
    max_overflow=20,
    echo=False,
)

AppSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=app_engine)
AppBase = declarative_base()

# RADIUS database
radius_engine = create_engine(
    settings.radius_database_url,
    pool_pre_ping=True,
    pool_recycle=300,
    pool_size=5,
    max_overflow=10,
    echo=False,
)

RadiusSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=radius_engine)
RadiusBase = declarative_base()

def get_app_db():
    """Get application database session"""
    db = AppSessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_radius_db():
    """Get RADIUS database session"""
    db = RadiusSessionLocal()
    try:
        yield db
    finally:
        db.close()
