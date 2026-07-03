package background

import (
	"crypto/tls"
	"fmt"
	"mime"
	"net"
	"net/smtp"
	"strings"

	"nexora/config"
)

// smtpMailer envia emails via SMTP.
// Se SMTPHost não estiver configurado, Send é no-op silencioso.
type smtpMailer struct {
	host     string
	port     int
	user     string
	password string
	from     string
	fromName string
}

func newMailer(cfg *config.Config) *smtpMailer {
	return &smtpMailer{
		host:     cfg.SMTPHost,
		port:     cfg.SMTPPort,
		user:     cfg.SMTPUser,
		password: cfg.SMTPPassword,
		from:     cfg.SMTPFrom,
		fromName: cfg.SMTPFromName,
	}
}

func (m *smtpMailer) enabled() bool {
	return m.host != "" && m.from != ""
}

// send envia um email de texto simples.
// Porta 465 → SMTPS (TLS imediato).
// Outras portas → STARTTLS via smtp.SendMail.
func (m *smtpMailer) send(to, subject, body string) error {
	if !m.enabled() {
		return nil
	}

	from := fmt.Sprintf("%s <%s>", m.fromName, m.from)
	encodedSubject := mime.QEncoding.Encode("UTF-8", subject)

	var buf strings.Builder
	fmt.Fprintf(&buf, "From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s",
		from, to, encodedSubject, body)
	msg := []byte(buf.String())

	addr := fmt.Sprintf("%s:%d", m.host, m.port)

	if m.port == 465 {
		return m.sendTLS(addr, to, msg)
	}
	// STARTTLS (portas 587 / 25)
	var auth smtp.Auth
	if m.user != "" {
		auth = smtp.PlainAuth("", m.user, m.password, m.host)
	}
	return smtp.SendMail(addr, auth, m.from, []string{to}, msg)
}

func (m *smtpMailer) sendTLS(addr, to string, msg []byte) error {
	tlsCfg := &tls.Config{ServerName: m.host}
	conn, err := tls.Dial("tcp", addr, tlsCfg)
	if err != nil {
		return fmt.Errorf("smtp tls dial: %w", err)
	}
	defer conn.Close()

	host, _, _ := net.SplitHostPort(addr)
	c, err := smtp.NewClient(conn, host)
	if err != nil {
		return fmt.Errorf("smtp client: %w", err)
	}
	defer c.Close()

	if m.user != "" {
		if err := c.Auth(smtp.PlainAuth("", m.user, m.password, m.host)); err != nil {
			return fmt.Errorf("smtp auth: %w", err)
		}
	}
	if err := c.Mail(m.from); err != nil {
		return err
	}
	if err := c.Rcpt(to); err != nil {
		return err
	}
	w, err := c.Data()
	if err != nil {
		return err
	}
	if _, err = w.Write(msg); err != nil {
		return err
	}
	return w.Close()
}
