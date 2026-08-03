package handlers

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
	"nexora/internal/storage"
)

// MarcarPontoRequest é o payload de POST /api/self-service/assiduidade/ponto.
//
// Não tem funcionario_id: o ponto é sempre do colaborador autenticado,
// resolvido a partir do JWT. Quem marca ponto em nome de outra pessoa usa
// POST /api/rh/eventos, protegido por recursos-humanos:gerir_funcionarios.
type MarcarPontoRequest struct {
	// metodo é a chave da configuração do tenant (rh.assiduidade.metodos).
	// Por omissão "pin".
	Metodo string `json:"metodo"`
	// PIN é obrigatório apenas quando metodo == "pin". A prova de presença
	// é verificada no mesmo pedido que grava o evento para não poder ser
	// saltada por um cliente modificado.
	PIN string `json:"pin"`
	// tipo_evento_codigo é opcional: sem ele, entrada/saída alternam pela
	// paridade dos eventos do dia (assiduidade.InferirEntradaOuSaida), que é
	// o comportamento de um único botão "marcar ponto" na app.
	TipoEventoCodigo string   `json:"tipo_evento_codigo"`
	Latitude         *float64 `json:"latitude"`
	Longitude        *float64 `json:"longitude"`
	LocalidadeID     *int64   `json:"localidade_id"`
	Observacoes      *string  `json:"observacoes"`
	// Dados extra trazidos pelo método escolhido (ex.: qr_code, nfc_tag_id,
	// image_base64). A prova facial é validada e consumida pelo ERP no mesmo
	// pedido; os restantes dados ficam em observações para auditoria.
	Dados map[string]any `json:"dados"`
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

// metodoSelfService descreve como um método vindo da app é mapeado para o
// catálogo rh.metodos_marcacao e para a coluna origem.
type metodoSelfService struct {
	ChaveConfig string // chave usada em rh.assiduidade.configuracao.metodos
	Codigo      string // codigo em rh.metodos_marcacao
	Origem      string // valor da coluna origem (limitado pelo CHECK)
	RequerPIN   bool
}

// metodosSelfService mapeia os valores de "metodo" que a app envia para os
// códigos internos do ERP. Deve estar sincronizado com AttendanceMethod no
// Flutter (nexora/lib/features/attendance/domain/entities/attendance_method.dart).
//
// O método "manual" foi propositadamente excluído: marcações manuais são
// operações de gestor/RH e devem usar POST /api/rh/assiduidade/ponto.
var metodosSelfService = map[string]metodoSelfService{
	"pin":         {ChaveConfig: "pin", Codigo: "pin", Origem: "app", RequerPIN: true},
	"qr_code":     {ChaveConfig: "qr_code", Codigo: "qr", Origem: "qr", RequerPIN: false},
	"nfc":         {ChaveConfig: "nfc", Codigo: "nfc", Origem: "nfc", RequerPIN: false},
	"selfie_gps":  {ChaveConfig: "selfie", Codigo: "selfie", Origem: "selfie", RequerPIN: false},
	"selfie":      {ChaveConfig: "selfie", Codigo: "selfie", Origem: "selfie", RequerPIN: false},
	"facial":      {ChaveConfig: "facial", Codigo: "reconhecimento_facial", Origem: "reconhecimento_facial", RequerPIN: false},
	"fingerprint": {ChaveConfig: "fingerprint", Codigo: "impressao_digital", Origem: "impressao_digital", RequerPIN: false},
}

// MarcarPonto regista o ponto do próprio colaborador autenticado por JWT.
//
// O PIN, quando usado, é verificado aqui, e não delegado a
// POST /api/authcode/pin/verify, porque esse endpoint só devolve um veredicto
// ao cliente: um cliente modificado saltava-o e marcava o ponto na mesma. A
// prova de presença tem de acontecer no mesmo pedido que grava o evento.
//
// Facial exige um comprovativo assinado e de uso único emitido pelo FaceClock.
// QR e NFC são validados contra os registos activos do tenant. Os restantes
// métodos mantêm as provas específicas documentadas em cada bloco abaixo.
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

	cfg, ok := metodosSelfService[body.Metodo]
	if !ok {
		jsonErr(w, fmt.Sprintf("Método de marcação '%s' não suportado", body.Metodo), http.StatusBadRequest)
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
	if !svc.MetodoActivo(r.Context(), user.TenantID, cfg.ChaveConfig) {
		jsonErr(w, fmt.Sprintf("Marcação por '%s' desactivada para esta empresa", body.Metodo), http.StatusForbidden)
		return
	}

	// O contrato móvel agrupa as provas do método em `dados`. Promover as
	// coordenadas para os campos persistidos e transformar a data URL da
	// selfie numa URL real do storage antes de criar o evento.
	if body.Latitude == nil {
		if latitude, ok := body.Dados["latitude"].(float64); ok {
			body.Latitude = &latitude
		}
	}
	if body.Longitude == nil {
		if longitude, ok := body.Dados["longitude"].(float64); ok {
			body.Longitude = &longitude
		}
	}

	var fotoURL *string
	if rawFoto, ok := body.Dados["foto_url"].(string); ok && rawFoto != "" {
		foto, err := h.prepararFotoSelfie(r.Context(), user.TenantID, user.ID, rawFoto)
		if err != nil {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		fotoURL = &foto
		body.Dados["foto_url"] = foto
	}
	if cfg.ChaveConfig == "selfie" {
		if body.Latitude == nil || body.Longitude == nil {
			jsonErr(w, "latitude e longitude são obrigatórias para selfie", http.StatusBadRequest)
			return
		}
		if fotoURL == nil {
			jsonErr(w, "foto_url é obrigatória para selfie", http.StatusBadRequest)
			return
		}
	}

	var qrTokenID *int64
	var qrLocationID *string
	var nfcTagID *int64

	if body.Metodo == "nfc" {
		tagUID, _ := body.Dados["nfc_tag_id"].(string)
		tagUID = strings.ToUpper(strings.TrimSpace(tagUID))
		if tagUID == "" {
			jsonErr(w, "nfc_tag_id é obrigatório para marcação por NFC", http.StatusBadRequest)
			return
		}

		var id int64
		err := h.db.QueryRow(r.Context(), `
			SELECT id
			  FROM rh.nfc_tags
			 WHERE tenant_id=$1 AND funcionario_id=$2
			   AND UPPER(tag_uid)=$3 AND activo=true`,
			user.TenantID, colab.ID, tagUID).Scan(&id)
		if errors.Is(err, pgx.ErrNoRows) {
			jsonErr(w, "Cartão NFC inválido ou não associado ao funcionário", http.StatusBadRequest)
			return
		}
		if err != nil {
			jsonErr(w, "Erro ao validar o cartão NFC", http.StatusInternalServerError)
			return
		}
		nfcTagID = &id
		body.Dados["nfc_tag_id"] = tagUID
	}

	if body.Metodo == "qr_code" {
		qrCode, _ := body.Dados["qr_code"].(string)
		if qrCode == "" {
			jsonErr(w, "qr_code é obrigatório para marcação por QR", http.StatusBadRequest)
			return
		}

		qr, err := svc.ValidarEUsarQRToken(r.Context(), user.TenantID, qrCode)
		if err != nil {
			switch {
			case errors.Is(err, assiduidade.ErrQRExpirado):
				jsonErr(w, "QR Code expirado", http.StatusBadRequest)
			case errors.Is(err, assiduidade.ErrQRUsado):
				jsonErr(w, "QR Code já utilizado", http.StatusBadRequest)
			default:
				jsonErr(w, "QR Code inválido", http.StatusBadRequest)
			}
			return
		}
		if qr.FuncionarioID != nil {
			jsonErr(w, "QR Code pessoal não pode ser usado para marcação por terminal", http.StatusBadRequest)
			return
		}

		qrTokenID = &qr.TokenID
		qrLocationID = qr.LocationID
	}

	if cfg.RequerPIN {
		if body.PIN == "" {
			jsonErr(w, "pin é obrigatório", http.StatusBadRequest)
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
	}

	// Sem limite ao número de marcações do dia: cada toque é um facto que fica
	// gravado, e o emparelhamento é feito no fim por assiduidade.RecalcularDia
	// (agruparPorTipoPar), que junta entrada→saída por ordem cronológica e
	// ignora o que não fecha par. Recusar marcações próximas aqui só perderia
	// eventos reais — várias saídas e regressos no mesmo dia são normais.
	if body.Metodo == "facial" {
		verificationToken, _ := body.Dados["verification_token"].(string)
		clientDeviceID, _ := body.Dados["device_id"].(string)
		claims, err := h.consumeFacialVerification(
			r.Context(), verificationToken, user.ID, user.TenantID, clientDeviceID,
		)
		if err != nil {
			switch {
			case errors.Is(err, errFacialProofMissing):
				jsonErr(w, "verification_token e device_id sao obrigatorios para marcacao facial", http.StatusBadRequest)
			case errors.Is(err, errFacialProofUsed):
				jsonErr(w, "Comprovativo facial ja utilizado", http.StatusConflict)
			case errors.Is(err, errFacialProofInvalid):
				jsonErr(w, "Comprovativo facial invalido ou expirado", http.StatusForbidden)
			default:
				jsonErr(w, "Erro ao validar comprovativo facial", http.StatusInternalServerError)
			}
			return
		}
		// Nao persistir o JWT em observacoes. Somente os scores autenticados.
		delete(body.Dados, "verification_token")
		body.Dados["device_id"] = clientDeviceID
		body.Dados["confidence_score"] = claims.ConfidenceScore
		body.Dados["liveness_score"] = claims.LivenessScore
	}

	agora := time.Now()

	tipoEvento := body.TipoEventoCodigo
	if tipoEvento == "" {
		tipoEvento = svc.InferirEntradaOuSaida(r.Context(), user.TenantID, colab.ID, agora)
	}

	origem := cfg.Origem
	metodo := cfg.Codigo
	registadoPor := user.ID
	ip := ipDoPedido(r)
	ua := r.UserAgent()
	observacoes := body.Observacoes
	if len(body.Dados) > 0 || qrLocationID != nil {
		extras := []string{}
		if len(body.Dados) > 0 {
			extras = append(extras, fmt.Sprintf("dados=%+v", body.Dados))
		}
		if qrLocationID != nil && *qrLocationID != "" {
			extras = append(extras, fmt.Sprintf("location_id=%s", *qrLocationID))
		}
		merged := ""
		if observacoes != nil && *observacoes != "" {
			merged = *observacoes + " | "
		}
		merged += extras[0]
		for i := 1; i < len(extras); i++ {
			merged += " | " + extras[i]
		}
		observacoes = &merged
	}

	ev, err := svc.RegistarEvento(r.Context(), user.TenantID, assiduidade.RegistarEventoInput{
		FuncionarioID:    colab.ID,
		TipoEventoCodigo: tipoEvento,
		MetodoCodigo:     &metodo,
		OcorridoEm:       agora,
		Origem:           origem,
		QRTokenID:        qrTokenID,
		NFCTagID:         nfcTagID,
		Latitude:         body.Latitude,
		Longitude:        body.Longitude,
		LocalidadeID:     body.LocalidadeID,
		FotoURL:          fotoURL,
		RegistadoPor:     &registadoPor,
		Observacoes:      observacoes,
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

const maxSelfieBytes = 5 << 20

// prepararFotoSelfie aceita uma URL HTTPS já publicada ou uma data URL
// JPEG/PNG enviada pela app. A segunda opção é guardada no provider configurado
// e substituída pela URL pública devolvida pelo storage.
func (h *Handler) prepararFotoSelfie(ctx context.Context, tenantID, userID int64, raw string) (string, error) {
	raw = strings.TrimSpace(raw)
	if strings.HasPrefix(raw, "https://") || strings.HasPrefix(raw, "http://") {
		parsed, err := url.ParseRequestURI(raw)
		if err != nil || parsed.Host == "" {
			return "", errors.New("foto_url inválida")
		}
		return raw, nil
	}

	contentType := "image/jpeg"
	ext := ".jpg"
	prefix := "data:image/jpeg;base64,"
	if strings.HasPrefix(raw, "data:image/png;base64,") {
		contentType = "image/png"
		ext = ".png"
		prefix = "data:image/png;base64,"
	}
	if !strings.HasPrefix(raw, prefix) {
		return "", errors.New("foto_url deve ser uma URL HTTP(S) ou imagem JPEG/PNG")
	}

	encoded := strings.TrimPrefix(raw, prefix)
	if len(encoded) > (maxSelfieBytes*4/3)+4 {
		return "", errors.New("selfie excede o limite de 5 MB")
	}
	data, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil || len(data) == 0 {
		return "", errors.New("selfie inválida")
	}
	if len(data) > maxSelfieBytes {
		return "", errors.New("selfie excede o limite de 5 MB")
	}
	if detected := http.DetectContentType(data); detected != contentType {
		return "", errors.New("conteúdo da selfie inválido")
	}

	digest := sha256.Sum256(data)
	key := storage.JoinPath(
		"uploads",
		fmt.Sprintf("tenant-%d", tenantID),
		"assiduidade",
		"selfies",
		fmt.Sprintf("%d-%x%s", userID, digest[:12], ext),
	)
	storedURL, err := h.storage.Put(ctx, key, data, contentType)
	if err != nil {
		return "", errors.New("não foi possível guardar a selfie")
	}
	return storedURL, nil
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
