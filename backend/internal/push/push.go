// Package push envia notificações push via Firebase Cloud Messaging (FCM).
//
// É agnóstico ao módulo/portal que o usa: os tokens de dispositivo são
// guardados por user_id (auth.users.id) — a identidade universal a que todo
// o tipo de principal deste sistema (funcionário, candidato, aluno,
// encarregado) acaba ligado — em vez de uma tabela por módulo. Qualquer
// handler que consiga resolver o user_id do principal autenticado pode
// registar um token ou enviar uma notificação através deste serviço.
package push

import (
	"context"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/api/option"
)

// Service envia e regista notificações push. É seguro para uso concorrente.
// Se as credenciais não estiverem configuradas ou o ficheiro não existir,
// fica num estado inactivo em que Send/SendToUser são no-ops silenciosos —
// para nunca impedir o arranque do servidor nem falhar o fluxo que o invoca
// (ex.: gravar uma mensagem de candidatura não pode falhar por causa do push).
type Service struct {
	db     *pgxpool.Pool
	client *messaging.Client
}

// New inicializa o serviço a partir do ficheiro de credenciais da service
// account (Firebase Admin SDK). Nunca é fatal — erros ficam apenas em log.
func New(db *pgxpool.Pool, credentialsFile string) *Service {
	if credentialsFile == "" {
		log.Println("push: FIREBASE_CREDENTIALS_FILE não definido — notificações push desactivadas")
		return &Service{db: db}
	}
	if _, err := os.Stat(credentialsFile); err != nil {
		log.Printf("push: credenciais não encontradas em %q — notificações push desactivadas", credentialsFile)
		return &Service{db: db}
	}

	ctx := context.Background()
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(credentialsFile))
	if err != nil {
		log.Printf("push: erro ao inicializar Firebase: %v — notificações push desactivadas", err)
		return &Service{db: db}
	}
	client, err := app.Messaging(ctx)
	if err != nil {
		log.Printf("push: erro ao obter cliente de Messaging: %v — notificações push desactivadas", err)
		return &Service{db: db}
	}
	log.Println("push: Firebase Cloud Messaging inicializado")
	return &Service{db: db, client: client}
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

// SendToUser envia uma notificação a todos os dispositivos registados de um
// utilizador. Falhas de envio nunca são devolvidas ao chamador — ficam em
// log — porque o envio de push é sempre um efeito secundário best-effort de
// outra operação (gravar uma mensagem, mudar um estado, etc.).
func (s *Service) SendToUser(ctx context.Context, userID int64, title, body string, data map[string]string) {
	if s == nil || s.client == nil || s.db == nil {
		return
	}
	rows, err := s.db.Query(ctx,
		`SELECT token FROM notifications.push_tokens WHERE user_id=$1`, userID)
	if err != nil {
		return
	}
	var tokens []string
	for rows.Next() {
		var t string
		if rows.Scan(&t) == nil {
			tokens = append(tokens, t)
		}
	}
	rows.Close()

	s.Send(ctx, tokens, title, body, data)
}

// Send envia uma notificação a cada token da lista. Tokens individuais que
// falhem por já não estarem registados são removidos da base de dados;
// outras falhas (rede, quota, etc.) são apenas registadas em log — nenhuma
// interrompe o envio aos restantes tokens.
func (s *Service) Send(ctx context.Context, tokens []string, title, body string, data map[string]string) {
	if s == nil || s.client == nil || len(tokens) == 0 {
		return
	}
	for _, token := range tokens {
		_, err := s.client.Send(ctx, &messaging.Message{
			Token: token,
			Notification: &messaging.Notification{
				Title: title,
				Body:  body,
			},
			Data: data,
		})
		if err == nil {
			continue
		}
		if messaging.IsRegistrationTokenNotRegistered(err) || messaging.IsUnregistered(err) {
			if s.db != nil {
				s.db.Exec(ctx, `DELETE FROM notifications.push_tokens WHERE token=$1`, token)
			}
			continue
		}
		log.Printf("push: erro ao enviar notificação: %v", err)
	}
}
