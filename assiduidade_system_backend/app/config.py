import os

from dotenv import load_dotenv

load_dotenv()


class Settings:
    app_name: str = os.getenv("APP_NAME", "FaceClock API")
    app_version: str = os.getenv("APP_VERSION", "1.0.0")
    database_url: str = os.getenv("DATABASE_URL", "postgresql://postgres:admin@postgres:5432/faceclock")
    jwt_algorithm: str = os.getenv("JWT_ALGORITHM", "HS256")
    access_token_expire_minutes: int = int(
        os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    )
    biometric_quality_threshold: float = float(
        os.getenv("BIOMETRIC_QUALITY_THRESHOLD", "0.55")
    )
    biometric_liveness_threshold: float = float(
        os.getenv("BIOMETRIC_LIVENESS_THRESHOLD", "0.60")
    )
    biometric_match_threshold: float = float(
        os.getenv("BIOMETRIC_MATCH_THRESHOLD", "0.85")
    )
    seed_data_on_startup: bool = os.getenv("SEED_DATA_ON_STARTUP", "false").lower() == "true"
    docs_url: str = os.getenv("DOCS_URL", "/docs")
    openapi_url: str = os.getenv("OPENAPI_URL", "/openapi.json")
    payroll_provider_base_url: str = os.getenv("PAYROLL_PROVIDER_BASE_URL", "")
    payroll_provider_api_key: str = os.getenv("PAYROLL_PROVIDER_API_KEY", "")
    payroll_provider_timeout_seconds: int = int(
        os.getenv("PAYROLL_PROVIDER_TIMEOUT_SECONDS", "30")
    )
    erp_base_url: str = os.getenv("ERP_BASE_URL", "")
    erp_api_key: str = os.getenv("ERP_API_KEY", "")
    erp_timeout_seconds: int = int(os.getenv("ERP_TIMEOUT_SECONDS", "10"))
    erp_fallback_local_login: bool = os.getenv(
        "ERP_FALLBACK_LOCAL_LOGIN", "true"
    ).lower() == "true"

    @property
    def jwt_secret_key(self) -> str:
        """Retorna a chave JWT garantindo tamanho minimo de 32 bytes."""
        key = os.getenv("JWT_SECRET_KEY", "change-me-in-production")
        if len(key.encode("utf-8")) < 32:
            key = (key * ((32 // len(key)) + 1))[:32]
        return key


settings = Settings()
