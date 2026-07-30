package handlers

import (
	"errors"
	"net"
	"net/http"
	"time"

	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
)

// MarcarPontoRequest é o payload de POST /api/self-service/assiduidade/ponto.
//
// Não tem funcionario_id: o ponto é sempre do colaborador autenticado,
// resolvido a partir do JWT. Quem marca ponto em nome de outra pessoa usa
// POST /api/rh/eventos, protegido por recursos-humanos:gerir_funcionarios.
type MarcarPontoRequest struct {
	// metodo é a chave da configuração do tenant (rh.assiduidade.metodos).
	// Por omissão "pin" — o único método que este endpoint sabe provar
	// sozinho; ver o comentário de MarcarPonto.
	Metodo string `json:"metodo"`
	PIN    string `json:"pin"`
	// tipo_evento_codigo é opcional: sem ele, entrada/saída alternam pela
	// paridade dos eventos do dia (assiduidade.InferirEntradaOuSaida), que é
	// o comportamento de um único botão "marcar ponto" na app.
	TipoEventoCodigo string   `json:"tipo_evento_codigo"`
	Latitude         *float64 `json:"latitude"`
	Longitude        *float64 `json:"longitude"`
	LocalidadeID     *int64   `json:"localidade_id"`
	Observacoes      *string  `json:"observacoes"`
}

// tiposEventoSelfService são os únicos tipos que um colaborador pode marcar
// sobre si próprio. Ausências (falta, férias, baixa, licença) e horas extra
// ficam de fora de propósito: são decisões de RH, não factos que a pessoa
// possa declarar sozinha ao bater o ponto.
var tiposEventoSelfService = map[string]bool{
	"entrada":          true,
	"saida":            true,
	"intervalo_inicio": true,
	"intervalo_fim":    true,
}

// MarcarPonto regista o ponto do próprio colaborador autenticado por JWT —
// Fase 1 do roadmap em docs/arquitetura-comunicacao-assiduidade.md §10. Até
// aqui, marcar ponto pela app passava sempre por POST /api/hardware/events*,
// autenticado pela API Key de device embutida no APK: uma credencial de
// máquina, igual em todas as instalações, que identifica o telefone e não a
// pessoa. Com este endpoint a marcação passa a ser feita com a identidade de
// quem a faz, e a permissão assiduidade:marcar_ponto (semeada em
// 20260728000004) ganha finalmente uma rota que a consome.
//
// O PIN é verificado aqui, e não delegado a POST /api/authcode/pin/verify,
// porque esse endpoint só devolve um veredicto ao cliente: um cliente
// modificado saltava-o e marcava o ponto na mesma. A prova de presença tem de
// acontecer no mesmo pedido que grava o evento.
//
// Os métodos que dependem de segredos ou hardware de terceiros ficam fora:
// facial e digital continuam a passar pelo FaceClock (VerificarFacial), QR e
// NFC pelos validadores de device. Um pedido com outro método é recusado em
// vez de aceite sem prova nenhuma.
func (h *Handler) MarcarPonto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body MarcarPontoRequest
	if err := decodeJSON(r, &body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}
	if body.Metodo == "" {
		body.Metodo = "pin"
	}
	if body.Metodo != "pin" {
		jsonErr(w, "Este endpoint só aceita o método 'pin'", http.StatusBadRequest)
		return
	}
	if body.PIN == "" {
		jsonErr(w, "pin é obrigatório", http.StatusBadRequest)
		return
	}
	if body.TipoEventoCodigo != "" && !tiposEventoSelfService[body.TipoEventoCodigo] {
		jsonErr(w, "tipo_evento_codigo não permitido em marcações próprias", http.StatusBadRequest)
		return
	}

	// O funcionário vem do resolver central (mesmo caminho do processor de
	// hardware), que garante que pertence ao tenant do token e valida o
	// estado — um colaborador desligado mantém o login enquanto o utilizador
	// não for desactivado, mas não pode continuar a bater ponto.
	colab, err := funcionario.NewService(h.db).PorUserID(r.Context(), user.TenantID, user.ID)
	if err != nil {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}
	if err := colab.VerificarAtivo(); err != nil {
		jsonErr(w, "Funcionário inativo", http.StatusForbidden)
		return
	}

	svc := assiduidade.NewService(h.db)
	if !svc.MetodoActivo(r.Context(), user.TenantID, "pin") {
		jsonErr(w, "Marcação por PIN desactivada para esta empresa", http.StatusForbidden)
		return
	}

	switch h.verificarPIN(r, user.ID, body.PIN) {
	case pinNaoConfigurado:
		jsonErr(w, "PIN não configurado — peça a RH para definir o seu PIN", http.StatusPreconditionFailed)
		return
	case pinIncorrecto:
		jsonErr(w, "PIN incorrecto", http.StatusForbidden)
		return
	}

	// Sem limite ao número de marcações do dia: cada toque é um facto que fica
	// gravado, e o emparelhamento é feito no fim por assiduidade.RecalcularDia
	// (agruparPorTipoPar), que junta entrada→saída por ordem cronológica e
	// ignora o que não fecha par. Recusar marcações próximas aqui só perderia
	// eventos reais — várias saídas e regressos no mesmo dia são normais.
	agora := time.Now()

	tipoEvento := body.TipoEventoCodigo
	if tipoEvento == "" {
		tipoEvento = svc.InferirEntradaOuSaida(r.Context(), user.TenantID, colab.ID, agora)
	}

	metodo := "pin"
	// origem é o canal por onde a marcação chegou, e está limitada pelo CHECK
	// eventos_assiduidade_origem_check — que não aceita "pin"; o método fica
	// em metodo_id. Mesmo par (metodo=pin, origem=app) que o processor de
	// hardware usa para as marcações por PIN vindas do terminal.
	origem := "app"
	registadoPor := user.ID
	ip := ipDoPedido(r)
	ua := r.UserAgent()

	ev, err := svc.RegistarEvento(r.Context(), user.TenantID, assiduidade.RegistarEventoInput{
		FuncionarioID:    colab.ID,
		TipoEventoCodigo: tipoEvento,
		MetodoCodigo:     &metodo,
		OcorridoEm:       agora,
		Origem:           origem,
		Latitude:         body.Latitude,
		Longitude:        body.Longitude,
		LocalidadeID:     body.LocalidadeID,
		RegistadoPor:     &registadoPor,
		Observacoes:      body.Observacoes,
		IPOrigem:         &ip,
		UserAgent:        &ua,
	})
	if err != nil {
		if errors.Is(err, assiduidade.ErrTipoEventoDesconhecido) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro ao registar o ponto", http.StatusInternalServerError)
		return
	}

	// O resultado diário (presente/atraso/horas) não é recalculado aqui: é
	// responsabilidade de assiduidade.RecalcularDia, chamado pelo job em
	// background/jobs.go, tal como para os eventos vindos de hardware.
	jsonOK(w, ev, http.StatusCreated)
}

type resultadoPIN int

const (
	pinValido resultadoPIN = iota
	pinNaoConfigurado
	pinIncorrecto
)

// verificarPIN repete a verificação de auth.VerificarPIN
// (auth/handlers/authcode.go, POST /api/authcode/pin/verify) por a prova ter
// de ser feita no mesmo pedido que grava o evento. Só o PIN activo conta:
// desactivar a linha em auth.user_auth_codes retira a marcação por PIN sem
// apagar o histórico.
func (h *Handler) verificarPIN(r *http.Request, userID int64, pin string) resultadoPIN {
	var hash string
	err := h.db.QueryRow(r.Context(), `
		SELECT secret_hash FROM auth.user_auth_codes
		 WHERE user_id = $1 AND tipo = 'pin' AND ativo = true`, userID).Scan(&hash)
	if err != nil {
		return pinNaoConfigurado
	}
	if bcrypt.CompareHashAndPassword([]byte(hash), []byte(pin)) != nil {
		return pinIncorrecto
	}
	return pinValido
}

// ipDoPedido devolve o IP sem porta. rh.eventos_assiduidade.ip_origem é uma
// coluna inet e r.RemoteAddr traz "host:porta" sempre que não há
// X-Forwarded-For para middleware.RealIP substituir (ex.: chamadas de dentro
// da rede docker) — o INSERT falharia no fim de todas as validações, com o
// colaborador a levar um 500 depois de o PIN já ter sido aceite.
func ipDoPedido(r *http.Request) string {
	if host, _, err := net.SplitHostPort(r.RemoteAddr); err == nil {
		return host
	}
	return r.RemoteAddr
}
