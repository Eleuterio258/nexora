package handlers

import (
	"net/http"

	mw "nexora/internal/middleware"
)

type rhEstadoCount struct {
	Estado string `json:"estado"`
	Total  int    `json:"total"`
}

type rhNomeCount struct {
	Nome  string `json:"nome"`
	Total int    `json:"total"`
}

type rhFolhaResumo struct {
	Ano            int      `json:"ano"`
	Mes            int      `json:"mes"`
	TotalProventos *float64 `json:"total_proventos"`
	TotalDescontos *float64 `json:"total_descontos"`
	TotalLiquido   *float64 `json:"total_liquido"`
	Estado         string   `json:"estado"`
}

type rhAbsentismoResumo struct {
	Tipo  string  `json:"tipo"`
	Total int     `json:"total"`
	Dias  float64 `json:"dias"`
}

type rhAvaliacaoResumo struct {
	Periodo        string  `json:"periodo"`
	Total          int     `json:"total"`
	MediaPontuacao float64 `json:"media_pontuacao"`
}

// RelatoriosRH devolve indicadores agregados de RH (efectivo, massa salarial,
// absentismo, processos disciplinares, avaliações e formações).
func (h *Handler) RelatoriosRH(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	ctx := r.Context()

	var totalFuncionarios int
	h.db.QueryRow(ctx, `SELECT COUNT(*) FROM funcionarios WHERE tenant_id=$1`, user.TenantID).Scan(&totalFuncionarios)

	porEstado := []rhEstadoCount{}
	if rows, err := h.db.Query(ctx, `
		SELECT estado, COUNT(*) FROM funcionarios WHERE tenant_id=$1 GROUP BY estado ORDER BY estado`, user.TenantID); err == nil {
		for rows.Next() {
			var c rhEstadoCount
			if rows.Scan(&c.Estado, &c.Total) == nil {
				porEstado = append(porEstado, c)
			}
		}
		rows.Close()
	}

	porUnidade := []rhNomeCount{}
	if rows, err := h.db.Query(ctx, `
		SELECT COALESCE(u.nome, 'Sem Unidade'), COUNT(*)
		  FROM funcionarios f
		  LEFT JOIN unidades_organizacionais u ON u.id = f.unit_id
		 WHERE f.tenant_id=$1
		 GROUP BY COALESCE(u.nome, 'Sem Unidade')
		 ORDER BY 2 DESC, 1`, user.TenantID); err == nil {
		for rows.Next() {
			var c rhNomeCount
			if rows.Scan(&c.Nome, &c.Total) == nil {
				porUnidade = append(porUnidade, c)
			}
		}
		rows.Close()
	}

	porCargo := []rhNomeCount{}
	if rows, err := h.db.Query(ctx, `
		SELECT COALESCE(c.nome, 'Sem Cargo'), COUNT(*)
		  FROM funcionarios f
		  LEFT JOIN cargos c ON c.id = f.cargo_id
		 WHERE f.tenant_id=$1
		 GROUP BY COALESCE(c.nome, 'Sem Cargo')
		 ORDER BY 2 DESC, 1`, user.TenantID); err == nil {
		for rows.Next() {
			var c rhNomeCount
			if rows.Scan(&c.Nome, &c.Total) == nil {
				porCargo = append(porCargo, c)
			}
		}
		rows.Close()
	}

	podeVerSalarios := h.PodeVerSalarios(r)

	massaSalarial := []rhFolhaResumo{}
	if rows, err := h.db.Query(ctx, `
		SELECT ano, mes, total_proventos, total_descontos, total_liquido, estado
		  FROM folhas_pagamento
		 WHERE tenant_id=$1
		 ORDER BY ano DESC, mes DESC LIMIT 12`, user.TenantID); err == nil {
		for rows.Next() {
			var f rhFolhaResumo
			var totalProventos, totalDescontos, totalLiquido float64
			if rows.Scan(&f.Ano, &f.Mes, &totalProventos, &totalDescontos, &totalLiquido, &f.Estado) == nil {
				if podeVerSalarios {
					f.TotalProventos = &totalProventos
					f.TotalDescontos = &totalDescontos
					f.TotalLiquido = &totalLiquido
				}
				massaSalarial = append(massaSalarial, f)
			}
		}
		rows.Close()
	}
	for i, j := 0, len(massaSalarial)-1; i < j; i, j = i+1, j-1 {
		massaSalarial[i], massaSalarial[j] = massaSalarial[j], massaSalarial[i]
	}

	absentismo := []rhAbsentismoResumo{}
	if rows, err := h.db.Query(ctx, `
		SELECT COALESCE(t.nome, a.tipo, 'Outro'), COUNT(*), COALESCE(SUM(a.dias),0)
		  FROM ausencias a
		  LEFT JOIN tipos_ausencia t ON t.id = a.tipo_id
		 WHERE a.tenant_id=$1 AND a.estado IN ('aprovado','gozada')
		 GROUP BY COALESCE(t.nome, a.tipo, 'Outro')
		 ORDER BY 3 DESC`, user.TenantID); err == nil {
		for rows.Next() {
			var ab rhAbsentismoResumo
			if rows.Scan(&ab.Tipo, &ab.Total, &ab.Dias) == nil {
				absentismo = append(absentismo, ab)
			}
		}
		rows.Close()
	}

	processosDisciplinares := map[string]int{
		"aberto":     0,
		"em_analise": 0,
		"decidido":   0,
		"arquivado":  0,
	}
	if rows, err := h.db.Query(ctx, `
		SELECT estado, COUNT(*) FROM processos_disciplinares WHERE tenant_id=$1 GROUP BY estado`, user.TenantID); err == nil {
		for rows.Next() {
			var estado string
			var total int
			if rows.Scan(&estado, &total) == nil {
				processosDisciplinares[estado] = total
			}
		}
		rows.Close()
	}

	avaliacoes := []rhAvaliacaoResumo{}
	if rows, err := h.db.Query(ctx, `
		SELECT COALESCE(p.nome, 'Sem Período'), COUNT(*), COALESCE(AVG(av.pontuacao),0)
		  FROM avaliacoes av
		  LEFT JOIN periodos_avaliacao p ON p.id = av.periodo_id
		 WHERE av.tenant_id=$1
		 GROUP BY COALESCE(p.nome, 'Sem Período'), p.data_inicio
		 ORDER BY p.data_inicio DESC NULLS LAST`, user.TenantID); err == nil {
		for rows.Next() {
			var av rhAvaliacaoResumo
			if rows.Scan(&av.Periodo, &av.Total, &av.MediaPontuacao) == nil {
				avaliacoes = append(avaliacoes, av)
			}
		}
		rows.Close()
	}

	formacoes := map[string]int{
		"planeada":  0,
		"em_curso":  0,
		"concluida": 0,
		"cancelada": 0,
	}
	if rows, err := h.db.Query(ctx, `
		SELECT estado, COUNT(*) FROM funcionario_formacoes WHERE tenant_id=$1 GROUP BY estado`, user.TenantID); err == nil {
		for rows.Next() {
			var estado string
			var total int
			if rows.Scan(&estado, &total) == nil {
				formacoes[estado] = total
			}
		}
		rows.Close()
	}

	jsonOK(w, map[string]any{
		"total_funcionarios":      totalFuncionarios,
		"por_estado":              porEstado,
		"por_unidade":             porUnidade,
		"por_cargo":               porCargo,
		"massa_salarial":          massaSalarial,
		"absentismo":              absentismo,
		"processos_disciplinares": processosDisciplinares,
		"avaliacoes":              avaliacoes,
		"formacoes":               formacoes,
		"pode_ver_salarios":       podeVerSalarios,
	}, http.StatusOK)
}
