package assiduidade

import (
	"context"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/pashagolub/pgxmock/v4"

	"nexora/internal/modules/recursos-humanos/models"
)

func eventoRowColumns() []string {
	return []string{
		"id", "tenant_id", "funcionario_id", "tipo_evento_id", "metodo_id",
		"ocorrido_em", "data_referencia", "origem", "dispositivo_id", "qr_token_id", "nfc_tag_id",
		"latitude", "longitude", "localidade_id", "dentro_geofence",
		"foto_url", "documento_url", "estado", "registado_por", "motivo", "observacoes",
		"evento_pai_id", "duplicado_de_id", "ip_origem", "user_agent", "hash_digital",
		"created_at", "updated_at",
	}
}

// RegistarEvento com um tipo de evento inexistente para o tenant deve falhar
// sem chegar a tentar gravar nada.
func TestRegistarEvento_TipoDesconhecido(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)

	mock.ExpectQuery("SELECT id FROM rh.tipos_evento").
		WithArgs(int64(1), "codigo_inexistente").
		WillReturnError(pgx.ErrNoRows)

	_, err = svc.RegistarEvento(context.Background(), 1, RegistarEventoInput{
		FuncionarioID:    10,
		TipoEventoCodigo: "codigo_inexistente",
		OcorridoEm:       time.Now(),
		Origem:           "manual",
	})
	if err != ErrTipoEventoDesconhecido {
		t.Fatalf("err = %v, want ErrTipoEventoDesconhecido", err)
	}
}

// Um segundo pedido com o mesmo hash (mesmo funcionário/tipo/origem/instante)
// devolve o evento já gravado em vez de duplicar a linha — idempotência ao
// nível do serviço, complementar à deduplicação de hardware.device_events.
func TestRegistarEvento_DedupPorHash(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)
	ocorridoEm := time.Date(2026, 7, 20, 7, 55, 0, 0, time.UTC)

	mock.ExpectQuery("SELECT id FROM rh.tipos_evento").
		WithArgs(int64(1), "entrada").
		WillReturnRows(pgxmock.NewRows([]string{"id"}).AddRow(int64(100)))

	expectedHash := hashEventoAssiduidade(1, 10, 100, "manual", nil, ocorridoEm)
	mock.ExpectQuery("SELECT id, tenant_id, funcionario_id").
		WithArgs(int64(1), expectedHash).
		WillReturnRows(pgxmock.NewRows(eventoRowColumns()).
			AddRow(
				int64(555), int64(1), int64(10), int64(100), (*int64)(nil),
				ocorridoEm, ocorridoEm, "manual", (*int64)(nil), (*int64)(nil), (*int64)(nil),
				(*float64)(nil), (*float64)(nil), (*int64)(nil), (*bool)(nil),
				(*string)(nil), (*string)(nil), "valido", (*int64)(nil), (*string)(nil), (*string)(nil),
				(*int64)(nil), (*int64)(nil), (*string)(nil), (*string)(nil), models.StringPtr("hash-existente"),
				ocorridoEm, ocorridoEm,
			))

	ev, err := svc.RegistarEvento(context.Background(), 1, RegistarEventoInput{
		FuncionarioID:    10,
		TipoEventoCodigo: "entrada",
		OcorridoEm:       ocorridoEm,
		Origem:           "manual",
	})
	if err != nil {
		t.Fatalf("RegistarEvento error: %v", err)
	}
	if ev.ID != 555 {
		t.Fatalf("ID = %d, want 555 (evento existente devolvido em vez de duplicado)", ev.ID)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// Uma correcção aprovada (correcoes_evento.go) grava o evento gerado já com
// EstadoForcado="corrigido" em vez do "valido"/"fora_localizacao" normais —
// confirma que o INSERT recebe esse estado tal como pedido pelo chamador.
func TestRegistarEvento_EstadoForcadoParaCorrecao(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)
	ocorridoEm := time.Date(2026, 7, 20, 7, 55, 0, 0, time.UTC)

	mock.ExpectQuery("SELECT id FROM rh.tipos_evento").
		WithArgs(int64(1), "entrada").
		WillReturnRows(pgxmock.NewRows([]string{"id"}).AddRow(int64(100)))

	expectedHash := hashEventoAssiduidade(1, 10, 100, "manual", nil, ocorridoEm)
	mock.ExpectQuery("SELECT id, tenant_id, funcionario_id").
		WithArgs(int64(1), expectedHash).
		WillReturnError(pgx.ErrNoRows)

	anyArgs := make([]any, 24)
	for i := range anyArgs {
		anyArgs[i] = pgxmock.AnyArg()
	}
	mock.ExpectQuery("INSERT INTO rh.eventos_assiduidade").
		WithArgs(anyArgs...).
		WillReturnRows(pgxmock.NewRows(eventoRowColumns()).
			AddRow(
				int64(700), int64(1), int64(10), int64(100), (*int64)(nil),
				ocorridoEm, ocorridoEm, "manual", (*int64)(nil), (*int64)(nil), (*int64)(nil),
				(*float64)(nil), (*float64)(nil), (*int64)(nil), (*bool)(nil),
				(*string)(nil), (*string)(nil), "corrigido", (*int64)(nil), (*string)(nil), (*string)(nil),
				(*int64)(nil), (*int64)(nil), (*string)(nil), (*string)(nil), models.StringPtr("hash-novo"),
				ocorridoEm, ocorridoEm,
			))
	auditArgs := make([]any, 14)
	for i := range auditArgs {
		auditArgs[i] = pgxmock.AnyArg()
	}
	mock.ExpectExec("INSERT INTO rh.auditoria_assiduidade").
		WithArgs(auditArgs...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	estadoCorrigido := "corrigido"
	ev, err := svc.RegistarEvento(context.Background(), 1, RegistarEventoInput{
		FuncionarioID:    10,
		TipoEventoCodigo: "entrada",
		OcorridoEm:       ocorridoEm,
		Origem:           "manual",
		EstadoForcado:    &estadoCorrigido,
	})
	if err != nil {
		t.Fatalf("RegistarEvento error: %v", err)
	}
	if ev.Estado != "corrigido" {
		t.Fatalf("Estado = %q, want %q", ev.Estado, "corrigido")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}
