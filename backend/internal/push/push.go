// Package push envia notificações push via Firebase Cloud Messaging (FCM).
//
// É agnóstico ao módulo/portal que o usa: os tokens de dispositivo são
// guardados por user_id (auth.users.id) — a identidade universal a que todo
// o tipo de principal deste sistema (funcionário, candidato, aluno,
// encarregado) acaba ligado — em vez de uma tabela por módulo. Qualquer
// handler que consiga resolver o user_id do principal autenticado pode
// registar um token ou enfileirar uma notificação através deste serviço.
//
// A entrega ao FCM em si (SendOne) passa pelo dispatcher persistente de
// internal/background/jobs.go, não é chamada directamente pelos handlers —
// Fase 3 de docs/analise-transactional-outbox-backends.md, item 1: antes
// disto, um push era um efeito síncrono e best-effort dentro do próprio
// pedido HTTP, sem retry nem registo de falha.
package push

import (
	"context"
	"errors"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/api/option"

	"nexora/internal/shared/adapters"
	"nexora/internal/shared/contracts"
)

var errFCMNaoConfigurado = errors.New("push: FCM não configurado")

// DBTX é a interface mínima de acesso à BD usada por este serviço — tanto
// *pgxpool.Pool (produção) como pgxmock (testes) a implementam.
type DBTX interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

// Service resolve tokens de dispositivo e entrega notificações push. É
// seguro para uso concorrente. Se as credenciais não estiverem configuradas
// ou o ficheiro não existir, fica num estado inactivo em que SendOne é um
// no-op que devolve erro — Enqueue* continuam a funcionar (só passam a
// enfileirar mensagens que o dispatcher nunca consegue entregar; é o mesmo
// comportamento tolerante de sempre, "nunca impedir o arranque do servidor
// nem falhar o fluxo que invoca").
type Service struct {
	db     DBTX
	client *messaging.Client
	notif  contracts.NotificationPort
}

// New inicializa o serviço a partir do ficheiro de credenciais da service
// account (Firebase Admin SDK). Nunca é fatal — erros ficam apenas em log.
func New(db *pgxpool.Pool, credentialsFile string) *Service {
	notif := adapters.NewNotificationAdapter(db)
	if credentialsFile == "" {
		log.Println("push: FIREBASE_CREDENTIALS_FILE não definido — notificações push desactivadas")
		return &Service{db: db, notif: notif}
	}
	if _, err := os.Stat(credentialsFile); err != nil {
		log.Printf("push: credenciais não encontradas em %q — notificações push desactivadas", credentialsFile)
		return &Service{db: db, notif: notif}
	}

	ctx := context.Background()
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(credentialsFile))
	if err != nil {
		log.Printf("push: erro ao inicializar Firebase: %v — notificações push desactivadas", err)
		return &Service{db: db, notif: notif}
	}
	client, err := app.Messaging(ctx)
	if err != nil {
		log.Printf("push: erro ao obter cliente de Messaging: %v — notificações push desactivadas", err)
		return &Service{db: db, notif: notif}
	}
	log.Println("push: Firebase Cloud Messaging inicializado")
	return &Service{db: db, client: client, notif: notif}
}

// Enabled diz se há um cliente FCM funcional — usado pelo dispatcher
// (internal/background/jobs.go) para decidir se vale a pena sequer olhar
// para mensagens canal_tipo='push'.
func (s *Service) Enabled() bool {
	return s != nil && s.client != nil
}

// RegisterToken associa (ou reassocia) um token de dispositivo FCM a um
// utilizador. Um token pertence sempre a um único utilizador — se o mesmo
// dispositivo autenticar como outra conta, o token migra para essa conta.
func (s *Service) RegisterToken(ctx context.Context, userID int64, token, platform string) error {
	if platform == "" {
		platform = "android"
	}
	_, err := s.db.Exec(ctx, `
		INSERT INTO notifications.push_tokens (user_id, token, platform)
		VALUES ($1, $2, $3)
		ON CONFLICT (token) DO UPDATE
		  SET user_id    = EXCLUDED.user_id,
		      platform   = EXCLUDED.platform,
		      updated_at = NOW()`,
		userID, token, platform)
	return err
}

// EnqueueToUser resolve todos os tokens de dispositivo registados de um
// utilizador e enfileira uma linha em notifications.notification_messages
// por token (canal_tipo='push') — uma por dispositivo, para que o resultado
// de cada entrega seja rastreado individualmente (Fase 3, itens 3 e 4). A
// entrega real fica a cargo do dispatcher persistente. Devolve o número de
// tokens para os quais a notificação foi enfileirada.
func (s *Service) EnqueueToUser(ctx context.Context, tenantID, userID int64, title, body string, data map[string]string) (int, error) {
	if s == nil || s.notif == nil {
		return 0, nil
	}
	tokens, err := s.tokensForUser(ctx, userID)
	if err != nil {
		return 0, err
	}
	return s.enqueueTokens(ctx, tenantID, tokens, title, body, data), nil
}

// EnqueueToTenant resolve os tokens de todos os utilizadores com associação
// activa (auth.memberships) a um tenant e enfileira uma linha por token —
// ao contrário de EnqueueToUser, não é dirigida a uma pessoa específica,
// serve para avisos gerais (promoções, manutenção, alertas). Devolve o
// número de tokens para os quais a notificação foi enfileirada.
func (s *Service) EnqueueToTenant(ctx context.Context, tenantID int64, title, body string, data map[string]string) (int, error) {
	if s == nil || s.notif == nil {
		return 0, nil
	}
	tokens, err := s.tokensForTenant(ctx, tenantID)
	if err != nil {
		return 0, err
	}
	return s.enqueueTokens(ctx, tenantID, tokens, title, body, data), nil
}

func (s *Service) tokensForUser(ctx context.Context, userID int64) ([]string, error) {
	rows, err := s.db.Query(ctx,
		`SELECT token FROM notifications.push_tokens WHERE user_id=$1`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var tokens []string
	for rows.Next() {
		var t string
		if rows.Scan(&t) == nil {
			tokens = append(tokens, t)
		}
	}
	return tokens, rows.Err()
}

func (s *Service) tokensForTenant(ctx context.Context, tenantID int64) ([]string, error) {
	rows, err := s.db.Query(ctx, `
		SELECT DISTINCT pt.token
		  FROM notifications.push_tokens pt
		  JOIN auth.memberships m ON m.user_id = pt.user_id AND m.ativo = true
		 WHERE m.tenant_id = $1`, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var tokens []string
	for rows.Next() {
		var t string
		if rows.Scan(&t) == nil {
			tokens = append(tokens, t)
		}
	}
	return tokens, rows.Err()
}

func (s *Service) enqueueTokens(ctx context.Context, tenantID int64, tokens []string, title, body string, data map[string]string) int {
	var payload map[string]any
	if len(data) > 0 {
		payload = make(map[string]any, len(data))
		for k, v := range data {
			payload[k] = v
		}
	}
	n := 0
	for _, token := range tokens {
		if err := s.notif.Send(ctx, contracts.Notification{
			TenantID:     tenantID,
			CanalTipo:    "push",
			Destinatario: token,
			Assunto:      title,
			Corpo:        body,
			Payload:      payload,
		}); err != nil {
			log.Printf("push: falha ao enfileirar notificação para um token: %v", err)
			continue
		}
		n++
	}
	return n
}

// SendOne entrega uma notificação a um único token — chamada só pelo
// dispatcher persistente (internal/background/jobs.go), uma vez por linha
// canal_tipo='push' reservada de notifications.notification_messages. Um
// token que o FCM diga já não estar registado é removido daqui; o erro é
// sempre devolvido ao chamador, que decide entre novo retry ou dead-letter.
func (s *Service) SendOne(ctx context.Context, token, title, body string, data map[string]string) error {
	if s == nil || s.client == nil {
		return errFCMNaoConfigurado
	}
	_, err := s.client.Send(ctx, &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
	})
	if err == nil {
		return nil
	}
	if messaging.IsRegistrationTokenNotRegistered(err) || messaging.IsUnregistered(err) {
		if s.db != nil {
			if _, delErr := s.db.Exec(ctx, `DELETE FROM notifications.push_tokens WHERE token=$1`, token); delErr != nil {
				log.Printf("push: falha ao remover token inválido: %v", delErr)
			}
		}
	}
	return err
}
