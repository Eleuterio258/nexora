package service

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/pashagolub/pgxmock/v4"

	"nexora/internal/modules/hardware/models"
)

func TestProcess_EventoDuplicadoDevolveEstadoRealDaLinhaExistente(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	insertArgs := make([]any, 8)
	for i := range insertArgs {
		insertArgs[i] = pgxmock.AnyArg()
	}
	mock.ExpectQuery("INSERT INTO hardware.device_events").
		WithArgs(insertArgs...).
		WillReturnError(pgx.ErrNoRows)
	existingErrorMessage := "employee_no não mapeado"
	mock.ExpectQuery("SELECT id, processed, error_message").
		WithArgs(pgxmock.AnyArg()).
		WillReturnRows(pgxmock.NewRows([]string{"id", "processed", "error_message"}).
			AddRow(int64(42), false, &existingErrorMessage))

	p := NewProcessor(mock)
	event := &models.NormalizedEvent{
		EmployeeNo: "E1", EventTime: time.Now(), CredentialType: "face",
		RawPayload: []byte(`{}`),
	}
	id, result, err := p.Process(context.Background(), 1, 1, event)
	if err != nil {
		t.Fatalf("Process: %v", err)
	}
	if id != 42 {
		t.Fatalf("id = %d, want 42", id)
	}
	// Antes desta correção, um evento duplicado devolvia sempre
	// Processed:true, mesmo quando a tentativa original tinha falhado — o
	// bug que o item 4 da Fase 5 ("replay seguro") corrige.
	if result.Processed {
		t.Fatal("Processed = true, want false (a linha existente falhou)")
	}
	if result.ErrorMessage != "employee_no não mapeado" {
		t.Fatalf("ErrorMessage = %q, want a mensagem da linha existente", result.ErrorMessage)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestFinalizeEvent_SucessoLimpaLock(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("UPDATE hardware.device_events\\s+SET processed = TRUE").
		WithArgs(pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	p := NewProcessor(mock)
	presencaID := int64(99)
	err = p.finalizeEvent(context.Background(), 1, 0, ProcessResult{Processed: true, PresencaID: &presencaID})
	if err != nil {
		t.Fatalf("finalizeEvent: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestFinalizeEvent_FalhaPermanenteMarcaPermanentFailure(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("UPDATE hardware.device_events\\s+SET error_message = \\$1, permanent_failure = TRUE").
		WithArgs("credential_type 'x' desconhecido", int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	p := NewProcessor(mock)
	err = p.finalizeEvent(context.Background(), 1, 0, ProcessResult{
		ErrorMessage: "credential_type 'x' desconhecido", Permanent: true,
	})
	if err != nil {
		t.Fatalf("finalizeEvent: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestFinalizeEvent_FalhaTransitoriaAgendaRetryComBackoffCrescente(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("UPDATE hardware.device_events\\s+SET error_message = \\$1, attempts = \\$2").
		WithArgs("employee_no não mapeado", 3, deviceEventBackoffFor(3).Seconds(), int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	p := NewProcessor(mock)
	err = p.finalizeEvent(context.Background(), 1, 2, ProcessResult{ErrorMessage: "employee_no não mapeado"})
	if err != nil {
		t.Fatalf("finalizeEvent: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestDeviceEventBackoffFor_Cresce(t *testing.T) {
	anterior := time.Duration(0)
	for attempts := 1; attempts <= deviceEventMaxAttempts; attempts++ {
		atual := deviceEventBackoffFor(attempts)
		if atual <= anterior {
			t.Errorf("backoff não cresceu entre tentativa %d e %d: %v -> %v", attempts-1, attempts, anterior, atual)
		}
		anterior = atual
	}
	// Fica fixo no último valor da tabela além do seu tamanho.
	if deviceEventBackoffFor(100) != deviceEventBackoffFor(deviceEventMaxAttempts) {
		t.Fatalf("backoff(100) devia ficar fixo no último valor da tabela")
	}
}

func TestClaimForRetry_ReservaSemMexerEmProcessedOuPermanentFailure(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery("WITH candidatos AS").
		WithArgs(50, "worker-1").
		WillReturnRows(pgxmock.NewRows(
			[]string{"id", "tenant_id", "device_id", "normalized_payload", "attempts"},
		).AddRow(int64(1), int64(7), int64(3), []byte(`{"EmployeeNo":"E1"}`), 2))

	p := NewProcessor(mock)
	retries, err := p.ClaimForRetry(context.Background(), "worker-1", 50)
	if err != nil {
		t.Fatalf("ClaimForRetry: %v", err)
	}
	if len(retries) != 1 || retries[0].Attempts != 2 {
		t.Fatalf("retries = %+v, want 1 com attempts=2", retries)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestRecoverExpiredLeases(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("UPDATE hardware.device_events").
		WithArgs(pgxmock.AnyArg()).
		WillReturnResult(pgxmock.NewResult("UPDATE", 4))

	p := NewProcessor(mock)
	n, err := p.RecoverExpiredLeases(context.Background(), 5*time.Minute)
	if err != nil {
		t.Fatalf("RecoverExpiredLeases: %v", err)
	}
	if n != 4 {
		t.Fatalf("n = %d, want 4", n)
	}
}

func TestRetry_PayloadInvalidoDevolveErroSemTocarNaBD(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	p := NewProcessor(mock)
	err = p.Retry(context.Background(), DeviceEventRetry{ID: 1, NormalizedPayload: []byte("não é json")})
	if err == nil {
		t.Fatal("Retry err = nil, want erro de desserialização")
	}
	// Nenhuma expectativa registada: se tivesse tocado na BD, o mock
	// devolvia erro de chamada inesperada.
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestRetry_ChamaProcessEntityEGravaFalhaPermanente(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	// tenantid.ResolveSaas falha → processEntity devolve Permanent:true —
	// finalizeEvent tem de marcar permanent_failure sem agendar retry.
	mock.ExpectQuery("SELECT tenant_id FROM empresas.companies").
		WithArgs(int64(7)).
		WillReturnError(errors.New("empresa não encontrada"))
	mock.ExpectExec("UPDATE hardware.device_events\\s+SET error_message = \\$1, permanent_failure = TRUE").
		WithArgs("dispositivo sem empresa/tenant associado correctamente", int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	payload, _ := json.Marshal(models.NormalizedEvent{EmployeeNo: "E1", CredentialType: "face"})
	p := NewProcessor(mock)
	err = p.Retry(context.Background(), DeviceEventRetry{
		ID: 1, TenantID: 7, DeviceID: 3, NormalizedPayload: payload, Attempts: 1,
	})
	if err != nil {
		t.Fatalf("Retry: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}
