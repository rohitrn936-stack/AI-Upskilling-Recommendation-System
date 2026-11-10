from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # API FOR AI ENGINE - configuration section
    AI_PROVIDER: str = Field(default="gemini", env="AI_PROVIDER")
    AI_MODEL: str = Field(default="", env="AI_MODEL")
    AI_API_KEY: str = Field(default="", env="AI_API_KEY")
    AI_BASE_URL: str = Field(default="", env="AI_BASE_URL")
    AI_TEMPERATURE: float = Field(default=0.3, env="AI_TEMPERATURE")
    AI_TIMEOUT: int = Field(default=120, env="AI_TIMEOUT")
    AI_MAX_RETRIES: int = Field(default=3, env="AI_MAX_RETRIES")

    # Database
    DATABASE_URL: str = Field(default="postgresql://rohitrnaik:@localhost:5432/upskilling", env="DATABASE_URL")

    # JWT
    JWT_SECRET_KEY: str = Field(default="your-jwt-secret-key-change-in-production", env="JWT_SECRET_KEY")
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=30, env="JWT_ACCESS_TOKEN_EXPIRE_MINUTES")

    # Environment
    ENVIRONMENT: str = Field(default="development", env="ENVIRONMENT")

    class Config:
        env_file = ".env"


settings = Settings()