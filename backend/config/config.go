package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	// Ambiente de execução ("development" por omissão). Só um valor
	// explícito "production" activa AssertProductionSecrets().
	Environment string

	// Base de dados
	DatabaseURL string

	// JWT — partilhado por todos os módulos
	JWTSecret           string
	JWTRefreshSecret    string
	JWTExpiresIn        time.Duration
	JWTRefreshExpiresIn time.Duration

	// Servidor
	Port       string
	CORSOrigin string

	// RunBackgroundJobs controla se este processo corre os jobs recorrentes
	// (background.StartJobs — dispatch de notificações, reminders, etc.).
	// Default true preserva o comportamento anterior à Fase 2 (jobs dentro
	// do processo da API). Um operador que separe o dispatcher para
	// cmd/worker deve pôr RUN_BACKGROUND_JOBS=false na API, para não correrem
	// dois dispatchers em simultâneo — a reserva atómica em
	// internal/background/jobs.go torna isso seguro mesmo que aconteça, mas
	// desperdiça trabalho.
	RunBackgroundJobs bool

	// Ficheiros locais
	AvatarDir  string
	UploadsDir string

	// Multi-tenant — domínio base da plataforma. Um pedido a
	// <codigo>.<PlatformBaseDomain> resolve para o tenant com esse código.
	PlatformBaseDomain string

	// ID obfuscation — same salt must be set in PHP frontend (JWT_SECRET is reused)
	IDHashSalt string

	// Pagamentos — webhook do gateway
	GatewayWebhookSecret string

	// Firebase Admin SDK — notificações push (FCM)
	FirebaseCredentialsFile string

	// Nexora-Pay — gateway de pagamento (M-Pesa, eMola, mKesh)
	NexoraPayBaseURL        string
	NexoraPayAPIKey         string
	NexoraPayPublicKey      string
	NexoraPayServiceAccount string

	// Email transaccional — API nativa do AWS SES; credenciais AWS pela
	// cadeia standard do SDK (env vars/role IAM), não configuradas aqui.
	SESRegion   string
	SESFrom     string
	SESFromName string

	// Object Storage (local ou minio)
	StorageProvider   string
	StorageLocalDir   string
	StoragePublicURL  string
	MinioEndpoint     string
	MinioAccessKey    string
	MinioSecretKey    string
	MinioBucket       string
	MinioUseSSL       bool
	MinioRegion       string
	MinioBucketLookup string // auto | dns | path

	// Recuperação de senha — página do frontend que lê ?token= e chama
	// POST /api/auth/reset-password (opcional; sem link clicável se vazio).
	PasswordResetBaseURL string

	// SMS — envio de notificações por SMS (opcional; "noop" ou vazio desativa).
	SMSProvider    string
	SMSTwilioSID   string
	SMSTwilioToken string
	SMSTwilioFrom  string

	// Authorization Server OAuth2 — chave(s) RS256 que assinam os access
	// tokens emitidos por /oauth/token. Ver internal/modules/auth/oauthkeys.
	// Por omissão o servidor RECUSA arrancar sem uma chave válida já
	// presente em OAuthSigningKeysDir, a menos que OAuthAllowGeneratedKey
	// reconheça explicitamente o uso de uma chave gerada.
	OAuthSigningKeysDir    string
	OAuthAllowGeneratedKey bool
	OAuthIssuer            string
	OAuthAudience          string
}

// defaultJWTSecret, defaultJWTRefreshSecret, defaultMinioAccessKey e
// defaultMinioSecretKey são os mesmos valores por omissão usados em Load() —
// mantidos como constantes para AssertProductionSecrets() os comparar sem
// depender de duplicar as strings.
const (
	defaultJWTSecret        = "change-me-secret"
	defaultJWTRefreshSecret = "change-me-refresh-secret"
	defaultMinioAccessKey   = "histories"
	defaultMinioSecretKey   = "histories"
)

// AssertProductionSecrets falha o arranque (log.Fatal, chamado pelo caller)
// se Environment=="production" e algum segredo crítico ainda tiver o valor
// por omissão versionado no repositório: um JWT_SECRET
// por omissão esquecido permite forjar tokens válidos para qualquer
// utilizador/tenant. Sem ENVIRONMENT=production explícito, o comportamento
// por omissão mantém-se inalterado (dev/staging não são afectados).
func (c *Config) AssertProductionSecrets() error {
	if c.Environment != "production" {
		return nil
	}
	var bad []string
	if c.JWTSecret == "" || c.JWTSecret == defaultJWTSecret {
		bad = append(bad, "JWT_SECRET")
	}
	if c.JWTRefreshSecret == "" || c.JWTRefreshSecret == defaultJWTRefreshSecret {
		bad = append(bad, "JWT_REFRESH_SECRET")
	}
	if c.MinioAccessKey == defaultMinioAccessKey {
		bad = append(bad, "MINIO_ACCESS_KEY")
	}
	if c.MinioSecretKey == defaultMinioSecretKey {
		bad = append(bad, "MINIO_SECRET_KEY")
	}
	if len(bad) > 0 {
		return fmt.Errorf("ENVIRONMENT=production exige segredos reais para: %s (valores por omissão do repositório não são seguros)", strings.Join(bad, ", "))
	}
	return nil
}

func Load() *Config {
	return &Config{
		DatabaseURL: env("DATABASE_URL",
			"postgres://postgres:Plane@mento1@209.126.86.55:5432/nexora_erp?sslmode=disable"+
				"&options=-csearch_path%3D"+
				"auth%2Cutilizadores%2Cempresas%2Cauditoria%2C"+
				"sistema_configuracao%2Cclientes%2Cprodutos%2Cstock%2Cfaturacao%2C"+
				"recrutamento%2Ccrm%2Cpos%2C"+
				"rh%2C"+
				"contabilidade%2Ccentros_custo%2Ccompras%2C"+
				"financeiro%2Ctesouraria%2Clogistica%2C"+
				"impostos%2Cmulti_moeda%2C"+
				"assinaturas%2Cnotifications%2Cseguranca%2C"+
				"gestao_escolar%2Cpublic"),
		Environment:         env("ENVIRONMENT", "development"),
		JWTSecret:           env("JWT_SECRET", defaultJWTSecret),
		JWTRefreshSecret:    env("JWT_REFRESH_SECRET", defaultJWTRefreshSecret),
		JWTExpiresIn:        parseDuration(env("JWT_EXPIRES_IN", "15m")),
		JWTRefreshExpiresIn: parseDuration(env("JWT_REFRESH_EXPIRES_IN", "7d")),
		Port:                env("PORT", "8080"),
		CORSOrigin:          env("CORS_ORIGIN", "*"),
		RunBackgroundJobs:   envBool("RUN_BACKGROUND_JOBS", true),
		AvatarDir:           env("AVATAR_DIR", "./avatars"),

		UploadsDir:              env("UPLOADS_DIR", "./uploads"),
		PlatformBaseDomain:      strings.ToLower(strings.TrimSpace(env("PLATFORM_BASE_DOMAIN", ""))),
		IDHashSalt:              env("JWT_SECRET", "change-me-secret"),
		GatewayWebhookSecret:    env("GATEWAY_WEBHOOK_SECRET", ""),
		FirebaseCredentialsFile: env("FIREBASE_CREDENTIALS_FILE", "./config/e258tech-d439e.json"),
		NexoraPayBaseURL:        env("NEXORA_PAY_BASE_URL", "http://nexora-backend:3000"),
		NexoraPayAPIKey:         env("NEXORA_PAY_API_KEY", ""),
		NexoraPayPublicKey:      env("NEXORA_PAY_PUBLIC_KEY", ""),
		NexoraPayServiceAccount: env("NEXORA_PAY_SERVICE_ACCOUNT", "gestao-escolar"),

		SESRegion:   env("SES_REGION", "us-east-1"),
		SESFrom:     env("SES_FROM", ""),
		SESFromName: env("SES_FROM_NAME", "Nexora ERP"),

		StorageProvider:   env("STORAGE_PROVIDER", "minio"),
		StorageLocalDir:   env("STORAGE_LOCAL_DIR", "./uploads"),
		StoragePublicURL:  env("STORAGE_PUBLIC_URL", ""),
		MinioEndpoint:     env("MINIO_ENDPOINT", "localhost:9004"),
		MinioAccessKey:    env("MINIO_ACCESS_KEY", defaultMinioAccessKey),
		MinioSecretKey:    env("MINIO_SECRET_KEY", defaultMinioSecretKey),
		MinioBucket:       env("MINIO_BUCKET", "nexora"),
		MinioUseSSL:       envBool("MINIO_USE_SSL", false),
		MinioRegion:       env("MINIO_REGION", "us-east-1"),
		MinioBucketLookup: env("MINIO_BUCKET_LOOKUP", "auto"),

		PasswordResetBaseURL: env("PASSWORD_RESET_BASE_URL", ""),

		SMSProvider:    env("SMS_PROVIDER", "noop"),
		SMSTwilioSID:   env("SMS_TWILIO_SID", ""),
		SMSTwilioToken: env("SMS_TWILIO_TOKEN", ""),
		SMSTwilioFrom:  env("SMS_TWILIO_FROM", ""),

		OAuthSigningKeysDir:    env("OAUTH_SIGNING_KEYS_DIR", "./data/oauth-keys"),
		OAuthAllowGeneratedKey: envBool("OAUTH_ALLOW_GENERATED_KEY", false),
		OAuthIssuer:            env("OAUTH_ISSUER", "nexora-erp"),
		OAuthAudience:          env("OAUTH_AUDIENCE", "nexora-api"),
	}
}

func envBool(key string, fallback bool) bool {
	if v := os.Getenv(key); v != "" {
		if b, err := strconv.ParseBool(v); err == nil {
			return b
		}
	}
	return fallback
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func parseDuration(s string) time.Duration {
	if len(s) >= 2 && s[len(s)-1] == 'd' {
		n, _ := strconv.Atoi(s[:len(s)-1])
		return time.Duration(n) * 24 * time.Hour
	}
	d, _ := time.ParseDuration(s)
	if d == 0 {
		return 15 * time.Minute
	}
	return d
}
