import os

from dotenv import load_dotenv

load_dotenv()


DEFAULT_JWT_SECRET_KEY = "change-me-in-production"


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
    # Segredo partilhado entre o gateway/ERP e o FaceClock: exigido em qualquer
    # pedido que traga X-Auth-User-Id (headers de identidade de confianca), para
    # que um chamador com mero acesso de rede nao se consiga fazer passar por
    # outro utilizador/tenant. Vazio = confiar nos headers sem verificacao
    # (aceitavel so em dev local; bloqueado em producao por assert_production_secrets).
    gateway_shared_secret: str = os.getenv("GATEWAY_SHARED_SECRET", "")

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


settings = Settings()
