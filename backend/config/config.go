package config

import (
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
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

	// Avatar
	AvatarMaxMB int64
	AvatarDir   string

	// Recrutamento
	RecruitmentTenantID int64
	UploadsDir          string
	UploadMaxMB         int64

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
	NexoraPayServiceAccount string

	// SMTP — envio de emails transaccionais
	SMTPHost     string
	SMTPPort     int
	SMTPUser     string
	SMTPPassword string
	SMTPFrom     string
	SMTPFromName string

	// Object Storage (local ou minio)
	StorageProvider  string
	StorageLocalDir  string
	StoragePublicURL string
	MinioEndpoint    string
	MinioAccessKey   string
	MinioSecretKey   string
	MinioBucket      string
	MinioUseSSL      bool
	MinioRegion      string

	// Hardware — worker MQTT (opcional; desligado se MQTTBrokerURL vazio)
	MQTTBrokerURL string
	MQTTClientID  string
	MQTTUsername  string
	MQTTPassword  string

	// Assinatura digital — convite de assinatura (opcional; sem link clicável se vazio)
	SignatureInviteBaseURL string

	// Assinatura digital — provider PKI/PAdES. "dev" gera um certificado
	// auto-assinado local; NUNCA é juridicamente válido. Um provider real
	// (ex. INTIC) substituiria este valor quando existirem credenciais.
	SignatureProvider   string
	SignatureDevKeyPath string
	SignatureTSAURL     string

	// Assinatura digital — segredo HMAC do webhook (esqueleto, sem lógica de
	// negócio ainda; vazio desliga o endpoint com 501).
	SignatureWebhookSecret string

	// SMS — envio de notificações por SMS (opcional; "noop" ou vazio desativa).
	SMSProvider   string
	SMSTwilioSID  string
	SMSTwilioToken string
	SMSTwilioFrom string

	// Antivírus — verificação de ficheiros no upload (opcional).
	AntivirusProvider      string
	AntivirusClamAVNetwork string
	AntivirusClamAVAddress string

	// Provider de assinatura real (INTIC stub).
	SignatureINTICKeyPath       string
	SignatureCARootsPEM         string
	SignatureCAIntermediatesPEM string
}

func Load() *Config {
	return &Config{
		DatabaseURL: env("DATABASE_URL",
			"postgres://postgres:admin@localhost:5432/nexora_erp?sslmode=disable"+
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
		JWTSecret:           env("JWT_SECRET", "change-me-secret"),
		JWTRefreshSecret:    env("JWT_REFRESH_SECRET", "change-me-refresh-secret"),
		JWTExpiresIn:        parseDuration(env("JWT_EXPIRES_IN", "15m")),
		JWTRefreshExpiresIn: parseDuration(env("JWT_REFRESH_EXPIRES_IN", "7d")),
		Port:                env("PORT", "8080"),
		CORSOrigin:          env("CORS_ORIGIN", "*"),
		AvatarMaxMB:         envInt("AVATAR_MAX_MB", 2),
		AvatarDir:           env("AVATAR_DIR", "./avatars"),

		RecruitmentTenantID:     envInt("RECRUITMENT_TENANT_ID", 1),
		UploadsDir:              env("UPLOADS_DIR", "./uploads"),
		UploadMaxMB:             envInt("UPLOAD_MAX_MB", 3),
		PlatformBaseDomain:      strings.ToLower(strings.TrimSpace(env("PLATFORM_BASE_DOMAIN", ""))),
		IDHashSalt:              env("JWT_SECRET", "change-me-secret"),
		GatewayWebhookSecret:    env("GATEWAY_WEBHOOK_SECRET", ""),
		FirebaseCredentialsFile: env("FIREBASE_CREDENTIALS_FILE", "./config/e258tech-d439e.json"),
		NexoraPayBaseURL:        env("NEXORA_PAY_BASE_URL", "http://nexora-pay:3000"),
		NexoraPayAPIKey:         env("NEXORA_PAY_API_KEY", ""),
		NexoraPayServiceAccount: env("NEXORA_PAY_SERVICE_ACCOUNT", "gestao-escolar"),

		SMTPHost:     env("SMTP_HOST", ""),
		SMTPPort:     int(envInt("SMTP_PORT", 587)),
		SMTPUser:     env("SMTP_USER", ""),
		SMTPPassword: env("SMTP_PASSWORD", ""),
		SMTPFrom:     env("SMTP_FROM", ""),
		SMTPFromName: env("SMTP_FROM_NAME", "Nexora ERP"),

		StorageProvider:  env("STORAGE_PROVIDER", "minio"),
		StorageLocalDir:  env("STORAGE_LOCAL_DIR", "./uploads"),
		StoragePublicURL: env("STORAGE_PUBLIC_URL", ""),
		MinioEndpoint:    env("MINIO_ENDPOINT", "localhost:9004"),
		MinioAccessKey:   env("MINIO_ACCESS_KEY", "histories"),
		MinioSecretKey:   env("MINIO_SECRET_KEY", "histories"),
		MinioBucket:      env("MINIO_BUCKET", "nexora"),
		MinioUseSSL:      envBool("MINIO_USE_SSL", false),
		MinioRegion:      env("MINIO_REGION", "us-east-1"),

		MQTTBrokerURL: env("MQTT_BROKER_URL", ""),
		MQTTClientID:  env("MQTT_CLIENT_ID", "nexora-hardware-worker"),
		MQTTUsername:  env("MQTT_USERNAME", ""),
		MQTTPassword:  env("MQTT_PASSWORD", ""),

		SignatureInviteBaseURL: env("SIGNATURE_INVITE_BASE_URL", ""),

		SignatureProvider:   env("SIGNATURE_PROVIDER", "dev"),
		SignatureDevKeyPath: env("SIGNATURE_DEV_KEY_PATH", "./data/assinatura-dev.pem"),
		SignatureTSAURL:     env("SIGNATURE_TSA_URL", ""),

		SignatureWebhookSecret: env("SIGNATURE_WEBHOOK_SECRET", ""),

		SMSProvider:    env("SMS_PROVIDER", "noop"),
		SMSTwilioSID:   env("SMS_TWILIO_SID", ""),
		SMSTwilioToken: env("SMS_TWILIO_TOKEN", ""),
		SMSTwilioFrom:  env("SMS_TWILIO_FROM", ""),

		AntivirusProvider:      env("ANTIVIRUS_PROVIDER", "noop"),
		AntivirusClamAVNetwork: env("ANTIVIRUS_CLAMAV_NETWORK", "tcp"),
		AntivirusClamAVAddress: env("ANTIVIRUS_CLAMAV_ADDRESS", "localhost:3310"),

		SignatureINTICKeyPath:       env("SIGNATURE_INTIC_KEY_PATH", ""),
		SignatureCARootsPEM:         env("SIGNATURE_CA_ROOTS_PEM", ""),
		SignatureCAIntermediatesPEM: env("SIGNATURE_CA_INTERMEDIATES_PEM", ""),
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

func envInt(key string, fallback int64) int64 {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.ParseInt(v, 10, 64); err == nil {
			return n
		}
	}
	return fallback
}
