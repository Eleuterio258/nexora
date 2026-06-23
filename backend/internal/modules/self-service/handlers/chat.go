package handlers

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

type conversaRow struct {
	ID           int64      `json:"id"`
	Nome         *string    `json:"nome"`
	Tipo         string     `json:"tipo"`
	UltMensagem  *string    `json:"ultima_mensagem"`
	UltData      *time.Time `json:"ultima_data"`
	NaoLidas     int        `json:"nao_lidas"`
	Participantes []participanteRow `json:"participantes,omitempty"`
}

type participanteRow struct {
	UserID int64  `json:"user_id"`
	Nome   string `json:"nome"`
}

type mensagemRow struct {
	ID          int64     `json:"id"`
	AutorID     *int64    `json:"autor_id"`
	AutorNome   *string   `json:"autor_nome"`
	Conteudo    string    `json:"conteudo"`
	Tipo        string    `json:"tipo"`
	FicheiroURL *string   `json:"ficheiro_url"`
	CreatedAt   time.Time `json:"created_at"`
}

// ListarConversas lista as conversas do utilizador autenticado.
func (h *Handler) ListarConversas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT c.id, c.nome, c.tipo,
		       (SELECT conteudo FROM chat_mensagens m WHERE m.conversa_id=c.id AND NOT m.eliminada ORDER BY m.created_at DESC LIMIT 1) AS ult_msg,
		       (SELECT created_at FROM chat_mensagens m WHERE m.conversa_id=c.id AND NOT m.eliminada ORDER BY m.created_at DESC LIMIT 1) AS ult_data,
		       (SELECT COUNT(*) FROM chat_mensagens m
		           WHERE m.conversa_id=c.id AND NOT m.eliminada
		             AND m.created_at > COALESCE(p.ultima_leitura, '1970-01-01')) AS nao_lidas
		  FROM chat_conversas c
		  JOIN chat_participantes p ON p.conversa_id=c.id AND p.user_id=$1
		 WHERE c.tenant_id=$2
		 ORDER BY ult_data DESC NULLS LAST`, user.ID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []conversaRow{}
	for rows.Next() {
		var c conversaRow
		if rows.Scan(&c.ID, &c.Nome, &c.Tipo, &c.UltMensagem, &c.UltData, &c.NaoLidas) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// CriarConversa cria uma nova conversa (individual ou grupo).
func (h *Handler) CriarConversa(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Tipo         string  `json:"tipo"`
		Nome         *string `json:"nome"`
		Participantes []int64 `json:"participantes"`
	}
	if err := decodeJSON(r, &body); err != nil || len(body.Participantes) == 0 {
		jsonErr(w, "participantes é obrigatório", http.StatusBadRequest)
		return
	}
	if body.Tipo == "" {
		body.Tipo = "individual"
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var id int64
	if err := tx.QueryRow(r.Context(), `
		INSERT INTO chat_conversas (tenant_id, nome, tipo, criado_por)
		VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Nome, body.Tipo, user.ID).Scan(&id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Adicionar o criador
	tx.Exec(r.Context(), `INSERT INTO chat_participantes (conversa_id, user_id) VALUES ($1,$2)`, id, user.ID)
	for _, uid := range body.Participantes {
		if uid != user.ID {
			tx.Exec(r.Context(), `INSERT INTO chat_participantes (conversa_id, user_id) VALUES ($1,$2) ON CONFLICT DO NOTHING`, id, uid)
		}
	}

	tx.Commit(r.Context())
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ListarMensagens lista as mensagens de uma conversa.
func (h *Handler) ListarMensagens(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	conversaID := chi.URLParam(r, "id")

	// Verificar participação
	var participa bool
	h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM chat_participantes WHERE conversa_id=$1 AND user_id=$2)`,
		conversaID, user.ID).Scan(&participa)
	if !participa {
		jsonErr(w, "Sem acesso a esta conversa", http.StatusForbidden)
		return
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT m.id, m.autor_id, u.nome, m.conteudo, m.tipo, m.ficheiro_url, m.created_at
		  FROM chat_mensagens m
		  LEFT JOIN auth.users u ON u.id = m.autor_id
		 WHERE m.conversa_id=$1 AND NOT m.eliminada
		 ORDER BY m.created_at ASC LIMIT 100`, conversaID)
	if rows == nil {
		jsonOK(w, []mensagemRow{}, http.StatusOK)
		return
	}
	defer rows.Close()

	data := []mensagemRow{}
	for rows.Next() {
		var m mensagemRow
		if rows.Scan(&m.ID, &m.AutorID, &m.AutorNome, &m.Conteudo, &m.Tipo, &m.FicheiroURL, &m.CreatedAt) == nil {
			data = append(data, m)
		}
	}

	// Actualizar última leitura
	h.db.Exec(r.Context(), `
		UPDATE chat_participantes SET ultima_leitura=NOW()
		 WHERE conversa_id=$1 AND user_id=$2`, conversaID, user.ID)

	jsonOK(w, data, http.StatusOK)
}

// EnviarMensagem envia uma mensagem numa conversa.
func (h *Handler) EnviarMensagem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	conversaID := chi.URLParam(r, "id")

	var participa bool
	h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM chat_participantes WHERE conversa_id=$1 AND user_id=$2)`,
		conversaID, user.ID).Scan(&participa)
	if !participa {
		jsonErr(w, "Sem acesso a esta conversa", http.StatusForbidden)
		return
	}

	var body struct {
		Conteudo    string  `json:"conteudo"`
		Tipo        string  `json:"tipo"`
		FicheiroURL *string `json:"ficheiro_url"`
	}
	if err := decodeJSON(r, &body); err != nil || body.Conteudo == "" {
		jsonErr(w, "conteudo é obrigatório", http.StatusBadRequest)
		return
	}
	if body.Tipo == "" {
		body.Tipo = "texto"
	}

	var id int64
	if err := h.db.QueryRow(r.Context(), `
		INSERT INTO chat_mensagens (conversa_id, autor_id, conteudo, tipo, ficheiro_url)
		VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		conversaID, user.ID, body.Conteudo, body.Tipo, body.FicheiroURL).Scan(&id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}
