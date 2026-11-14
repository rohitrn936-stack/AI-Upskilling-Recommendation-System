from pathlib import Path
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


ENV_FILE_PATH = Path(__file__).resolve().parents[2] / ".env"


class Settings(BaseSettings):
    # API FOR AI ENGINE - configuration section
    AI_PROVIDER: str = Field(default="gemini")
    AI_MODEL: str = Field(default="")
    AI_API_KEY: str = Field(default="")
    AI_BASE_URL: str = Field(default="")
    AI_TEMPERATURE: float = Field(default=0.3)
    AI_TIMEOUT: int = Field(default=120)
    AI_MAX_RETRIES: int = Field(default=3)

    # Database
    DATABASE_URL: str = Field(default="sqlite:///./upskilling.db")

    # JWT
    JWT_SECRET_KEY: str = Field(default="dev-secret-key-change-in-production")
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=30)

    # Environment
    ENVIRONMENT: str = Field(default="development")

    # CORS
    CORS_ORIGINS: str = Field(default="http://localhost:3000,http://127.0.0.1:3000")

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE_PATH),
        extra="ignore",
    )


settings = Settings()