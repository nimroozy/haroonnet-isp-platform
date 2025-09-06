"""
HaroonNet ISP Platform - Worker Configuration
"""

import os
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings"""

    # Celery configuration
    CELERY_BROKER_URL: str = "redis://redis:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://redis:6379/0"

    # Database configuration
    DB_HOST: str = "mysql"
    DB_PORT: int = 3306
    DB_NAME: str = "haroonnet"
    DB_USER: str = "haroonnet"
    DB_PASSWORD: str = "haroonnet123"

    # RADIUS Database configuration
    RADIUS_DB_HOST: str = "mysql"
    RADIUS_DB_PORT: int = 3306
    RADIUS_DB_NAME: str = "radius"
    RADIUS_DB_USER: str = "radius"
    RADIUS_DB_PASSWORD: str = "radpass"

    # Redis configuration
    REDIS_HOST: str = "redis"
    REDIS_PORT: int = 6379
    REDIS_PASSWORD: Optional[str] = None
    REDIS_DB: int = 0

    # Email configuration
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    SMTP_USE_TLS: bool = True

    # SMS configuration
    SMS_PROVIDER: str = "twilio"
    TWILIO_ACCOUNT_SID: Optional[str] = None
    TWILIO_AUTH_TOKEN: Optional[str] = None
    TWILIO_FROM_NUMBER: Optional[str] = None

    # Payment gateway configuration
    STRIPE_SECRET_KEY: Optional[str] = None
    STRIPE_PUBLISHABLE_KEY: Optional[str] = None

    # Company configuration
    COMPANY_NAME: str = "HaroonNet ISP"
    COMPANY_EMAIL: str = "admin@haroonnet.com"
    COMPANY_PHONE: str = "+93-123-456-789"
    COMPANY_TIMEZONE: str = "Asia/Kabul"
    DEFAULT_CURRENCY: str = "AFN"

    # RADIUS CoA configuration
    COA_SECRET: str = "haroonnet-coa-secret-2024"
    COA_PORT: int = 3799

    # Backup configuration
    BACKUP_RETENTION_DAYS: int = 30
    S3_BACKUP_BUCKET: Optional[str] = None
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None

    # Monitoring configuration
    MONITORING_ENABLED: bool = True
    METRICS_RETENTION_DAYS: int = 90

    # Logging configuration
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    # Task configuration
    BILLING_CYCLE_DAY: int = 1  # Day of month to generate invoices
    PAYMENT_REMINDER_DAYS: list[int] = [3, 7, 14]  # Days before due date
    OVERDUE_GRACE_DAYS: int = 7
    QUOTA_WARNING_THRESHOLD: float = 0.8  # 80%

    @property
    def database_url(self) -> str:
        """Get database URL for SQLAlchemy"""
        return f"mysql+pymysql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    @property
    def radius_database_url(self) -> str:
        """Get RADIUS database URL for SQLAlchemy"""
        return f"mysql+pymysql://{self.RADIUS_DB_USER}:{self.RADIUS_DB_PASSWORD}@{self.RADIUS_DB_HOST}:{self.RADIUS_DB_PORT}/{self.RADIUS_DB_NAME}"

    @property
    def redis_url(self) -> str:
        """Get Redis URL"""
        if self.REDIS_PASSWORD:
            return f"redis://:{self.REDIS_PASSWORD}@{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
        return f"redis://{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"

    # Pydantic v2 settings configuration
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True)


# Global settings instance
settings = Settings()
