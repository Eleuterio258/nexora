package background

import (
	"bytes"
	"context"
	"encoding/base64"
	"fmt"
	"io"
	"mime/multipart"
	"mime/quotedprintable"
	"net/textproto"

	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sesv2"
	"github.com/aws/aws-sdk-go-v2/service/sesv2/types"

	"nexora/config"
	"nexora/internal/storage"
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

// sendWithAttachment envia um email com um único anexo, montando a mensagem
// MIME em bruto (SESv2 SendEmail aceita Content.Raw para isto — não precisa
// da API SendRawEmail separada).
func (m *sesMailer) sendWithAttachment(to, subject, body, anexoNome string, anexoBytes []byte, anexoContentType string) error {
	if !m.enabled() {
		return nil
	}
	from := m.from
	if m.fromName != "" {
		from = fmt.Sprintf("%s <%s>", m.fromName, m.from)
	}

	raw, err := buildRawEmail(from, to, subject, body, anexoNome, anexoContentType, anexoBytes)
	if err != nil {
		return fmt.Errorf("montar email com anexo: %w", err)
	}

	_, err = m.client.SendEmail(context.Background(), &sesv2.SendEmailInput{
		FromEmailAddress: &from,
		Destination:      &types.Destination{ToAddresses: []string{to}},
		Content:          &types.EmailContent{Raw: &types.RawMessage{Data: raw}},
	})
	if err != nil {
		return fmt.Errorf("ses send (com anexo): %w", err)
	}
	return nil
}

// buildRawEmail monta uma mensagem MIME multipart/mixed (corpo texto +
// anexo em base64) pronta para SESv2 Content.Raw.
func buildRawEmail(from, to, subject, body, anexoNome, anexoContentType string, anexoBytes []byte) ([]byte, error) {
	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf)

	fmt.Fprintf(&buf, "From: %s\r\n", from)
	fmt.Fprintf(&buf, "To: %s\r\n", to)
	fmt.Fprintf(&buf, "Subject: %s\r\n", subject)
	fmt.Fprintf(&buf, "MIME-Version: 1.0\r\n")
	fmt.Fprintf(&buf, "Content-Type: multipart/mixed; boundary=%q\r\n\r\n", mw.Boundary())

	textHeader := textproto.MIMEHeader{}
	textHeader.Set("Content-Type", `text/plain; charset="utf-8"`)
	textHeader.Set("Content-Transfer-Encoding", "quoted-printable")
	pw, err := mw.CreatePart(textHeader)
	if err != nil {
		return nil, err
	}
	qp := quotedprintable.NewWriter(pw)
	if _, err := qp.Write([]byte(body)); err != nil {
		return nil, err
	}
	if err := qp.Close(); err != nil {
		return nil, err
	}

	if len(anexoBytes) > 0 {
		if anexoContentType == "" {
			anexoContentType = "application/octet-stream"
		}
		attHeader := textproto.MIMEHeader{}
		attHeader.Set("Content-Type", fmt.Sprintf(`%s; name=%q`, anexoContentType, anexoNome))
		attHeader.Set("Content-Transfer-Encoding", "base64")
		attHeader.Set("Content-Disposition", fmt.Sprintf(`attachment; filename=%q`, anexoNome))
		aw, err := mw.CreatePart(attHeader)
		if err != nil {
			return nil, err
		}
		encoded := base64.StdEncoding.EncodeToString(anexoBytes)
		for i := 0; i < len(encoded); i += 76 {
			end := i + 76
			if end > len(encoded) {
				end = len(encoded)
			}
			if _, err := io.WriteString(aw, encoded[i:end]+"\r\n"); err != nil {
				return nil, err
			}
		}
	}

	if err := mw.Close(); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// sendEmailComAnexo lê o anexo do storage e envia o email — usado por
// dispatchNotifications quando a mensagem tem anexo_storage_key preenchido.
func sendEmailComAnexo(ctx context.Context, mailer *sesMailer, store storage.Provider, to, subject, body, anexoNome, anexoStorageKey string) error {
	reader, _, err := store.Get(ctx, anexoStorageKey)
	if err != nil {
		return fmt.Errorf("ler anexo do storage: %w", err)
	}
	defer reader.Close()
	data, err := io.ReadAll(reader)
	if err != nil {
		return fmt.Errorf("ler bytes do anexo: %w", err)
	}
	return mailer.sendWithAttachment(to, subject, body, anexoNome, data, "application/pdf")
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
