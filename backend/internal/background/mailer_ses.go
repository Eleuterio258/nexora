package background

import (
	"context"
	"fmt"

	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sesv2"
	"github.com/aws/aws-sdk-go-v2/service/sesv2/types"

	"nexora/config"
)

// sesMailer envia emails transaccionais via API nativa do AWS SES (SendEmail
// v2). As credenciais AWS seguem a cadeia standard do SDK (variáveis de
// ambiente AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY/AWS_SESSION_TOKEN, ficheiro
// partilhado ou role IAM) — não há campos de credenciais próprios aqui.
// Se SESFrom não estiver configurado, send é no-op silencioso.
type sesMailer struct {
	client   *sesv2.Client
	from     string
	fromName string
}

func newMailer(cfg *config.Config) *sesMailer {
	if cfg.SESFrom == "" {
		return &sesMailer{}
	}
	awsCfg, err := awsconfig.LoadDefaultConfig(context.Background(), awsconfig.WithRegion(cfg.SESRegion))
	if err != nil {
		return &sesMailer{}
	}
	return &sesMailer{
		client:   sesv2.NewFromConfig(awsCfg),
		from:     cfg.SESFrom,
		fromName: cfg.SESFromName,
	}
}

func (m *sesMailer) enabled() bool {
	return m.client != nil && m.from != ""
}

func (m *sesMailer) send(to, subject, body string) error {
	if !m.enabled() {
		return nil
	}

	from := m.from
	if m.fromName != "" {
		from = fmt.Sprintf("%s <%s>", m.fromName, m.from)
	}

	_, err := m.client.SendEmail(context.Background(), &sesv2.SendEmailInput{
		FromEmailAddress: &from,
		Destination:      &types.Destination{ToAddresses: []string{to}},
		Content: &types.EmailContent{
			Simple: &types.Message{
				Subject: &types.Content{Data: &subject},
				Body: &types.Body{
					Text: &types.Content{Data: &body},
				},
			},
		},
	})
	if err != nil {
		return fmt.Errorf("ses send: %w", err)
	}
	return nil
}

// SendTestEmail cria um mailer SES a partir da configuração e envia um email,
// devolvendo o erro real de configuração/envio — ao contrário do mailer usado
// por dispatchNotifications, que fica silenciosamente desligado se SES_FROM
// estiver vazio. Usado por cmd/send-test-email para diagnosticar a
// configuração de SES sem subir o servidor todo.
func SendTestEmail(cfg *config.Config, to, subject, body string) error {
	if cfg.SESFrom == "" {
		return fmt.Errorf("SES_FROM não está configurado")
	}
	awsCfg, err := awsconfig.LoadDefaultConfig(context.Background(), awsconfig.WithRegion(cfg.SESRegion))
	if err != nil {
		return fmt.Errorf("carregar credenciais AWS: %w", err)
	}
	m := &sesMailer{client: sesv2.NewFromConfig(awsCfg), from: cfg.SESFrom, fromName: cfg.SESFromName}
	return m.send(to, subject, body)
}
