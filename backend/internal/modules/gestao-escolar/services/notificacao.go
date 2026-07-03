package services

import "fmt"

// notifEscolar formata mensagem padrão para eventos escolares.
// Usado pelos handlers ao construir notificações via h.notification.Send().
func notifEscolar(evento, detalhe string) string {
	return fmt.Sprintf("[Escolar] %s: %s", evento, detalhe)
}
