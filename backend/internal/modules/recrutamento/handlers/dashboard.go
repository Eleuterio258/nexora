package handlers

import (
	"math"
	"net/http"
	"time"

	mw "nexora/internal/middleware"
)

type candidaturaRecente struct {
	ID         int64     `json:"id"`
	Nome       string    `json:"nome"`
	Email      string    `json:"email"`
	VagaTitulo string    `json:"vaga_titulo"`
	Estado     string    `json:"estado"`
	CreatedAt  time.Time `json:"created_at"`
}

type prazoProximo struct {
	ID     int64  `json:"id"`
	Titulo string `json:"titulo"`
	Area   string `json:"area"`
	Prazo  string `json:"prazo"`
	Dias   int    `json:"dias"`
}

// Dashboard devolve os indicadores apresentados em admin/index.php, adaptados a Postgres.
func (h *Handler) Dashboard(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	ctx := r.Context()

	var totalVagas, vagasAtivas, totalCandidaturas, candidaturasHoje int
	h.db.QueryRow(ctx, "SELECT COUNT(*) FROM vagas WHERE tenant_id=$1", user.TenantID).Scan(&totalVagas)
	h.db.QueryRow(ctx, "SELECT COUNT(*) FROM vagas WHERE tenant_id=$1 AND ativa=TRUE", user.TenantID).Scan(&vagasAtivas)
	h.db.QueryRow(ctx, "SELECT COUNT(*) FROM candidaturas WHERE tenant_id=$1", user.TenantID).Scan(&totalCandidaturas)
	h.db.QueryRow(ctx, "SELECT COUNT(*) FROM candidaturas WHERE tenant_id=$1 AND created_at::date = CURRENT_DATE", user.TenantID).Scan(&candidaturasHoje)

	funil := map[string]int{
		"recebida":   0,
		"em_analise": 0,
		"entrevista": 0,
		"aprovada":   0,
		"rejeitada":  0,
	}
	if rows, err := h.db.Query(ctx, "SELECT estado, COUNT(*) FROM candidaturas WHERE tenant_id=$1 GROUP BY estado", user.TenantID); err == nil {
		for rows.Next() {
			var estado string
			var count int
			if rows.Scan(&estado, &count) == nil {
				funil[estado] = count
			}
		}
		rows.Close()
	}

	taxaAprovacao := 0.0
	if totalCandidaturas > 0 {
		taxaAprovacao = math.Round(float64(funil["aprovada"])/float64(totalCandidaturas)*1000) / 10
	}

	recentes := []candidaturaRecente{}
	if rows, err := h.db.Query(ctx,
		`SELECT id, nome, email, vaga_titulo, estado, created_at FROM candidaturas
		 WHERE tenant_id=$1 ORDER BY created_at DESC LIMIT 8`, user.TenantID); err == nil {
		for rows.Next() {
			var c candidaturaRecente
			if rows.Scan(&c.ID, &c.Nome, &c.Email, &c.VagaTitulo, &c.Estado, &c.CreatedAt) == nil {
				recentes = append(recentes, c)
			}
		}
		rows.Close()
	}

	prazosProximos := []prazoProximo{}
	if rows, err := h.db.Query(ctx,
		`SELECT id, titulo, area, to_char(prazo, 'YYYY-MM-DD'), (prazo - CURRENT_DATE)::int AS dias
		 FROM vagas
		 WHERE tenant_id=$1 AND ativa=TRUE AND prazo IS NOT NULL
		   AND prazo >= CURRENT_DATE AND prazo <= CURRENT_DATE + 7
		 ORDER BY prazo ASC`, user.TenantID); err == nil {
		for rows.Next() {
			var p prazoProximo
			if rows.Scan(&p.ID, &p.Titulo, &p.Area, &p.Prazo, &p.Dias) == nil {
				prazosProximos = append(prazosProximos, p)
			}
		}
		rows.Close()
	}

	jsonOK(w, map[string]any{
		"total_vagas":        totalVagas,
		"vagas_ativas":       vagasAtivas,
		"total_candidaturas": totalCandidaturas,
		"candidaturas_hoje":  candidaturasHoje,
		"funil":              funil,
		"taxa_aprovacao":     taxaAprovacao,
		"recentes":           recentes,
		"prazos_proximos":    prazosProximos,
	}, http.StatusOK)
}
