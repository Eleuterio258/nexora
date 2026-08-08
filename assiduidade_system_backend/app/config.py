import os

from dotenv import load_dotenv

load_dotenv()


# Defaults inseguros para segredos que DEVEM ser sobrescritos em ambiente real.
# O default de BIOMETRIC_ENCRYPTION_KEY foi removido: a ausência desta variável
# levanta erro imediato, evitando templates cifrados com chave previsível.
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
    biometric_model: str = os.getenv("BIOMETRIC_MODEL", "facenet")
    liveness_model: str = os.getenv("LIVENESS_MODEL", "heuristic")
    biometric_key_provider: str = "environment"
    biometric_max_pitch: float = float(os.getenv("BIOMETRIC_MAX_PITCH", "20.0"))
    biometric_max_roll: float = float(os.getenv("BIOMETRIC_MAX_ROLL", "15.0"))
    biometric_max_yaw: float = float(os.getenv("BIOMETRIC_MAX_YAW", "25.0"))
    liveness_challenge_store: str = os.getenv("LIVENESS_CHALLENGE_STORE", "memory")
    suspicious_activity_threshold: int = int(os.getenv("SUSPICIOUS_ACTIVITY_THRESHOLD", "5"))
    suspicious_activity_window_seconds: int = int(
        os.getenv("SUSPICIOUS_ACTIVITY_WINDOW_SECONDS", "600")
    )
    require_image_signature: bool = os.getenv("REQUIRE_IMAGE_SIGNATURE", "false").lower() in (
        "1",
        "true",
        "yes",
    )
    fingerprint_match_threshold: float = float(os.getenv("FINGERPRINT_MATCH_THRESHOLD", "0.25"))
    cancelable_transform_secret: str | None = os.getenv("CANCELABLE_TRANSFORM_SECRET")
    cancelable_transform_version: str = os.getenv("CANCELABLE_TRANSFORM_VERSION", "v1")
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
    erp_reenroll_webhook_url: str = os.getenv("ERP_REENROLL_WEBHOOK_URL", "")
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
    def biometric_encryption_key(self) -> bytes | None:
        """Chave unica para criptografia em repouso de templates biométricos.

        Pode ser None se BIOMETRIC_ENCRYPTION_KEYS (keyring JSON) estiver
        configurado. A origem da chave depende do BIOMETRIC_KEY_PROVIDER.
        """
        from app.security.key_management import get_key_provider

        try:
            return get_key_provider().get_key()
        except RuntimeError:
            return None

    @property
    def biometric_encryption_keys(self) -> str | None:
        """Keyring JSON para suporte a rotação de chaves.

        Exemplo: {"v1": "base64...", "v2": "base64...", "active": "v2"}
        """
        return os.getenv("BIOMETRIC_ENCRYPTION_KEYS")

    def assert_production_secrets(self) -> None:
        """Falha alto (em vez de degradar em silencio) se ENVIRONMENT=production
        estiver a correr com segredos por omissao/ausentes."""
        if self.environment != "production":
            return
        if not self.biometric_encryption_keys and not self.biometric_encryption_key:
            raise RuntimeError(
                "BIOMETRIC_ENCRYPTION_KEY/BIOMETRIC_ENCRYPTION_KEYS nao configurada "
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

    @property
    def biometric_face_detector(self) -> str:
        return os.getenv("BIOMETRIC_FACE_DETECTOR", "blaze_face").lower()


settings = Settings()
