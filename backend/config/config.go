package config

import (
	"os"
	"strconv"
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
}

func Load() *Config {
	return &Config{
		DatabaseURL: env("DATABASE_URL",
			"postgres://postgres:admin@localhost:5432/nexora_erp?sslmode=disable"+
				"&options=-csearch_path%3D"+
				"auth%2Cutilizadores%2Cempresas%2Cempresa%2Cautorizacao%2Cauditoria%2C"+
				"sistema_configuracao%2Cclientes%2Cprodutos%2Cstock%2Cfaturacao%2C"+
				"recrutamento%2Ccrm%2Cpos%2C"+
				"rh%2Crecursos_humanos%2C"+
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

		RecruitmentTenantID: envInt("RECRUITMENT_TENANT_ID", 1),
		UploadsDir:          env("UPLOADS_DIR", "./uploads"),
		UploadMaxMB:         envInt("UPLOAD_MAX_MB", 3),
	}
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
