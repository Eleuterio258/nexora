package handlers

import (
	"strings"
	"testing"
	"time"
)

func TestValidarMarcacaoOffline(t *testing.T) {
	agora := time.Date(2026, 9, 26, 12, 0, 0, 0, time.UTC)
	base := MarcacaoOffline{
		IdempotencyKey: "a0c1f7e2-6b1d-4f6e-9a55-2d0b7b1f0c11",
		Metodo:         "pin",
		PIN:            "1234",
		OcorridoEm:     agora.Add(-2 * time.Hour).Format(time.RFC3339),
	}

	casos := []struct {
		nome    string
		mudar   func(m *MarcacaoOffline)
		erroCom string // "" = deve ser aceite
	}{
		{"pin valido", func(m *MarcacaoOffline) {}, ""},
		{"fingerprint sem pin", func(m *MarcacaoOffline) { m.Metodo = "fingerprint"; m.PIN = "" }, ""},
		{"no limite das 72h", func(m *MarcacaoOffline) { m.OcorridoEm = agora.Add(-72 * time.Hour).Format(time.RFC3339) }, ""},
		{"folga de relogio adiantado", func(m *MarcacaoOffline) { m.OcorridoEm = agora.Add(4 * time.Minute).Format(time.RFC3339) }, ""},
		{"mais de 72h", func(m *MarcacaoOffline) { m.OcorridoEm = agora.Add(-73 * time.Hour).Format(time.RFC3339) }, "72 horas"},
		{"no futuro", func(m *MarcacaoOffline) { m.OcorridoEm = agora.Add(10 * time.Minute).Format(time.RFC3339) }, "futuro"},
		{"data invalida", func(m *MarcacaoOffline) { m.OcorridoEm = "26/09/2026 10:00" }, "RFC 3339"},
		{"sem chave", func(m *MarcacaoOffline) { m.IdempotencyKey = "  " }, "idempotency_key"},
		{"chave longa", func(m *MarcacaoOffline) { m.IdempotencyKey = strings.Repeat("x", 129) }, "idempotency_key"},
		{"pin em falta", func(m *MarcacaoOffline) { m.PIN = "" }, "pin"},
		{"facial nao sincroniza offline", func(m *MarcacaoOffline) { m.Metodo = "facial" }, "com rede"},
		{"qr nao sincroniza offline", func(m *MarcacaoOffline) { m.Metodo = "qr_code" }, "com rede"},
		{"metodo desconhecido", func(m *MarcacaoOffline) { m.Metodo = "telepatia" }, "não suportado"},
		{"tipo de ausencia recusado", func(m *MarcacaoOffline) { m.TipoEventoCodigo = "ferias" }, "tipo_evento_codigo"},
	}

	for _, c := range casos {
		t.Run(c.nome, func(t *testing.T) {
			m := base
			c.mudar(&m)
			v, err := validarMarcacaoOffline(m, agora)
			if c.erroCom == "" {
				if err != nil {
					t.Fatalf("esperava aceitar, obteve %v", err)
				}
				if v.cfg.Codigo == "" {
					t.Fatalf("metodo nao resolvido: %+v", v)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), c.erroCom) {
				t.Fatalf("esperava erro com %q, obteve %v", c.erroCom, err)
			}
		})
	}
}

func TestObservacoesOfflineAssinalaOrigem(t *testing.T) {
	ocorrido := time.Date(2026, 9, 25, 8, 1, 0, 0, time.UTC)
	sync := time.Date(2026, 9, 26, 9, 30, 0, 0, time.UTC)
	v := marcacaoValidada{item: MarcacaoOffline{DeviceID: "dev-7"}, ocorridoEm: ocorrido}

	got := observacoesOffline(v, sync)
	for _, esperado := range []string{"offline", "registado_no_dispositivo=2026-09-25T08:01:00Z", "sincronizado_em=2026-09-26T09:30:00Z", "device_id=dev-7"} {
		if !strings.Contains(got, esperado) {
			t.Fatalf("observacoes sem %q: %s", esperado, got)
		}
	}
}
