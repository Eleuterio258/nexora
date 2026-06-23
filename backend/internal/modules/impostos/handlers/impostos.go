package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) taxJSONList(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) CriarRegime(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo     string  `json:"codigo"`
		Nome       string  `json:"nome"`
		Tipo       string  `json:"tipo"`
		Descricao  *string `json:"descricao"`
		Principal  bool    `json:"principal"`
		DataInicio *string `json:"data_inicio"`
		DataFim    *string `json:"data_fim"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Codigo == "" || body.Nome == "" ||
		!map[string]bool{"simplificado": true, "normal": true, "isento": true}[body.Tipo] {
		jsonErr(w, "codigo, nome e tipo fiscal valido sao obrigatorios", http.StatusBadRequest)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	if body.Principal {
		_, _ = tx.Exec(r.Context(), `
			UPDATE impostos.tax_regimes SET principal=false,updated_at=NOW()
			 WHERE tenant_id=$1`, user.TenantID)
	}
	var id int64
	err := tx.QueryRow(r.Context(), `
		INSERT INTO impostos.tax_regimes(
		  tenant_id,codigo,nome,tipo,descricao,principal,data_inicio,data_fim)
		VALUES($1,$2,$3,$4,$5,$6,$7::date,$8::date) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Tipo, body.Descricao,
		body.Principal, body.DataInicio, body.DataFim).Scan(&id)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Regime duplicado ou dados invalidos", http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarRegimes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.taxJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.principal DESC,x.nome),'[]'::jsonb)
		FROM (
		  SELECT id,codigo,nome,tipo,descricao,principal,data_inicio,data_fim,ativo,
		         created_at,updated_at
		    FROM impostos.tax_regimes WHERE tenant_id=$1
		) x`, user.TenantID)
}

func (h *Handler) CriarIsencao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		TaxID         int64   `json:"tax_id"`
		EntityType    string  `json:"entity_type"`
		EntityID      int64   `json:"entity_id"`
		Motivo        string  `json:"motivo"`
		NumeroIsencao string  `json:"numero_isencao"`
		DataInicio    *string `json:"data_inicio"`
		Validade      *string `json:"validade"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.TaxID < 1 || body.EntityID < 1 ||
		body.NumeroIsencao == "" || !map[string]bool{
		"customer": true, "supplier": true, "product": true, "product_category": true,
	}[body.EntityType] {
		jsonErr(w, "Imposto, entidade e numero de isencao sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO impostos.tax_exemptions(
		  tenant_id,tax_id,entity_type,entity_id,motivo,numero_isencao,data_inicio,validade)
		SELECT $1,id,$3,$4,$5,$6,COALESCE($7::date,CURRENT_DATE),$8::date
		  FROM impostos.taxes WHERE id=$2 AND tenant_id=$1
		RETURNING id`, user.TenantID, body.TaxID, body.EntityType, body.EntityID,
		body.Motivo, body.NumeroIsencao, body.DataInicio, body.Validade).Scan(&id)
	if err != nil {
		jsonErr(w, "Imposto ou dados de isencao invalidos", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarIsencoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "e.tenant_id=$1"
	args := []any{user.TenantID}
	for column, value := range map[string]string{
		"e.entity_type": q.Get("entity_type"),
		"e.entity_id":   q.Get("entity_id"),
	} {
		if value != "" {
			args = append(args, value)
			where += " AND " + column + "=$" + strconv.Itoa(len(args))
		}
	}
	if q.Get("ativas") == "true" {
		where += " AND e.ativo AND e.data_inicio<=CURRENT_DATE AND (e.validade IS NULL OR e.validade>=CURRENT_DATE)"
	}
	h.taxJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.validade NULLS LAST,x.id DESC),'[]'::jsonb)
		FROM (
		  SELECT e.*,t.codigo AS imposto_codigo,t.nome AS imposto_nome,
		         CASE WHEN e.validade IS NULL THEN NULL ELSE e.validade-CURRENT_DATE END dias_validade,
		         e.ativo AND e.data_inicio<=CURRENT_DATE
		           AND (e.validade IS NULL OR e.validade>=CURRENT_DATE) activa_agora,
		         e.ativo AND e.validade BETWEEN CURRENT_DATE AND CURRENT_DATE+30 alerta_validade
		    FROM impostos.tax_exemptions e
		    JOIN impostos.taxes t ON t.id=e.tax_id
		   WHERE `+where+`
		) x`, args...)
}

func (h *Handler) ActualizarIsencao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Motivo        *string `json:"motivo"`
		NumeroIsencao *string `json:"numero_isencao"`
		DataInicio    *string `json:"data_inicio"`
		Validade      *string `json:"validade"`
		Ativo         *bool   `json:"ativo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE impostos.tax_exemptions
		   SET motivo=COALESCE($1,motivo),numero_isencao=COALESCE($2,numero_isencao),
		       data_inicio=COALESCE($3::date,data_inicio),validade=COALESCE($4::date,validade),
		       ativo=COALESCE($5,ativo),updated_at=NOW()
		 WHERE id=$6 AND tenant_id=$7`,
		body.Motivo, body.NumeroIsencao, body.DataInicio, body.Validade,
		body.Ativo, chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Isencao nao encontrada ou dados invalidos", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverIsencao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM impostos.tax_exemptions WHERE id=$1 AND tenant_id=$2`,
		chi.URLParam(r, "id"), user.TenantID)
	if err != nil {
		jsonErr(w, "Isencao ja foi utilizada em documento fiscal", http.StatusConflict)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Isencao nao encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CriarOuRegistarRetencao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		WithholdingTaxID *int64   `json:"withholding_tax_id"`
		Codigo           string   `json:"codigo"`
		Nome             string   `json:"nome"`
		Tipo             string   `json:"tipo"`
		Taxa             float64  `json:"taxa"`
		AplicaEm         string   `json:"aplica_em"`
		TipoEntidade     *string  `json:"tipo_entidade"`
		Descricao        *string  `json:"descricao"`
		ReferenciaTipo   *string  `json:"referencia_tipo"`
		ReferenciaID     *int64   `json:"referencia_id"`
		EntityType       *string  `json:"entity_type"`
		EntityID         *int64   `json:"entity_id"`
		DocumentoNumero  *string  `json:"documento_numero"`
		BaseImponivel    *float64 `json:"base_imponivel"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if body.WithholdingTaxID == nil {
		if body.Codigo == "" || body.Nome == "" || body.Taxa < 0 ||
			!map[string]bool{"IRPS": true, "IRPC": true}[body.Tipo] ||
			!map[string]bool{"pagamento": true, "fatura": true}[body.AplicaEm] {
			jsonErr(w, "codigo, nome, tipo, taxa e aplica_em validos sao obrigatorios", http.StatusBadRequest)
			return
		}
		var id int64
		err := h.db.QueryRow(r.Context(), `
			INSERT INTO impostos.withholding_taxes(
			  tenant_id,codigo,nome,tipo,taxa,aplica_em,tipo_entidade,descricao)
			VALUES($1,$2,$3,$4,$5,$6,COALESCE($7,'todos'),$8) RETURNING id`,
			user.TenantID, body.Codigo, body.Nome, body.Tipo, body.Taxa,
			body.AplicaEm, body.TipoEntidade, body.Descricao).Scan(&id)
		if err != nil {
			jsonErr(w, "Retencao duplicada ou dados invalidos", http.StatusConflict)
			return
		}
		jsonOK(w, map[string]any{"id": id, "tipo_registo": "regra"}, http.StatusCreated)
		return
	}
	if body.BaseImponivel == nil || *body.BaseImponivel <= 0 ||
		body.ReferenciaTipo == nil || body.ReferenciaID == nil {
		jsonErr(w, "base_imponivel e referencia do documento sao obrigatorias", http.StatusBadRequest)
		return
	}
	var id int64
	var valor float64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO impostos.withholding_tax_transactions(
		  tenant_id,withholding_tax_id,referencia_tipo,referencia_id,
		  entity_type,entity_id,documento_numero,base_imponivel,taxa_aplicada,
		  valor_retido,created_by)
		SELECT $1,id,$3,$4,$5,$6,$7,$8,taxa,ROUND($8*taxa/100,2),$9
		  FROM impostos.withholding_taxes
		 WHERE id=$2 AND tenant_id=$1 AND ativo
		RETURNING id,valor_retido`,
		user.TenantID, body.WithholdingTaxID, body.ReferenciaTipo, body.ReferenciaID,
		body.EntityType, body.EntityID, body.DocumentoNumero, body.BaseImponivel, user.ID).
		Scan(&id, &valor)
	if err != nil {
		jsonErr(w, "Regra de retencao nao encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"id": id, "tipo_registo": "transaccao", "valor_retido": valor}, http.StatusCreated)
}

func (h *Handler) ListarRetencoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.taxJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.tipo,x.nome),'[]'::jsonb)
		FROM (
		  SELECT r.*,(SELECT COUNT(*) FROM impostos.withholding_tax_transactions t
		               WHERE t.withholding_tax_id=r.id) total_transaccoes,
		         (SELECT COALESCE(SUM(valor_retido),0)
		            FROM impostos.withholding_tax_transactions t
		           WHERE t.withholding_tax_id=r.id) total_retido
		    FROM impostos.withholding_taxes r WHERE r.tenant_id=$1
		) x`, user.TenantID)
}

func (h *Handler) ListarTransaccoesRetencao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.taxJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.transaction_date DESC),'[]'::jsonb)
		FROM (
		  SELECT t.* FROM impostos.withholding_tax_transactions t
		  JOIN impostos.withholding_taxes r ON r.id=t.withholding_tax_id
		  WHERE r.id=$1 AND r.tenant_id=$2
		) x`, chi.URLParam(r, "id"), user.TenantID)
}

type declaracaoCredito struct {
	Codigo          string  `json:"codigo"`
	Descricao       string  `json:"descricao"`
	BaseImponivel   float64 `json:"base_imponivel"`
	Taxa            float64 `json:"taxa"`
	Valor           float64 `json:"valor"`
	ReferenciaTipo  string  `json:"referencia_tipo"`
	ReferenciaID    int64   `json:"referencia_id"`
	DocumentoNumero string  `json:"documento_numero"`
}

func (h *Handler) CriarDeclaracao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Periodo       string              `json:"periodo"`
		Tipo          string              `json:"tipo"`
		PeriodoInicio string              `json:"periodo_inicio"`
		PeriodoFim    string              `json:"periodo_fim"`
		SubstituiID   *int64              `json:"substitui_id"`
		CreditosIVA   []declaracaoCredito `json:"creditos_iva"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Periodo == "" ||
		body.PeriodoInicio == "" || body.PeriodoFim == "" ||
		!map[string]bool{"iva": true, "irps": true, "irpc": true, "retencoes": true}[body.Tipo] {
		jsonErr(w, "periodo, datas e tipo validos sao obrigatorios", http.StatusBadRequest)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	if body.SubstituiID != nil {
		var ok bool
		_ = tx.QueryRow(r.Context(), `
			SELECT EXISTS(SELECT 1 FROM impostos.tax_returns
			 WHERE id=$1 AND tenant_id=$2 AND tipo=$3 AND status IN ('submetida','paga'))`,
			body.SubstituiID, user.TenantID, body.Tipo).Scan(&ok)
		if !ok {
			jsonErr(w, "Declaracao original submetida nao encontrada", http.StatusUnprocessableEntity)
			return
		}
	}
	var id int64
	err := tx.QueryRow(r.Context(), `
		INSERT INTO impostos.tax_returns(
		  tenant_id,periodo,tipo,periodo_inicio,periodo_fim,substitui_id)
		VALUES($1,$2,$3,$4::date,$5::date,$6) RETURNING id`,
		user.TenantID, body.Periodo, body.Tipo, body.PeriodoInicio,
		body.PeriodoFim, body.SubstituiID).Scan(&id)
	if err != nil {
		jsonErr(w, "Ja existe declaracao para o periodo ou substituicao", http.StatusConflict)
		return
	}

	if body.Tipo == "iva" {
		_, err = tx.Exec(r.Context(), `
			INSERT INTO impostos.tax_return_lines(
			  tax_return_id,codigo,descricao,natureza,base_imponivel,taxa,valor,
			  referencia_tipo,referencia_id,documento_numero)
			SELECT $1,'IVA-LIQ','IVA liquidado','debito',i.subtotal,i.imposto_percent,
			       i.imposto_valor,'invoice_item',i.id,f.numero
			  FROM faturacao.invoice_items i
			  JOIN faturacao.invoices f ON f.id=i.invoice_id
			 WHERE f.tenant_id=$2 AND f.status IN ('emitida','parcialmente_paga','paga')
			   AND f.invoice_date BETWEEN $3::date AND $4::date`,
			id, user.TenantID, body.PeriodoInicio, body.PeriodoFim)
		for _, line := range body.CreditosIVA {
			if err != nil {
				break
			}
			if line.ReferenciaTipo == "" || line.ReferenciaID < 1 || line.Valor < 0 {
				jsonErr(w, "Credito de IVA sem documento de origem valido", http.StatusBadRequest)
				return
			}
			_, err = tx.Exec(r.Context(), `
				INSERT INTO impostos.tax_return_lines(
				  tax_return_id,codigo,descricao,natureza,base_imponivel,taxa,valor,
				  referencia_tipo,referencia_id,documento_numero)
				VALUES($1,COALESCE(NULLIF($2,''),'IVA-DED'),$3,'credito',$4,$5,$6,$7,$8,$9)`,
				id, line.Codigo, line.Descricao, line.BaseImponivel, line.Taxa,
				line.Valor, line.ReferenciaTipo, line.ReferenciaID, line.DocumentoNumero)
		}
	} else {
		tipo := body.Tipo
		if tipo == "retencoes" {
			tipo = ""
		}
		_, err = tx.Exec(r.Context(), `
			INSERT INTO impostos.tax_return_lines(
			  tax_return_id,codigo,descricao,natureza,base_imponivel,taxa,valor,
			  referencia_tipo,referencia_id,documento_numero)
			SELECT $1,r.codigo,r.nome,'retencao',t.base_imponivel,t.taxa_aplicada,
			       t.valor_retido,t.referencia_tipo,t.referencia_id,t.documento_numero
			  FROM impostos.withholding_tax_transactions t
			  JOIN impostos.withholding_taxes r ON r.id=t.withholding_tax_id
			 WHERE t.tenant_id=$2 AND t.transaction_date >= $3::date
			   AND t.transaction_date < ($4::date+interval '1 day')
			   AND ($5='' OR LOWER(r.tipo)=LOWER($5))`,
			id, user.TenantID, body.PeriodoInicio, body.PeriodoFim, tipo)
	}
	if err != nil {
		jsonErr(w, "Erro ao gerar linhas da declaracao", http.StatusInternalServerError)
		return
	}
	_, err = tx.Exec(r.Context(), `
		UPDATE impostos.tax_returns d SET
		  total_base=COALESCE(x.base,0),total_imposto=COALESCE(x.debito,0),
		  total_credito=COALESCE(x.credito,0),
		  total_a_pagar=GREATEST(COALESCE(x.debito,0)-COALESCE(x.credito,0),0),
		  total_a_recuperar=GREATEST(COALESCE(x.credito,0)-COALESCE(x.debito,0),0),
		  updated_at=NOW()
		FROM (
		  SELECT tax_return_id,SUM(base_imponivel) base,
		    SUM(CASE WHEN natureza IN ('debito','retencao') THEN valor ELSE 0 END) debito,
		    SUM(CASE WHEN natureza='credito' THEN valor ELSE 0 END) credito
		  FROM impostos.tax_return_lines WHERE tax_return_id=$1 GROUP BY tax_return_id
		) x WHERE d.id=x.tax_return_id`, id)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao finalizar declaracao", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarDeclaracoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	for column, value := range map[string]string{"tipo": q.Get("tipo"), "status": q.Get("status")} {
		if value != "" {
			args = append(args, value)
			where += " AND " + column + "=$" + strconv.Itoa(len(args))
		}
	}
	h.taxJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.periodo_inicio DESC,x.id DESC),'[]'::jsonb)
		FROM (
		  SELECT d.*,(SELECT COUNT(*) FROM impostos.tax_return_lines l
		               WHERE l.tax_return_id=d.id) total_linhas
		    FROM impostos.tax_returns d WHERE `+where+`
		) x`, args...)
}

func (h *Handler) ObterDeclaracao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
		  'id',d.id,'periodo',d.periodo,'tipo',d.tipo,'status',d.status,
		  'periodo_inicio',d.periodo_inicio,'periodo_fim',d.periodo_fim,
		  'substitui_id',d.substitui_id,'total_base',d.total_base,
		  'total_imposto',d.total_imposto,'total_credito',d.total_credito,
		  'total_a_pagar',d.total_a_pagar,'total_a_recuperar',d.total_a_recuperar,
		  'data_submissao',d.data_submissao,
		  'submetida_por',d.submetida_por,'created_at',d.created_at,
		  'linhas',COALESCE((SELECT jsonb_agg(to_jsonb(l) ORDER BY l.id)
		    FROM impostos.tax_return_lines l WHERE l.tax_return_id=d.id),'[]'::jsonb)
		)
		FROM impostos.tax_returns d WHERE d.id=$1 AND d.tenant_id=$2`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Declaracao nao encontrada", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) SubmeterDeclaracao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE impostos.tax_returns
		   SET status='submetida',data_submissao=NOW(),submetida_por=$1,updated_at=NOW()
		 WHERE id=$2 AND tenant_id=$3 AND status='rascunho'`,
		user.ID, chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Declaracao em rascunho nao encontrada", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarLinhasDeclaracao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.taxJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(l) ORDER BY l.id),'[]'::jsonb)
		  FROM impostos.tax_return_lines l
		  JOIN impostos.tax_returns d ON d.id=l.tax_return_id
		 WHERE d.id=$1 AND d.tenant_id=$2`, chi.URLParam(r, "id"), user.TenantID)
}

func (h *Handler) CriarCertificado(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		EntityType  string  `json:"entity_type"`
		EntityID    int64   `json:"entity_id"`
		Tipo        string  `json:"tipo"`
		Numero      string  `json:"numero"`
		DataEmissao string  `json:"data_emissao"`
		Validade    *string `json:"validade"`
		FicheiroURL *string `json:"ficheiro_url"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.EntityID < 1 ||
		body.Numero == "" || body.DataEmissao == "" ||
		!map[string]bool{"tenant": true, "customer": true, "supplier": true, "employee": true}[body.EntityType] ||
		!map[string]bool{"isencao": true, "bom_contribuinte": true, "residencia_fiscal": true, "outro": true}[body.Tipo] {
		jsonErr(w, "Entidade, tipo, numero e emissao validos sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO impostos.tax_certificates(
		  tenant_id,entity_type,entity_id,tipo,numero,data_emissao,validade,ficheiro_url)
		VALUES($1,$2,$3,$4,$5,$6::date,$7::date,$8) RETURNING id`,
		user.TenantID, body.EntityType, body.EntityID, body.Tipo, body.Numero,
		body.DataEmissao, body.Validade, body.FicheiroURL).Scan(&id)
	if err != nil {
		jsonErr(w, "Certificado duplicado ou dados invalidos", http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarCertificados(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	for column, value := range map[string]string{
		"entity_type": q.Get("entity_type"),
		"entity_id":   q.Get("entity_id"),
	} {
		if value != "" {
			args = append(args, value)
			where += " AND " + column + "=$" + strconv.Itoa(len(args))
		}
	}
	h.taxJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.validade NULLS LAST),'[]'::jsonb)
		FROM (
		  SELECT c.*,CASE WHEN validade IS NULL THEN NULL ELSE validade-CURRENT_DATE END dias_validade,
		         ativo AND validade BETWEEN CURRENT_DATE AND CURRENT_DATE+30 alerta_validade,
		         ativo AND (validade IS NULL OR validade>=CURRENT_DATE) valido
		    FROM impostos.tax_certificates c WHERE `+where+`
		) x`, args...)
}
