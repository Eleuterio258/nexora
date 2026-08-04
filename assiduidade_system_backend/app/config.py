import os

from dotenv import load_dotenv

load_dotenv()


DEFAULT_JWT_SECRET_KEY = "change-me-in-production"
DEFAULT_BIOMETRIC_ENCRYPTION_KEY = "change-me-in-production-biometric-key-32bytes"
DEFAULT_FACIAL_VERIFICATION_SECRET = "change-me-facial-verification-secret"
DEFAULT_NEXORA_CREDENTIAL_ENCRYPTION_KEY = "change-me-nexora-credential-encryption-key"


class Settings:
    app_name: str = os.getenv("APP_NAME", "FaceClock API")
    app_version: str = os.getenv("APP_VERSION", "1.0.0")
    environment: str = os.getenv("ENVIRONMENT", "development")
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
    # JWKS do Authorization Server do Nexora ERP — usado para verificar
    # localmente (sem round-trip) os access tokens RS256 emitidos por
    # /oauth/token. erp_token_audience tem de bater com a claim "aud" que o
    # ERP emite (OAUTH_AUDIENCE no backend Go, default "nexora-api").
    erp_token_audience: str = os.getenv("ERP_TOKEN_AUDIENCE", "nexora-api")
    image_download_timeout_seconds: int = int(
        os.getenv("IMAGE_DOWNLOAD_TIMEOUT_SECONDS", "10")
    )
    image_download_max_bytes: int = int(
        os.getenv("IMAGE_DOWNLOAD_MAX_BYTES", "10485760")
    )

    @property
    def erp_jwks_url(self) -> str:
        override = os.getenv("ERP_JWKS_URL", "")
        if override:
            return override
        return f"{self.erp_base_url.rstrip('/')}/oauth/jwks" if self.erp_base_url else ""
    erp_fallback_local_login: bool = os.getenv(
        "ERP_FALLBACK_LOCAL_LOGIN", "true"
    ).lower() == "true"
    # Segredo partilhado entre o gateway/ERP e o FaceClock: exigido em qualquer
    # pedido que traga X-Auth-User-Id (headers de identidade de confianca), para
    # que um chamador com mero acesso de rede nao se consiga fazer passar por
    # outro utilizador/tenant. Vazio = confiar nos headers sem verificacao
    # (aceitavel so em dev local; bloqueado em producao por assert_production_secrets).
    gateway_shared_secret: str = os.getenv("GATEWAY_SHARED_SECRET", "")
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

    @property
    def jwt_secret_key(self) -> str:
        """Retorna a chave JWT garantindo tamanho minimo de 32 bytes."""
        key = os.getenv("JWT_SECRET_KEY", DEFAULT_JWT_SECRET_KEY)
        if len(key.encode("utf-8")) < 32:
            key = (key * ((32 // len(key)) + 1))[:32]
        return key

    @property
    def local_login_fallback_enabled(self) -> bool:
        """Login local (password directa na BD do FaceClock) so e permitido
        fora de producao. Em producao, a identidade tem de vir sempre do ERP."""
        if self.environment == "production":
            return False
        return self.erp_fallback_local_login

    def assert_production_secrets(self) -> None:
        """Falha alto (em vez de degradar em silencio) se ENVIRONMENT=production
        estiver a correr com segredos por omissao/ausentes."""
        if self.environment != "production":
            return
        if os.getenv("JWT_SECRET_KEY", DEFAULT_JWT_SECRET_KEY) == DEFAULT_JWT_SECRET_KEY:
            raise RuntimeError(
                "JWT_SECRET_KEY nao configurado (ou igual ao default versionado) "
                "com ENVIRONMENT=production. Defina um segredo forte e unico antes de arrancar."
            )
        if not self.gateway_shared_secret:
            raise RuntimeError(
                "GATEWAY_SHARED_SECRET nao configurado com ENVIRONMENT=production. "
                "Sem ele, qualquer chamador com acesso de rede pode forjar-se como "
                "outro utilizador via headers X-Auth-*. Defina o segredo partilhado "
                "com o gateway/ERP antes de arrancar."
            )
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
