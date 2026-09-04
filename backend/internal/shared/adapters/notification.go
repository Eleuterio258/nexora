package adapters

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"nexora/internal/shared/contracts"
)

const notifWriteTimeout = 10 * time.Second

// DBTX é a interface mínima de acesso à BD usada por este adaptador. Tanto
// *pgxpool.Pool como pgx.Tx a implementam — permite que Send() participe,
// quando quem chama tiver uma, na transacção do negócio que originou a
// notificação (Fase 2 de docs/analise-transactional-outbox-backends.md,
// item 2), sem obrigar a isso.
type DBTX interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

// NotificationAdapter implementa contracts.NotificationPort escrevendo
// directamente em notifications.notification_messages. A entrega
// propriamente dita (email/SMS) é feita à parte pelo dispatcher em
// internal/background/jobs.go — Send() só grava a mensagem pendente.
type NotificationAdapter struct {
	db DBTX
}

// NewNotificationAdapter cria um novo adaptador de Notificações sobre a pool
// de ligações.
func NewNotificationAdapter(db DBTX) *NotificationAdapter {
	return &NotificationAdapter{db: db}
}

// NewNotificationAdapterWithTx cria um adaptador cujo Send() grava dentro da
// transacção recebida — nunca faz Commit/Rollback, essa continua a ser
// responsabilidade do chamador (mesmo padrão de
// assiduidade.NewServiceWithTx, Fase 0).
func NewNotificationAdapterWithTx(tx pgx.Tx) *NotificationAdapter {
	return NewNotificationAdapter(tx)
}

// Send insere uma notificação na tabela de mensagens com status 'pendente'.
// Usa context.Background() com timeout próprio — não cancela com o request
// HTTP, para não perder a notificação só porque o cliente desligou
// entretanto. Isto aplica-se também quando a. db é uma pgx.Tx do chamador
// (NewNotificationAdapterWithTx): a transacção em si já está amarrada ao
// contexto com que foi aberta, este timeout só limita a duração do INSERT.
func (a *NotificationAdapter) Send(ctx context.Context, n contracts.Notification) error {
	if n.Destinatario == "" || n.Corpo == "" {
		return nil
	}
	assunto := n.Assunto
	if assunto == "" {
		assunto = "Notificação Escolar"
	}
	var payload any
	if len(n.Payload) > 0 {
		raw, err := json.Marshal(n.Payload)
		if err != nil {
			return err
		}
		payload = raw
	}
	wCtx, cancel := context.WithTimeout(context.Background(), notifWriteTimeout)
	defer cancel()
	_, err := a.db.Exec(wCtx, `
		INSERT INTO notifications.notification_messages
		(tenant_id, canal_tipo, destinatario, assunto, corpo, template_id,
		 referencia_tipo, referencia_id, anexo_storage_key, anexo_nome, payload, status)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'pendente')`,
		n.TenantID, n.CanalTipo, n.Destinatario, assunto, n.Corpo, n.TemplateID,
		nullStr(n.ReferenciaTipo), n.ReferenciaID, nullStr(n.AnexoStorageKey), nullStr(n.AnexoNome), payload)
	return err
}

func nullStr(s string) any {
	if s == "" {
		return nil
	}
	return s
}
