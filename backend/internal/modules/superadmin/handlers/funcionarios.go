package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
)

var superadminTiposContrato = map[string]bool{
	"efetivo": true, "indeterminado": true, "termo_certo": true, "termo_incerto": true,
	"estagio": true, "prestacao_servico": true,
}

// CriarFuncionarioTenant cria um funcionário para qualquer tenant (acesso exclusivo superadmin).
func (h *Handler) CriarFuncionarioTenant(w http.ResponseWriter, r *http.Request) {
	tenantID, err := strconv.ParseInt(chi.URLParam(r, "tenantId"), 10, 64)
	if err != nil || tenantID <= 0 {
		jsonErr(w, "tenant inválido", http.StatusBadRequest)
		return
	}

	var existe bool
	if err := h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM saas.tenants WHERE id=$1)`, tenantID,
	).Scan(&existe); err != nil || !existe {
		jsonErr(w, "tenant não encontrado", http.StatusNotFound)
		return
	}

	var body struct {
		NumeroFuncionario *string  `json:"numero_funcionario"`
		NomeCompleto      string   `json:"nome_completo"`
		DataNascimento    *string  `json:"data_nascimento"`
		Genero            *string  `json:"genero"`
		Nuit              *string  `json:"nuit"`
		Telefone          *string  `json:"telefone"`
		Email             *string  `json:"email"`
		Endereco          *string  `json:"endereco"`
		Cargo             *string  `json:"cargo"`
		DataAdmissao      *string  `json:"data_admissao"`
		TipoContrato      *string  `json:"tipo_contrato"`
		SalarioBase       *float64 `json:"salario_base"`
		Estado            *string  `json:"estado"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.NomeCompleto == "" {
		jsonErr(w, "nome_completo é obrigatório", http.StatusBadRequest)
		return
	}

	tipoContrato := "efetivo"
	if body.TipoContrato != nil && *body.TipoContrato != "" {
		if !superadminTiposContrato[*body.TipoContrato] {
			jsonErr(w, "tipo_contrato inválido", http.StatusBadRequest)
			return
		}
		tipoContrato = *body.TipoContrato
	}

	estado := "ativo"
	if body.Estado != nil && *body.Estado != "" {
		estado = *body.Estado
	}

	var genero *string
	if body.Genero != nil && *body.Genero != "" {
		genero = body.Genero
	}

	var id int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO funcionarios (
			tenant_id, numero_funcionario, nome_completo, data_nascimento, genero,
			nuit, telefone, email, endereco, cargo,
			data_admissao, tipo_contrato, salario_base, estado
		) VALUES (
			$1, $2, $3, $4::date, $5,
			$6, $7, $8, $9, $10,
			COALESCE($11::date, CURRENT_DATE), $12, $13, $14
		) RETURNING id`,
		tenantID, body.NumeroFuncionario, body.NomeCompleto, body.DataNascimento, genero,
		body.Nuit, body.Telefone, body.Email, body.Endereco, body.Cargo,
		body.DataAdmissao, tipoContrato, body.SalarioBase, estado,
	).Scan(&id)
	if err != nil {
		if isPgUniqueViolation(err) {
			jsonErr(w, "Já existe um funcionário com este número neste tenant", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno ao criar funcionário", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "id": id, "msg": "Funcionário criado com sucesso."}, http.StatusCreated)
}

// ProximoNumeroFuncionarioTenant devolve o próximo número sequencial para um tenant específico.
func (h *Handler) ProximoNumeroFuncionarioTenant(w http.ResponseWriter, r *http.Request) {
	tenantID, err := strconv.ParseInt(chi.URLParam(r, "tenantId"), 10, 64)
	if err != nil || tenantID <= 0 {
		jsonErr(w, "tenant inválido", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	prefixo, sep, digitos, inicio := "FUNC", "-", 3, 1
	rows, err := h.db.Query(ctx, `
		SELECT DISTINCT ON (chave) chave, COALESCE(valor,'') FROM sistema_configuracao.settings
		WHERE tenant_id=$1 AND chave IN (
			'rh.prefixo_funcionario','rh.separador_funcionario',
			'rh.digitos_funcionario','rh.numero_inicial_funcionario'
		) ORDER BY chave, id DESC`, tenantID)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var k, v string
			rows.Scan(&k, &v)
			switch k {
			case "rh.prefixo_funcionario":
				if v != "" {
					prefixo = v
				}
			case "rh.separador_funcionario":
				sep = v
			case "rh.digitos_funcionario":
				if n, e := strconv.Atoi(v); e == nil && n >= 1 && n <= 10 {
					digitos = n
				}
			case "rh.numero_inicial_funcionario":
				if n, e := strconv.Atoi(v); e == nil && n >= 1 {
					inicio = n
				}
			}
		}
	}

	padrao := fmt.Sprintf(`^%s%s[0-9]+$`, prefixo, sep)
	var maxSeq int
	h.db.QueryRow(ctx, `
		SELECT COALESCE(MAX(
			CASE WHEN numero_funcionario ~ $2
			THEN CAST(SUBSTRING(numero_funcionario FROM '[0-9]+$') AS INTEGER)
			ELSE 0 END
		), 0)
		FROM rh.funcionarios WHERE tenant_id=$1`,
		tenantID, padrao).Scan(&maxSeq)

	proxima := maxSeq + 1
	if proxima < inicio {
		proxima = inicio
	}
	formato := fmt.Sprintf("%%s%%s%%0%dd", digitos)
	numero := fmt.Sprintf(formato, prefixo, sep, proxima)

	jsonOK(w, map[string]any{
		"numero":    numero,
		"prefixo":   prefixo,
		"separador": sep,
		"digitos":   digitos,
		"sequencia": proxima,
	}, http.StatusOK)
}
