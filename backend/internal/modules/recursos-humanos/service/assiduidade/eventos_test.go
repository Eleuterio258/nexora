package assiduidade

import (
	"context"
	"errors"
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

// Um método explicitamente desactivado na configuração do tenant é recusado —
// é o que dá efeito real ao ecrã de configuração de assiduidade sobre os
// métodos que não passam pelo FaceClock (PIN, QR, NFC, manual...).
func TestMetodoActivo_Desactivado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)

	mock.ExpectQuery("FROM saas.feature_catalog").
		WithArgs(int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"activo", "configuracao"}).
			AddRow(true, []byte(`{"metodos":{"pin":{"ativo":false},"qr_code":{"ativo":true}}}`)))

	if svc.MetodoActivo(context.Background(), 1, "pin") {
		t.Fatal("MetodoActivo = true, want false para um método desactivado")
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// Falha aberta: um método sem entrada explícita na configuração passa, para
// não bloquear marcações em tenants cuja configuração ainda não foi editada.
func TestMetodoActivo_SemEntradaNaConfiguracao(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)

	mock.ExpectQuery("FROM saas.feature_catalog").
		WithArgs(int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"activo", "configuracao"}).
			AddRow(true, []byte(`{"metodos":{"facial":{"ativo":true}}}`)))

	if !svc.MetodoActivo(context.Background(), 1, "pin") {
		t.Fatal("MetodoActivo = false, want true (falha aberta)")
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// A direcção inferida alterna com a paridade dos eventos do dia: número par de
// entradas/saídas já registadas -> a próxima marcação é entrada.
func TestInferirEntradaOuSaida_AlternaPorParidade(t *testing.T) {
	dia := time.Date(2026, 7, 30, 8, 0, 0, 0, time.UTC)

	casos := []struct {
		eventosDoDia int
		querCodigo   string
	}{
		{0, "entrada"},
		{1, "saida"},
		{2, "entrada"},
		{3, "saida"},
	}

	for _, caso := range casos {
		mock, err := pgxmock.NewPool()
		if err != nil {
			t.Fatal(err)
		}

		mock.ExpectQuery("SELECT COUNT").
			WithArgs(int64(1), int64(10), "2026-07-30").
			WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(caso.eventosDoDia))

		got := NewService(mock).InferirEntradaOuSaida(context.Background(), 1, 10, dia)
		if got != caso.querCodigo {
			t.Fatalf("com %d eventos no dia: got %q, want %q", caso.eventosDoDia, got, caso.querCodigo)
		}
		if err := mock.ExpectationsWereMet(); err != nil {
			t.Fatalf("expectations not met: %v", err)
		}
		mock.Close()
	}
}

// Contagem falhada não pode perder a marcação: cai para "entrada", que RH
// consegue corrigir, em vez de propagar o erro e descartar o evento.
func TestInferirEntradaOuSaida_ErroCaiParaEntrada(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery("SELECT COUNT").
		WillReturnError(errors.New("ligação perdida"))

	got := NewService(mock).InferirEntradaOuSaida(context.Background(), 1, 10, time.Now())
	if got != "entrada" {
		t.Fatalf("got %q, want %q", got, "entrada")
	}
}
