import os

from dotenv import load_dotenv

load_dotenv()


DEFAULT_BIOMETRIC_ENCRYPTION_KEY = "change-me-in-production-biometric-key-32bytes"
DEFAULT_FACIAL_VERIFICATION_SECRET = "change-me-facial-verification-secret"
DEFAULT_NEXORA_CREDENTIAL_ENCRYPTION_KEY = "change-me-nexora-credential-encryption-key"


class Settings:
    app_name: str = os.getenv("APP_NAME", "FaceClock API")
    app_version: str = os.getenv("APP_VERSION", "1.0.0")
    environment: str = os.getenv("ENVIRONMENT", "development")
    database_url: str = os.getenv("DATABASE_URL", "postgresql://postgres:admin@postgres:5432/faceclock")
    biometric_quality_threshold: float = float(
        os.getenv("BIOMETRIC_QUALITY_THRESHOLD", "0.55")
    )
    biometric_liveness_threshold: float = float(
        os.getenv("BIOMETRIC_LIVENESS_THRESHOLD", "0.60")
    )
    biometric_match_threshold: float = float(
        os.getenv("BIOMETRIC_MATCH_THRESHOLD", "0.85")
    )
    facial_verification_secret: str = os.getenv(
        "FACIAL_VERIFICATION_SECRET", DEFAULT_FACIAL_VERIFICATION_SECRET
    )
    facial_verification_ttl_seconds: int = int(
        os.getenv("FACIAL_VERIFICATION_TTL_SECONDS", "90")
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
    image_download_timeout_seconds: int = int(
        os.getenv("IMAGE_DOWNLOAD_TIMEOUT_SECONDS", "10")
    )
    image_download_max_bytes: int = int(
        os.getenv("IMAGE_DOWNLOAD_MAX_BYTES", "10485760")
    )

    # Autenticacao mútua FaceClock <-> ERP/terminais via HMAC.
    # As credenciais sao armazenadas na base de dados (ApiCredential) e a chave
    # secreta e cifrada em repouso com uma chave mestra externa.
    nexora_credential_encryption_key: str = os.getenv(
        "NEXORA_CREDENTIAL_ENCRYPTION_KEY", DEFAULT_NEXORA_CREDENTIAL_ENCRYPTION_KEY
    )
    nexora_signature_ttl_seconds: int = int(os.getenv("NEXORA_SIGNATURE_TTL_SECONDS", "300"))
    nexora_auth_version: str = os.getenv("NEXORA_AUTH_VERSION", "NEXORA-HMAC-SHA256-V1")
    nexora_hmac_require_https: bool = os.getenv(
        "NEXORA_HMAC_REQUIRE_HTTPS", "true"
    ).lower() == "true"
    redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    nexora_rate_limit_per_key: str = os.getenv("NEXORA_RATE_LIMIT_PER_KEY", "100/minute")

    @property
    def biometric_encryption_key(self) -> bytes:
        """Chave para criptografia em repouso de templates biométricos."""
        key = os.getenv("BIOMETRIC_ENCRYPTION_KEY", DEFAULT_BIOMETRIC_ENCRYPTION_KEY)
        return key.encode("utf-8")

    def assert_production_secrets(self) -> None:
        """Falha alto (em vez de degradar em silencio) se ENVIRONMENT=production
        estiver a correr com segredos por omissao/ausentes."""
        if self.environment != "production":
            return
        if os.getenv("BIOMETRIC_ENCRYPTION_KEY", DEFAULT_BIOMETRIC_ENCRYPTION_KEY) == DEFAULT_BIOMETRIC_ENCRYPTION_KEY:
            raise RuntimeError(
                "BIOMETRIC_ENCRYPTION_KEY nao configurado (ou igual ao default versionado) "
                "com ENVIRONMENT=production. Defina uma chave forte e unica de 32 bytes "
                "antes de arrancar."
            )
        if self.facial_verification_secret == DEFAULT_FACIAL_VERIFICATION_SECRET:
            raise RuntimeError(
                "FACIAL_VERIFICATION_SECRET nao configurado (ou igual ao default versionado) "
                "com ENVIRONMENT=production. Use o mesmo segredo forte configurado no Nexora ERP."
            )
        if os.getenv("NEXORA_CREDENTIAL_ENCRYPTION_KEY", DEFAULT_NEXORA_CREDENTIAL_ENCRYPTION_KEY) == DEFAULT_NEXORA_CREDENTIAL_ENCRYPTION_KEY:
            raise RuntimeError(
                "NEXORA_CREDENTIAL_ENCRYPTION_KEY nao configurado (ou igual ao default versionado) "
                "com ENVIRONMENT=production. Defina uma chave forte e unica para cifrar "
                "as credenciais Nexora em repouso antes de arrancar."
            )


settings = Settings()
