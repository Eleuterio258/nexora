package background

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"

	"nexora/config"
)

// smsSender envia mensagens SMS. Implementações reais (Twilio, Africa's Talking,
// gateway local) devem satisfazer esta interface.
type smsSender interface {
	send(to, message string) error
}

// newSMSSender cria o sender consoante a configuração. Provider vazio ou
// "noop" devolve um sender que só loga e não envia — útil para testes ou quando
// o SMS ainda não está configurado.
func newSMSSender(cfg *config.Config) smsSender {
	switch strings.ToLower(cfg.SMSProvider) {
	case "twilio":
		return &twilioSender{
			accountSID: cfg.SMSTwilioSID,
			authToken:  cfg.SMSTwilioToken,
			fromNumber: cfg.SMSTwilioFrom,
			client:     &http.Client{Timeout: 15 * time.Second},
		}
	case "noop", "":
		return &noopSMSSender{}
	default:
		// Provider desconhecido: usa noop para não quebrar o arranque, mas loga aviso.
		log.Printf("[background] provider SMS desconhecido %q; usando noop", cfg.SMSProvider)
		return &noopSMSSender{}
	}
}

// twilioSender envia SMS via Twilio Programmable Messaging.
type twilioSender struct {
	accountSID string
	authToken  string
	fromNumber string
	client     *http.Client
}

func (t *twilioSender) send(to, message string) error {
	if t.accountSID == "" || t.authToken == "" || t.fromNumber == "" {
		return fmt.Errorf("configuração Twilio incompleta")
	}
	if !strings.HasPrefix(to, "+") {
		return fmt.Errorf("número de telefone deve incluir código do país (ex: +258...)")
	}

	endpoint := fmt.Sprintf("https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json", t.accountSID)
	data := url.Values{}
	data.Set("To", to)
	data.Set("From", t.fromNumber)
	data.Set("Body", message)

	req, err := http.NewRequest(http.MethodPost, endpoint, strings.NewReader(data.Encode()))
	if err != nil {
		return err
	}
	req.SetBasicAuth(t.accountSID, t.authToken)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := t.client.Do(req)
	if err != nil {
		return fmt.Errorf("twilio request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return nil
	}

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	return fmt.Errorf("twilio error %d: %s", resp.StatusCode, string(body))
}

// noopSMSSender não envia SMS; apenas valida o número e loga (em dev/testes).
type noopSMSSender struct{}

func (n *noopSMSSender) send(to, message string) error {
	if !strings.HasPrefix(to, "+") {
		return fmt.Errorf("número de telefone deve incluir código do país (ex: +258...)")
	}
	log.Printf("[background] SMS noop para %s: %s", to, message)
	return nil
}

