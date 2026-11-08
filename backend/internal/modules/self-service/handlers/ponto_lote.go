package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
)

// Limites do lote offline. A janela de 72h é a decisão de produto para
// marcações feitas sem rede: a hora vem do telemóvel e pode ser falsificada,
// por isso só se aceita um passado recente e nunca o futuro (com uma folga
// pequena para relógios ligeiramente adiantados). Tudo o que é aceite fica
// assinalado como offline nas observações do evento para o RH poder rever.
const (
	maxMarcacoesLote      = 100
	janelaMarcacaoOffline = 72 * time.Hour
	folgaRelogioFuturo    = 5 * time.Minute
	maxIdempotencyKey     = 128
)

// metodosOffline são os métodos cuja prova ainda pode ser verificada quando o
// evento chega mais tarde. PIN é verificado no ERP no momento da
// sincronização; a impressão digital do telemóvel nunca teve prova do lado do
// servidor (é o mesmo tratamento de POST /ponto). Facial, QR e NFC dependem de
// comprovativos de uso único com validade curta e têm de ser marcados online.
var metodosOffline = map[string]bool{
	"pin":         true,
	"fingerprint": true,
}

// MarcacaoOffline é uma marcação guardada na app enquanto estava sem rede.
type MarcacaoOffline struct {
	IdempotencyKey   string   `json:"idempotency_key"`
	Metodo           string   `json:"metodo"`
	PIN              string   `json:"pin"`
	TipoEventoCodigo string   `json:"tipo_evento_codigo"`
	OcorridoEm       string   `json:"ocorrido_em"` // RFC 3339, hora do telemóvel
	DeviceID         string   `json:"device_id"`
	Latitude         *float64 `json:"latitude"`
	Longitude        *float64 `json:"longitude"`
}

// MarcarPontoLoteRequest é o payload de POST /api/self-service/assiduidade/ponto/batch.
type MarcarPontoLoteRequest struct {
	Eventos []MarcacaoOffline `json:"eventos"`
}

// Estados devolvidos por marcação. "duplicado" significa que a mesma
// idempotency_key já tinha sido sincronizada: a app deve tratá-lo como
// sucesso e apagar o evento local. "rejeitado" é definitivo — reenviar o
// mesmo evento dá o mesmo resultado.
const (
	estadoRegistado = "registado"
	estadoDuplicado = "duplicado"
	estadoRejeitado = "rejeitado"
)

type ResultadoMarcacaoOffline struct {
	IdempotencyKey string `json:"idempotency_key"`
	Estado         string `json:"estado"`
	EventoID       *int64 `json:"evento_id,omitempty"`
	Erro           string `json:"erro,omitempty"`
}

type marcacaoValidada struct {
	item       MarcacaoOffline
	ocorridoEm time.Time
	cfg        metodoSelfService
}

// validarMarcacaoOffline faz as verificações que não precisam de base de
// dados: chave, método, tipo de evento e janela temporal.
func validarMarcacaoOffline(item MarcacaoOffline, agora time.Time) (marcacaoValidada, error) {
	key := strings.TrimSpace(item.IdempotencyKey)
	if key == "" || len(key) > maxIdempotencyKey {
		return marcacaoValidada{}, errors.New("idempotency_key em falta ou demasiado longa")
	}
	item.IdempotencyKey = key

	cfg, ok := metodosSelfService[item.Metodo]
	if !ok {
		return marcacaoValidada{}, fmt.Errorf("método de marcação '%s' não suportado", item.Metodo)
	}
	if !metodosOffline[item.Metodo] {
		return marcacaoValidada{}, fmt.Errorf("o método '%s' não pode ser sincronizado offline: marque o ponto com rede", item.Metodo)
	}
	if item.TipoEventoCodigo != "" && !tiposEventoSelfService[item.TipoEventoCodigo] {
		return marcacaoValidada{}, errors.New("tipo_evento_codigo não permitido em marcações próprias")
	}
	if cfg.RequerPIN && item.PIN == "" {
		return marcacaoValidada{}, errors.New("pin é obrigatório")
	}

	ocorrido, err := time.Parse(time.RFC3339, strings.TrimSpace(item.OcorridoEm))
	if err != nil {
		return marcacaoValidada{}, errors.New("ocorrido_em inválido (esperado RFC 3339)")
	}
	if ocorrido.After(agora.Add(folgaRelogioFuturo)) {
		return marcacaoValidada{}, errors.New("ocorrido_em está no futuro")
	}
	if agora.Sub(ocorrido) > janelaMarcacaoOffline {
		return marcacaoValidada{}, fmt.Errorf("marcação com mais de %d horas: peça a correcção ao RH", int(janelaMarcacaoOffline.Hours()))
	}

	return marcacaoValidada{item: item, ocorridoEm: ocorrido, cfg: cfg}, nil
}

// MarcarPontoLote sincroniza as marcações que a app guardou enquanto estava
// offline. É a alternativa autenticada por JWT a POST /api/hardware/events/generic
// com a API Key de device.
//
// Cada marcação é tratada numa transacção própria: uma rejeitada não impede as
// outras. As marcações são processadas por ordem cronológica para que a
// inferência entrada/saída siga a ordem real.
func (h *Handler) MarcarPontoLote(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body MarcarPontoLoteRequest
	if err := decodeJSON(r, &body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}
	if len(body.Eventos) == 0 {
		jsonErr(w, "eventos é obrigatório", http.StatusBadRequest)
		return
	}
	if len(body.Eventos) > maxMarcacoesLote {
		jsonErr(w, fmt.Sprintf("máximo de %d marcações por lote", maxMarcacoesLote), http.StatusBadRequest)
		return
	}

	colab, err := funcionario.NewService(h.db).PorUserID(r.Context(), user.TenantID, user.ID)
	if err != nil {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}
	if err := colab.VerificarAtivo(); err != nil {
		jsonErr(w, "Funcionário inativo", http.StatusForbidden)
		return
	}

	agora := time.Now()
	resultados := make([]ResultadoMarcacaoOffline, len(body.Eventos))
	validas := make([]int, 0, len(body.Eventos))
	validadas := make([]marcacaoValidada, len(body.Eventos))
	for i, item := range body.Eventos {
		v, err := validarMarcacaoOffline(item, agora)
		if err != nil {
			resultados[i] = ResultadoMarcacaoOffline{IdempotencyKey: item.IdempotencyKey, Estado: estadoRejeitado, Erro: err.Error()}
			continue
		}
		validadas[i] = v
		validas = append(validas, i)
	}
	sort.SliceStable(validas, func(a, b int) bool {
		return validadas[validas[a]].ocorridoEm.Before(validadas[validas[b]].ocorridoEm)
	})

	svc := assiduidade.NewService(h.db)
	metodoActivo := map[string]bool{}
	// Um PIN errado interrompe a verificação dos restantes PINs do lote: sem
	// isto, um lote de 100 marcações servia para tentar 100 PINs num só pedido.
	pinFalhou := false

	for _, i := range validas {
		v := validadas[i]
		res := ResultadoMarcacaoOffline{IdempotencyKey: v.item.IdempotencyKey}

		activo, visto := metodoActivo[v.cfg.ChaveConfig]
		if !visto {
			activo = svc.MetodoActivo(r.Context(), user.TenantID, v.cfg.ChaveConfig)
			metodoActivo[v.cfg.ChaveConfig] = activo
		}
		if !activo {
			res.Estado, res.Erro = estadoRejeitado, fmt.Sprintf("Marcação por '%s' desactivada para esta empresa", v.item.Metodo)
			resultados[i] = res
			continue
		}

		if v.cfg.RequerPIN {
			if pinFalhou {
				res.Estado, res.Erro = estadoRejeitado, "PIN não verificado: outro PIN do lote estava incorrecto"
				resultados[i] = res
				continue
			}
			switch h.verificarPIN(r, user.ID, v.item.PIN) {
			case pinNaoConfigurado:
				res.Estado, res.Erro = estadoRejeitado, "PIN não configurado — peça a RH para definir o seu PIN"
				resultados[i] = res
				continue
			case pinIncorrecto:
				pinFalhou = true
				res.Estado, res.Erro = estadoRejeitado, "PIN incorrecto"
				resultados[i] = res
				continue
			}
		}

		eventoID, duplicado, err := h.gravarMarcacaoOffline(r, user.TenantID, user.ID, colab.ID, v, agora)
		switch {
		case err != nil:
			res.Estado = estadoRejeitado
			if errors.Is(err, assiduidade.ErrTipoEventoDesconhecido) {
				res.Erro = err.Error()
			} else {
				res.Erro = "Erro ao registar o ponto"
			}
		case duplicado:
			res.Estado, res.EventoID = estadoDuplicado, eventoID
		default:
			res.Estado, res.EventoID = estadoRegistado, eventoID
		}
		resultados[i] = res
	}

	jsonOK(w, map[string]any{"resultados": resultados}, http.StatusOK)
}

// gravarMarcacaoOffline consome a idempotency_key e grava o evento na mesma
// transacção: ou ficam as duas coisas, ou nenhuma.
func (h *Handler) gravarMarcacaoOffline(
	r *http.Request,
	tenantID, userID, funcionarioID int64,
	v marcacaoValidada,
	sincronizadoEm time.Time,
) (eventoID *int64, duplicado bool, err error) {
	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		return nil, false, err
	}
	defer tx.Rollback(ctx)

	var inserido bool
	err = tx.QueryRow(ctx, `
		INSERT INTO rh.marcacoes_offline_sincronizadas (tenant_id, user_id, idempotency_key, ocorrido_em)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (tenant_id, user_id, idempotency_key) DO NOTHING
		RETURNING true`,
		tenantID, userID, v.item.IdempotencyKey, v.ocorridoEm).Scan(&inserido)
	if errors.Is(err, pgx.ErrNoRows) {
		var existente *int64
		if err := tx.QueryRow(ctx, `
			SELECT evento_id FROM rh.marcacoes_offline_sincronizadas
			 WHERE tenant_id = $1 AND user_id = $2 AND idempotency_key = $3`,
			tenantID, userID, v.item.IdempotencyKey).Scan(&existente); err != nil {
			return nil, false, err
		}
		return existente, true, nil
	}
	if err != nil {
		return nil, false, err
	}

	txSvc := assiduidade.NewServiceWithTx(tx)
	tipoEvento := v.item.TipoEventoCodigo
	if tipoEvento == "" {
		tipoEvento = txSvc.InferirEntradaOuSaida(ctx, tenantID, funcionarioID, v.ocorridoEm)
	}

	observacoes := observacoesOffline(v, sincronizadoEm)
	metodo := v.cfg.Codigo
	registadoPor := userID
	ip := ipDoPedido(r)
	ua := r.UserAgent()

	ev, err := txSvc.RegistarEvento(ctx, tenantID, assiduidade.RegistarEventoInput{
		FuncionarioID:    funcionarioID,
		TipoEventoCodigo: tipoEvento,
		MetodoCodigo:     &metodo,
		OcorridoEm:       v.ocorridoEm,
		Origem:           v.cfg.Origem,
		Latitude:         v.item.Latitude,
		Longitude:        v.item.Longitude,
		RegistadoPor:     &registadoPor,
		Observacoes:      &observacoes,
		IPOrigem:         &ip,
		UserAgent:        &ua,
	})
	if err != nil {
		return nil, false, err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE rh.marcacoes_offline_sincronizadas SET evento_id = $4
		 WHERE tenant_id = $1 AND user_id = $2 AND idempotency_key = $3`,
		tenantID, userID, v.item.IdempotencyKey, ev.ID); err != nil {
		return nil, false, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, false, err
	}
	return &ev.ID, false, nil
}

// observacoesOffline assinala o evento como vindo do lote offline, com a hora
// declarada pelo telemóvel e a hora real de chegada, para o RH poder comparar.
func observacoesOffline(v marcacaoValidada, sincronizadoEm time.Time) string {
	partes := []string{
		"offline",
		"registado_no_dispositivo=" + v.ocorridoEm.Format(time.RFC3339),
		"sincronizado_em=" + sincronizadoEm.Format(time.RFC3339),
	}
	if d := strings.TrimSpace(v.item.DeviceID); d != "" {
		partes = append(partes, "device_id="+d)
	}
	return strings.Join(partes, " | ")
}
