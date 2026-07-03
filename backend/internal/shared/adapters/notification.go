package adapters

import (
	"context"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/shared/contracts"
)

const notifWriteTimeout = 10 * time.Second

// NotificationAdapter implementa contracts.NotificationPort escrevendo
// directamente em notifications.notification_messages.
// Falhas são logadas mas nunca propagadas — notificações não bloqueiam o fluxo principal.
type NotificationAdapter struct {
	db *pgxpool.Pool
}

// NewNotificationAdapter cria um novo adaptador de Notificações.
func NewNotificationAdapter(db *pgxpool.Pool) *NotificationAdapter {
	return &NotificationAdapter{db: db}
}

// Send insere uma notificação na tabela de mensagens com status 'pendente'.
// Usa context.Background() com timeout próprio — não cancela com o request HTTP.
func (a *NotificationAdapter) Send(ctx context.Context, n contracts.Notification) {
	if n.Destinatario == "" || n.Corpo == "" {
		return
	}
	assunto := n.Assunto
	if assunto == "" {
		assunto = "Notificação Escolar"
	}
	wCtx, cancel := context.WithTimeout(context.Background(), notifWriteTimeout)
	defer cancel()
	_, err := a.db.Exec(wCtx, `
		INSERT INTO notifications.notification_messages
		(tenant_id, canal_tipo, destinatario, assunto, corpo, template_id,
		 referencia_tipo, referencia_id, status)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'pendente')`,
		n.TenantID, n.CanalTipo, n.Destinatario, assunto, n.Corpo, n.TemplateID,
		nullStr(n.ReferenciaTipo), n.ReferenciaID)
	if err != nil {
		log.Printf("[notif] falha ao enviar para %s (tenant=%d): %v",
			n.Destinatario, n.TenantID, err)
	}
}

func nullStr(s string) any {
	if s == "" {
		return nil
	}
	return s
}
