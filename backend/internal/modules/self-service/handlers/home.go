package handlers

import (
	"net/http"
	"time"

	mw "nexora/internal/middleware"
)

// Home devolve o agregado do ecrã inicial do colaborador.
func (h *Handler) Home(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	ctx  := r.Context()

	funcID, temFunc := h.funcionarioID(r)

	// ── Saldo de férias ───────────────────────────────────────────────────────
	type saldoFerias struct {
		DiasAtribuidos float64 `json:"dias_atribuidos"`
		DiasUsados     float64 `json:"dias_usados"`
		DiasDisponiveis float64 `json:"dias_disponiveis"`
	}
	var sf saldoFerias
	if temFunc {
		h.db.QueryRow(ctx, `
			SELECT COALESCE(SUM(s.dias_atribuidos),0), COALESCE(SUM(s.dias_usados),0)
			  FROM rh.saldos_ausencia s
			  JOIN tipos_ausencia ta ON ta.id = s.tipo_ausencia_id
			 WHERE s.funcionario_id=$1 AND s.ano=$2 AND ta.afeta_saldo`,
			funcID, time.Now().Year()).Scan(&sf.DiasAtribuidos, &sf.DiasUsados)
		sf.DiasDisponiveis = sf.DiasAtribuidos - sf.DiasUsados
	}

	// ── Assiduidade do mês ────────────────────────────────────────────────────
	type resumoMes struct {
		DiasTrabalhados int     `json:"dias_trabalhados"`
		HorasTotais     float64 `json:"horas_totais"`
		Atrasos         int     `json:"atrasos"`
		Faltas          int     `json:"faltas"`
	}
	var rm resumoMes
	if temFunc {
		agora := time.Now()
		h.db.QueryRow(ctx, `
			SELECT
			  COUNT(DISTINCT data)                                                                AS dias,
			  COALESCE(SUM(CASE WHEN hora_entrada IS NOT NULL AND hora_saida IS NOT NULL
			                    THEN EXTRACT(EPOCH FROM (hora_saida::time - hora_entrada::time))/3600
			                    ELSE COALESCE(horas_extra,0) END),0)                             AS horas,
			  COUNT(*) FILTER (WHERE tipo='atraso')                                              AS atrasos,
			  COUNT(*) FILTER (WHERE tipo='falta')                                               AS faltas
			FROM rh.presencas
			WHERE funcionario_id=$1 AND tenant_id=$2
			  AND EXTRACT(YEAR FROM data)=$3 AND EXTRACT(MONTH FROM data)=$4`,
			funcID, user.TenantID, agora.Year(), int(agora.Month())).
			Scan(&rm.DiasTrabalhados, &rm.HorasTotais, &rm.Atrasos, &rm.Faltas)
	}

	// ── Pedidos pendentes ─────────────────────────────────────────────────────
	var pedidosPendentes int
	if temFunc {
		h.db.QueryRow(ctx, `
			SELECT COUNT(*) FROM ausencias
			WHERE funcionario_id=$1 AND tenant_id=$2 AND estado='pendente'`,
			funcID, user.TenantID).Scan(&pedidosPendentes)
	}

	// ── Notificações não lidas ────────────────────────────────────────────────
	type notif struct {
		ID        int64     `json:"id"`
		Tipo      string    `json:"tipo"`
		Titulo    string    `json:"titulo"`
		Corpo     *string   `json:"corpo"`
		Link      *string   `json:"link"`
		CreatedAt time.Time `json:"created_at"`
	}
	notifs := []notif{}
	rows, _ := h.db.Query(ctx, `
		SELECT id, tipo, titulo, corpo, link, created_at
		  FROM notif_colaborador
		 WHERE user_id=$1 AND NOT lida
		 ORDER BY created_at DESC LIMIT 10`, user.ID)
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var n notif
			if rows.Scan(&n.ID, &n.Tipo, &n.Titulo, &n.Corpo, &n.Link, &n.CreatedAt) == nil {
				notifs = append(notifs, n)
			}
		}
	}

	// ── Comunicados recentes ──────────────────────────────────────────────────
	type comunicado struct {
		ID        int64     `json:"id"`
		Titulo    string    `json:"titulo"`
		CreatedAt time.Time `json:"created_at"`
		Lido      bool      `json:"lido"`
	}
	comunicados := []comunicado{}
	rows2, _ := h.db.Query(ctx, `
		SELECT c.id, c.titulo, c.created_at,
		       EXISTS(SELECT 1 FROM comunicados_lidos cl WHERE cl.comunicado_id=c.id AND cl.user_id=$1) AS lido
		  FROM comunicados c
		 WHERE c.tenant_id=$2
		   AND (c.expira_em IS NULL OR c.expira_em > NOW())
		 ORDER BY c.created_at DESC LIMIT 5`, user.ID, user.TenantID)
	if rows2 != nil {
		defer rows2.Close()
		for rows2.Next() {
			var c comunicado
			if rows2.Scan(&c.ID, &c.Titulo, &c.CreatedAt, &c.Lido) == nil {
				comunicados = append(comunicados, c)
			}
		}
	}

	// ── Aniversários da semana ────────────────────────────────────────────────
	type aniversario struct {
		Nome string `json:"nome"`
		Dia  int    `json:"dia"`
		Mes  int    `json:"mes"`
	}
	aniversarios := []aniversario{}
	if temFunc {
		rows3, _ := h.db.Query(ctx, `
			SELECT nome_completo,
			       EXTRACT(DAY FROM data_nascimento)::int,
			       EXTRACT(MONTH FROM data_nascimento)::int
			  FROM rh.funcionarios
			 WHERE tenant_id=$1 AND data_nascimento IS NOT NULL
			   AND EXTRACT(MONTH FROM data_nascimento) = EXTRACT(MONTH FROM NOW())
			   AND ABS(EXTRACT(DAY FROM data_nascimento) - EXTRACT(DAY FROM NOW())) <= 7
			 ORDER BY EXTRACT(DAY FROM data_nascimento)`,
			user.TenantID)
		if rows3 != nil {
			defer rows3.Close()
			for rows3.Next() {
				var a aniversario
				if rows3.Scan(&a.Nome, &a.Dia, &a.Mes) == nil {
					aniversarios = append(aniversarios, a)
				}
			}
		}
	}

	jsonOK(w, map[string]any{
		"saldo_ferias":       sf,
		"assiduidade_mes":    rm,
		"pedidos_pendentes":  pedidosPendentes,
		"notificacoes":       notifs,
		"comunicados":        comunicados,
		"aniversarios":       aniversarios,
	}, http.StatusOK)
}

// MarcarNotificacaoLida marca uma notificação como lida.
func (h *Handler) MarcarNotificacaoLida(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ID int64 `json:"id"`
	}
	if err := decodeJSON(r, &body); err != nil || body.ID == 0 {
		jsonErr(w, "id inválido", http.StatusBadRequest)
		return
	}
	h.db.Exec(r.Context(), `
		UPDATE notif_colaborador SET lida=TRUE
		 WHERE id=$1 AND user_id=$2`, body.ID, user.ID)
	w.WriteHeader(http.StatusNoContent)
}

// ComunicadoMarcarLido regista a leitura de um comunicado.
func (h *Handler) ComunicadoMarcarLido(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ID int64 `json:"id"`
	}
	if err := decodeJSON(r, &body); err != nil || body.ID == 0 {
		jsonErr(w, "id inválido", http.StatusBadRequest)
		return
	}
	h.db.Exec(r.Context(), `
		INSERT INTO comunicados_lidos (comunicado_id, user_id) VALUES ($1,$2)
		ON CONFLICT DO NOTHING`, body.ID, user.ID)
	w.WriteHeader(http.StatusNoContent)
}
