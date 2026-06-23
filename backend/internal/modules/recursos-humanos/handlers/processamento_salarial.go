package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ── Folhas de Pagamento (processamento salarial) ────────────────────────────

type folhaPagamentoRow struct {
	ID              int64      `json:"id"`
	Ano             int        `json:"ano"`
	Mes             int        `json:"mes"`
	Estado          string     `json:"estado"`
	NumFuncionarios int        `json:"num_funcionarios"`
	TotalProventos  *float64   `json:"total_proventos"`
	TotalDescontos  *float64   `json:"total_descontos"`
	TotalLiquido    *float64   `json:"total_liquido"`
	ProcessadaEm    *time.Time `json:"processada_em"`
	PagaEm          *time.Time `json:"paga_em"`
	CreatedAt       time.Time  `json:"created_at"`
}

func (h *Handler) ListarFolhasPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT id, ano, mes, estado, num_funcionarios, total_proventos, total_descontos, total_liquido, processada_em, paga_em, created_at
		  FROM folhas_pagamento
		 WHERE tenant_id=$1
		 ORDER BY ano DESC, mes DESC`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	podeVerSalarios := h.PodeVerSalarios(r)
	data := []folhaPagamentoRow{}
	for rows.Next() {
		var f folhaPagamentoRow
		var totalProventos, totalDescontos, totalLiquido float64
		if rows.Scan(&f.ID, &f.Ano, &f.Mes, &f.Estado, &f.NumFuncionarios, &totalProventos, &totalDescontos, &totalLiquido, &f.ProcessadaEm, &f.PagaEm, &f.CreatedAt) == nil {
			if podeVerSalarios {
				f.TotalProventos = &totalProventos
				f.TotalDescontos = &totalDescontos
				f.TotalLiquido = &totalLiquido
			}
			data = append(data, f)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body struct {
		Ano int `json:"ano"`
		Mes int `json:"mes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Ano < 2000 || body.Ano > 2100 || body.Mes < 1 || body.Mes > 12 {
		jsonErr(w, "ano e mes são obrigatórios e devem ser válidos", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO folhas_pagamento (tenant_id, ano, mes)
		VALUES ($1,$2,$3) RETURNING id`,
		user.TenantID, body.Ano, body.Mes).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe uma folha de pagamento para este mês/ano", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	podeVerSalarios := h.PodeVerSalarios(r)

	var f folhaPagamentoRow
	var totalProventos, totalDescontos, totalLiquido float64
	if err := h.db.QueryRow(r.Context(), `
		SELECT id, ano, mes, estado, num_funcionarios, total_proventos, total_descontos, total_liquido, processada_em, paga_em, created_at
		  FROM folhas_pagamento
		 WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(
		&f.ID, &f.Ano, &f.Mes, &f.Estado, &f.NumFuncionarios, &totalProventos, &totalDescontos, &totalLiquido, &f.ProcessadaEm, &f.PagaEm, &f.CreatedAt); err != nil {
		jsonErr(w, "Folha de pagamento não encontrada", http.StatusNotFound)
		return
	}
	if podeVerSalarios {
		f.TotalProventos = &totalProventos
		f.TotalDescontos = &totalDescontos
		f.TotalLiquido = &totalLiquido
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT rv.id, rv.funcionario_id, fu.nome_completo, fu.numero_funcionario, rv.salario_base, rv.total_proventos, rv.total_descontos, rv.salario_liquido, rv.estado
		  FROM recibos_vencimento rv
		  JOIN funcionarios fu ON fu.id = rv.funcionario_id
		 WHERE rv.folha_id=$1 AND rv.tenant_id=$2
		 ORDER BY fu.nome_completo`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type ReciboRow struct {
		ID                int64    `json:"id"`
		FuncionarioID     int64    `json:"funcionario_id"`
		NomeCompleto      string   `json:"nome_completo"`
		NumeroFuncionario *string  `json:"numero_funcionario"`
		SalarioBase       *float64 `json:"salario_base"`
		TotalProventos    *float64 `json:"total_proventos"`
		TotalDescontos    *float64 `json:"total_descontos"`
		SalarioLiquido    *float64 `json:"salario_liquido"`
		Estado            string   `json:"estado"`
	}
	recibos := []ReciboRow{}
	for rows.Next() {
		var rv ReciboRow
		var salarioBase, rvTotalProventos, rvTotalDescontos, salarioLiquido float64
		if rows.Scan(&rv.ID, &rv.FuncionarioID, &rv.NomeCompleto, &rv.NumeroFuncionario, &salarioBase, &rvTotalProventos, &rvTotalDescontos, &salarioLiquido, &rv.Estado) == nil {
			if podeVerSalarios {
				rv.SalarioBase = &salarioBase
				rv.TotalProventos = &rvTotalProventos
				rv.TotalDescontos = &rvTotalDescontos
				rv.SalarioLiquido = &salarioLiquido
			}
			recibos = append(recibos, rv)
		}
	}

	jsonOK(w, map[string]any{"folha": f, "recibos": recibos, "pode_ver_salarios": podeVerSalarios}, http.StatusOK)
}

func (h *Handler) ProcessarFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var estado string
	if err := tx.QueryRow(r.Context(), `SELECT estado FROM folhas_pagamento WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(&estado); err != nil {
		jsonErr(w, "Folha de pagamento não encontrada", http.StatusNotFound)
		return
	}
	if estado != "aberta" {
		jsonErr(w, "Apenas folhas em estado 'aberta' podem ser processadas", http.StatusConflict)
		return
	}

	funcRows, err := tx.Query(r.Context(), `
		SELECT id, COALESCE(salario_base,0) FROM funcionarios WHERE tenant_id=$1 AND estado='ativo'`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type funcionarioSalario struct {
		ID          int64
		SalarioBase float64
	}
	funcionarios := []funcionarioSalario{}
	for funcRows.Next() {
		var fs funcionarioSalario
		if funcRows.Scan(&fs.ID, &fs.SalarioBase) == nil {
			funcionarios = append(funcionarios, fs)
		}
	}
	funcRows.Close()

	if _, err := tx.Exec(r.Context(), `DELETE FROM recibos_vencimento WHERE folha_id=$1`, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	type componenteAtribuido struct {
		ComponenteID int64
		Nome         string
		Tipo         string
		FormaCalculo string
		Valor        float64
	}

	var totalProventosFolha, totalDescontosFolha, totalLiquidoFolha float64
	numFuncionarios := 0

	for _, fs := range funcionarios {
		compRows, err := tx.Query(r.Context(), `
			SELECT c.id, c.nome, c.tipo, c.forma_calculo, fc.valor
			  FROM funcionario_componentes_salariais fc
			  JOIN componentes_salariais c ON c.id = fc.componente_id
			 WHERE fc.funcionario_id=$1 AND fc.tenant_id=$2 AND c.ativo`, fs.ID, user.TenantID)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		componentes := []componenteAtribuido{}
		for compRows.Next() {
			var c componenteAtribuido
			if compRows.Scan(&c.ComponenteID, &c.Nome, &c.Tipo, &c.FormaCalculo, &c.Valor) == nil {
				componentes = append(componentes, c)
			}
		}
		compRows.Close()

		var totalProventos, totalDescontos float64
		type itemCalculado struct {
			ComponenteID int64
			Nome         string
			Tipo         string
			Valor        float64
		}
		itens := []itemCalculado{}
		for _, c := range componentes {
			valor := c.Valor
			if c.FormaCalculo == "percentual" {
				valor = fs.SalarioBase * c.Valor / 100
			}
			if c.Tipo == "provento" {
				totalProventos += valor
			} else {
				totalDescontos += valor
			}
			itens = append(itens, itemCalculado{ComponenteID: c.ComponenteID, Nome: c.Nome, Tipo: c.Tipo, Valor: valor})
		}
		salarioLiquido := fs.SalarioBase + totalProventos - totalDescontos

		var reciboID int64
		if err := tx.QueryRow(r.Context(), `
			INSERT INTO recibos_vencimento (tenant_id, folha_id, funcionario_id, salario_base, total_proventos, total_descontos, salario_liquido)
			VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
			user.TenantID, id, fs.ID, fs.SalarioBase, totalProventos, totalDescontos, salarioLiquido).Scan(&reciboID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}

		for _, it := range itens {
			if _, err := tx.Exec(r.Context(), `
				INSERT INTO recibo_vencimento_itens (recibo_id, componente_id, nome, tipo, valor)
				VALUES ($1,$2,$3,$4,$5)`,
				reciboID, it.ComponenteID, it.Nome, it.Tipo, it.Valor); err != nil {
				jsonErr(w, "Erro interno", http.StatusInternalServerError)
				return
			}
		}

		totalProventosFolha += totalProventos
		totalDescontosFolha += totalDescontos
		totalLiquidoFolha += salarioLiquido
		numFuncionarios++
	}

	if _, err := tx.Exec(r.Context(), `
		UPDATE folhas_pagamento SET
		  estado='processada', num_funcionarios=$1, total_proventos=$2, total_descontos=$3, total_liquido=$4,
		  processada_em=NOW(), processada_por=$5
		WHERE id=$6 AND tenant_id=$7`,
		numFuncionarios, totalProventosFolha, totalDescontosFolha, totalLiquidoFolha, user.ID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) PagarFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var estado string
	if err := tx.QueryRow(r.Context(), `SELECT estado FROM folhas_pagamento WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(&estado); err != nil {
		jsonErr(w, "Folha de pagamento não encontrada", http.StatusNotFound)
		return
	}
	if estado != "processada" {
		jsonErr(w, "Apenas folhas em estado 'processada' podem ser pagas", http.StatusConflict)
		return
	}

	if _, err := tx.Exec(r.Context(), `UPDATE folhas_pagamento SET estado='paga', paga_em=NOW() WHERE id=$1 AND tenant_id=$2`, id, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if _, err := tx.Exec(r.Context(), `UPDATE recibos_vencimento SET estado='pago' WHERE folha_id=$1 AND tenant_id=$2`, id, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CancelarFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `
		UPDATE folhas_pagamento SET estado='cancelada'
		 WHERE id=$1 AND tenant_id=$2 AND estado IN ('aberta','processada')`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Folha de pagamento não encontrada ou já paga/cancelada", http.StatusConflict)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ── Recibos de Vencimento ────────────────────────────────────────────────────

func (h *Handler) ListarRecibosVencimentoFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT rv.id, rv.folha_id, fp.ano, fp.mes, fp.estado, rv.salario_base, rv.total_proventos, rv.total_descontos, rv.salario_liquido, rv.estado, rv.created_at
		  FROM recibos_vencimento rv
		  JOIN folhas_pagamento fp ON fp.id = rv.folha_id
		 WHERE rv.funcionario_id=$1 AND rv.tenant_id=$2
		 ORDER BY fp.ano DESC, fp.mes DESC`, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID             int64     `json:"id"`
		FolhaID        int64     `json:"folha_id"`
		Ano            int       `json:"ano"`
		Mes            int       `json:"mes"`
		FolhaEstado    string    `json:"folha_estado"`
		SalarioBase    *float64  `json:"salario_base"`
		TotalProventos *float64  `json:"total_proventos"`
		TotalDescontos *float64  `json:"total_descontos"`
		SalarioLiquido *float64  `json:"salario_liquido"`
		Estado         string    `json:"estado"`
		CreatedAt      time.Time `json:"created_at"`
	}
	podeVerSalarios := h.PodeVerSalarios(r)
	data := []Row{}
	for rows.Next() {
		var rv Row
		var salarioBase, totalProventos, totalDescontos, salarioLiquido float64
		if rows.Scan(&rv.ID, &rv.FolhaID, &rv.Ano, &rv.Mes, &rv.FolhaEstado, &salarioBase, &totalProventos, &totalDescontos, &salarioLiquido, &rv.Estado, &rv.CreatedAt) == nil {
			if podeVerSalarios {
				rv.SalarioBase = &salarioBase
				rv.TotalProventos = &totalProventos
				rv.TotalDescontos = &totalDescontos
				rv.SalarioLiquido = &salarioLiquido
			}
			data = append(data, rv)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ObterReciboVencimento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var rv struct {
		ID                int64     `json:"id"`
		FolhaID           int64     `json:"folha_id"`
		Ano               int       `json:"ano"`
		Mes               int       `json:"mes"`
		FuncionarioID     int64     `json:"funcionario_id"`
		NomeCompleto      string    `json:"nome_completo"`
		NumeroFuncionario *string   `json:"numero_funcionario"`
		SalarioBase       *float64  `json:"salario_base"`
		TotalProventos    *float64  `json:"total_proventos"`
		TotalDescontos    *float64  `json:"total_descontos"`
		SalarioLiquido    *float64  `json:"salario_liquido"`
		Estado            string    `json:"estado"`
		CreatedAt         time.Time `json:"created_at"`
	}
	var salarioBase, totalProventos, totalDescontos, salarioLiquido float64
	if err := h.db.QueryRow(r.Context(), `
		SELECT rv.id, rv.folha_id, fp.ano, fp.mes, rv.funcionario_id, fu.nome_completo, fu.numero_funcionario,
		       rv.salario_base, rv.total_proventos, rv.total_descontos, rv.salario_liquido, rv.estado, rv.created_at
		  FROM recibos_vencimento rv
		  JOIN folhas_pagamento fp ON fp.id = rv.folha_id
		  JOIN funcionarios fu ON fu.id = rv.funcionario_id
		 WHERE rv.id=$1 AND rv.tenant_id=$2`, id, user.TenantID).Scan(
		&rv.ID, &rv.FolhaID, &rv.Ano, &rv.Mes, &rv.FuncionarioID, &rv.NomeCompleto, &rv.NumeroFuncionario,
		&salarioBase, &totalProventos, &totalDescontos, &salarioLiquido, &rv.Estado, &rv.CreatedAt); err != nil {
		jsonErr(w, "Recibo de vencimento não encontrado", http.StatusNotFound)
		return
	}

	podeVerSalarios := h.PodeVerSalarios(r)
	if podeVerSalarios {
		rv.SalarioBase = &salarioBase
		rv.TotalProventos = &totalProventos
		rv.TotalDescontos = &totalDescontos
		rv.SalarioLiquido = &salarioLiquido
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, componente_id, nome, tipo, valor FROM recibo_vencimento_itens WHERE recibo_id=$1 ORDER BY tipo, nome`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type ItemRow struct {
		ID           int64    `json:"id"`
		ComponenteID *int64   `json:"componente_id"`
		Nome         string   `json:"nome"`
		Tipo         string   `json:"tipo"`
		Valor        *float64 `json:"valor"`
	}
	itens := []ItemRow{}
	for rows.Next() {
		var it ItemRow
		var valor float64
		if rows.Scan(&it.ID, &it.ComponenteID, &it.Nome, &it.Tipo, &valor) == nil {
			if podeVerSalarios {
				it.Valor = &valor
			}
			itens = append(itens, it)
		}
	}

	jsonOK(w, map[string]any{"recibo": rv, "itens": itens, "pode_ver_salarios": podeVerSalarios}, http.StatusOK)
}
