package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// autorCandidato identifica, no campo "autor" de candidatura_notas, as
// mensagens escritas pelo próprio candidato — distingue-as das notas do
// recrutador/sistema sem precisar de alterar o CHECK constraint de "tipo"
// (que já aceita 'nota', reaproveitado aqui como mensagem de conversa).
const autorCandidato = "candidato"

type conversaCandidato struct {
	CandidaturaID  int64      `json:"candidatura_id"`
	VagaTitulo     string     `json:"vaga_titulo"`
	Estado         string     `json:"estado"`
	UltimoAutor    *string    `json:"ultimo_autor"`
	UltimaMensagem *string    `json:"ultima_mensagem"`
	UltimaData     *time.Time `json:"ultima_data"`
	NaoLidas       int        `json:"nao_lidas"`
}

// MinhasConversas lista, para o candidato autenticado, uma "conversa" por
// candidatura com a última mensagem e o número de mensagens do
// recrutador/sistema posteriores à última mensagem do próprio candidato.
func (h *Handler) MinhasConversas(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT c.id, c.vaga_titulo, c.estado,
		       u.autor, u.conteudo, u.created_at,
		       (SELECT COUNT(*) FROM recrutamento.candidatura_notas n
		          WHERE n.candidatura_id = c.id
		            AND n.autor <> $3
		            AND n.created_at > COALESCE(
		                (SELECT MAX(created_at) FROM recrutamento.candidatura_notas
		                  WHERE candidatura_id = c.id AND autor = $3),
		                'epoch'::timestamptz)) AS nao_lidas
		  FROM recrutamento.candidaturas c
		  LEFT JOIN LATERAL (
		      SELECT autor, conteudo, created_at
		        FROM recrutamento.candidatura_notas n
		       WHERE n.candidatura_id = c.id
		       ORDER BY n.created_at DESC
		       LIMIT 1
		  ) u ON TRUE
		 WHERE c.candidato_id = $1 AND c.tenant_id = $2
		 ORDER BY COALESCE(u.created_at, c.created_at) DESC`,
		c.ID, c.TenantID, autorCandidato)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []conversaCandidato{}
	for rows.Next() {
		var conv conversaCandidato
		if rows.Scan(&conv.CandidaturaID, &conv.VagaTitulo, &conv.Estado,
			&conv.UltimoAutor, &conv.UltimaMensagem, &conv.UltimaData, &conv.NaoLidas) == nil {
			data = append(data, conv)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// MensagensCandidatura lista o histórico de mensagens/notas de uma candidatura
// do candidato autenticado, em ordem cronológica (estilo conversa).
func (h *Handler) MensagensCandidatura(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)
	candidaturaID := h.decodeID(chi.URLParam(r, "id"))

	var pertence bool
	h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM recrutamento.candidaturas
		               WHERE id=$1 AND candidato_id=$2 AND tenant_id=$3)`,
		candidaturaID, c.ID, c.TenantID).Scan(&pertence)
	if !pertence {
		jsonErr(w, "Candidatura não encontrada", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, candidatura_id, autor, tipo, conteudo, created_at
		  FROM recrutamento.candidatura_notas
		 WHERE candidatura_id=$1
		 ORDER BY created_at ASC`, candidaturaID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []CandidaturaNota{}
	for rows.Next() {
		var n CandidaturaNota
		if rows.Scan(&n.ID, &n.CandidaturaID, &n.Autor, &n.Tipo, &n.Conteudo, &n.CreatedAt) == nil {
			data = append(data, n)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// EnviarMensagemCandidatura permite ao candidato responder numa candidatura.
func (h *Handler) EnviarMensagemCandidatura(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)
	candidaturaID := h.decodeID(chi.URLParam(r, "id"))

	var body struct {
		Conteudo string `json:"conteudo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	conteudo := strings.TrimSpace(body.Conteudo)
	if conteudo == "" {
		jsonErr(w, "O conteúdo da mensagem é obrigatório", http.StatusUnprocessableEntity)
		return
	}

	var pertence bool
	h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM recrutamento.candidaturas
		               WHERE id=$1 AND candidato_id=$2 AND tenant_id=$3)`,
		candidaturaID, c.ID, c.TenantID).Scan(&pertence)
	if !pertence {
		jsonErr(w, "Candidatura não encontrada", http.StatusNotFound)
		return
	}

	var nota CandidaturaNota
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO recrutamento.candidatura_notas (candidatura_id, autor, tipo, conteudo)
		VALUES ($1,$2,'nota',$3)
		RETURNING id, candidatura_id, autor, tipo, conteudo, created_at`,
		candidaturaID, autorCandidato, conteudo,
	).Scan(&nota.ID, &nota.CandidaturaID, &nota.Autor, &nota.Tipo, &nota.Conteudo, &nota.CreatedAt)
	if err != nil {
		jsonErr(w, "Erro ao enviar mensagem", http.StatusInternalServerError)
		return
	}
	h.realtime.EmitNovaMensagem(nota)
	jsonOK(w, nota, http.StatusCreated)
}
