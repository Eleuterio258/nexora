package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
)

// ── Settings ──────────────────────────────────────────────────────────────────

func (h *Handler) ListarCompanySettings(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, err := h.db.Query(r.Context(), `SELECT id, chave, valor, updated_at FROM company_settings WHERE company_id = $1 ORDER BY chave`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID        int64     `json:"id"`
		Chave     string    `json:"chave"`
		Valor     *string   `json:"valor"`
		UpdatedAt time.Time `json:"updated_at"`
	}
	data := []Row{}
	for rows.Next() {
		var x Row
		if rows.Scan(&x.ID, &x.Chave, &x.Valor, &x.UpdatedAt) == nil {
			data = append(data, x)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) GuardarCompanySetting(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Chave string  `json:"chave"`
		Valor *string `json:"valor"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Chave == "" {
		jsonErr(w, "chave é obrigatória", http.StatusBadRequest)
		return
	}
	h.db.Exec(r.Context(), `
		INSERT INTO company_settings (company_id, chave, valor)
		VALUES ($1, $2, $3)
		ON CONFLICT (company_id, chave) DO UPDATE SET valor = $3, updated_at = NOW()`,
		id, body.Chave, body.Valor)
	w.WriteHeader(http.StatusNoContent)
}

// ── Tax Info ──────────────────────────────────────────────────────────────────

func (h *Handler) ObterTaxInfo(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var t struct {
		ID              int64      `json:"id"`
		Nuit            string     `json:"nuit"`
		RegimeIva       *string    `json:"regime_iva"`
		TaxaIvaPadrao   float64    `json:"taxa_iva_padrao"`
		InicioAtividade *time.Time `json:"inicio_atividade"`
		ReparticaoFiscal *string   `json:"reparticao_fiscal"`
		UpdatedAt       time.Time  `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal, updated_at
		  FROM company_tax_info WHERE company_id = $1`, id).
		Scan(&t.ID, &t.Nuit, &t.RegimeIva, &t.TaxaIvaPadrao, &t.InicioAtividade, &t.ReparticaoFiscal, &t.UpdatedAt)
	if err != nil {
		jsonErr(w, "Informação fiscal não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, t, http.StatusOK)
}

func (h *Handler) GuardarTaxInfo(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Nuit             string   `json:"nuit"`
		RegimeIva        *string  `json:"regime_iva"`
		TaxaIvaPadrao    *float64 `json:"taxa_iva_padrao"`
		InicioAtividade  *string  `json:"inicio_atividade"`
		ReparticaoFiscal *string  `json:"reparticao_fiscal"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nuit == "" {
		jsonErr(w, "nuit é obrigatório", http.StatusBadRequest)
		return
	}
	_, err := h.db.Exec(r.Context(), `
		INSERT INTO company_tax_info (company_id, nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal)
		VALUES ($1, $2, $3, COALESCE($4, 17.00), $5::date, $6)
		ON CONFLICT (company_id) DO UPDATE SET
		  nuit = $2, regime_iva = $3,
		  taxa_iva_padrao = COALESCE($4, company_tax_info.taxa_iva_padrao),
		  inicio_atividade = COALESCE($5::date, company_tax_info.inicio_atividade),
		  reparticao_fiscal = COALESCE($6, company_tax_info.reparticao_fiscal),
		  updated_at = NOW()`,
		id, body.Nuit, body.RegimeIva, body.TaxaIvaPadrao, body.InicioAtividade, body.ReparticaoFiscal)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Banks ─────────────────────────────────────────────────────────────────────

func (h *Handler) ListarBancos(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, err := h.db.Query(r.Context(), `
		SELECT id, banco, numero_conta, nib, iban, swift, moeda, principal, created_at
		  FROM company_banks WHERE company_id = $1 ORDER BY principal DESC`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID          int64     `json:"id"`
		Banco       string    `json:"banco"`
		NumeroConta string    `json:"numero_conta"`
		Nib         *string   `json:"nib"`
		Iban        *string   `json:"iban"`
		Swift       *string   `json:"swift"`
		Moeda       string    `json:"moeda"`
		Principal   bool      `json:"principal"`
		CreatedAt   time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var b Row
		if rows.Scan(&b.ID, &b.Banco, &b.NumeroConta, &b.Nib, &b.Iban, &b.Swift, &b.Moeda, &b.Principal, &b.CreatedAt) == nil {
			data = append(data, b)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarBanco(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Banco       string  `json:"banco"`
		NumeroConta string  `json:"numero_conta"`
		Nib         *string `json:"nib"`
		Iban        *string `json:"iban"`
		Swift       *string `json:"swift"`
		Moeda       *string `json:"moeda"`
		Principal   *bool   `json:"principal"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Banco == "" || body.NumeroConta == "" {
		jsonErr(w, "banco e numero_conta são obrigatórios", http.StatusBadRequest)
		return
	}
	var bid int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO company_banks (company_id, banco, numero_conta, nib, iban, swift, moeda, principal)
		VALUES ($1,$2,$3,$4,$5,$6,COALESCE($7,'MZN'),COALESCE($8,FALSE)) RETURNING id`,
		id, body.Banco, body.NumeroConta, body.Nib, body.Iban, body.Swift, body.Moeda, body.Principal).Scan(&bid)
	jsonOK(w, map[string]any{"id": bid}, http.StatusCreated)
}

// ── Contacts ──────────────────────────────────────────────────────────────────

func (h *Handler) ListarContactos(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, tipo, nome, telefone, email, principal FROM company_contacts WHERE company_id = $1`, id)
	defer rows.Close()
	type Row struct {
		ID        int64   `json:"id"`
		Tipo      string  `json:"tipo"`
		Nome      *string `json:"nome"`
		Telefone  *string `json:"telefone"`
		Email     *string `json:"email"`
		Principal bool    `json:"principal"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.Tipo, &c.Nome, &c.Telefone, &c.Email, &c.Principal) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarContacto(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Tipo      *string `json:"tipo"`
		Nome      *string `json:"nome"`
		Telefone  *string `json:"telefone"`
		Email     *string `json:"email"`
		Principal *bool   `json:"principal"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	var cid int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO company_contacts (company_id, tipo, nome, telefone, email, principal)
		VALUES ($1, COALESCE($2,'geral'), $3, $4, $5, COALESCE($6,FALSE)) RETURNING id`,
		id, body.Tipo, body.Nome, body.Telefone, body.Email, body.Principal).Scan(&cid)
	jsonOK(w, map[string]any{"id": cid}, http.StatusCreated)
}

// ── Addresses ────────────────────────────────────────────────────────────────

func (h *Handler) ListarEnderecos(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, tipo, endereco, cidade, provincia, pais, codigo_postal FROM company_addresses WHERE company_id = $1`, id)
	defer rows.Close()
	type Row struct {
		ID           int64   `json:"id"`
		Tipo         string  `json:"tipo"`
		Endereco     string  `json:"endereco"`
		Cidade       *string `json:"cidade"`
		Provincia    *string `json:"provincia"`
		Pais         string  `json:"pais"`
		CodigoPostal *string `json:"codigo_postal"`
	}
	data := []Row{}
	for rows.Next() {
		var a Row
		if rows.Scan(&a.ID, &a.Tipo, &a.Endereco, &a.Cidade, &a.Provincia, &a.Pais, &a.CodigoPostal) == nil {
			data = append(data, a)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarEndereco(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Tipo         *string `json:"tipo"`
		Endereco     string  `json:"endereco"`
		Cidade       *string `json:"cidade"`
		Provincia    *string `json:"provincia"`
		CodigoPostal *string `json:"codigo_postal"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Endereco == "" {
		jsonErr(w, "endereco é obrigatório", http.StatusBadRequest)
		return
	}
	var eid int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO company_addresses (company_id, tipo, endereco, cidade, provincia, codigo_postal)
		VALUES ($1, COALESCE($2,'principal'), $3, $4, $5, $6) RETURNING id`,
		id, body.Tipo, body.Endereco, body.Cidade, body.Provincia, body.CodigoPostal).Scan(&eid)
	jsonOK(w, map[string]any{"id": eid}, http.StatusCreated)
}

// ── Licenses ─────────────────────────────────────────────────────────────────

func (h *Handler) ListarLicencas(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, plano, limite_usuarios, limite_filiais, inicia_em, expira_em, status
		  FROM company_licenses WHERE company_id = $1 ORDER BY inicia_em DESC`, id)
	defer rows.Close()
	type Row struct {
		ID             int64      `json:"id"`
		Plano          string     `json:"plano"`
		LimiteUsuarios *int       `json:"limite_usuarios"`
		LimiteFiliais  *int       `json:"limite_filiais"`
		IniciaEm       time.Time  `json:"inicia_em"`
		ExpiraEm       *time.Time `json:"expira_em"`
		Status         string     `json:"status"`
	}
	data := []Row{}
	for rows.Next() {
		var l Row
		if rows.Scan(&l.ID, &l.Plano, &l.LimiteUsuarios, &l.LimiteFiliais, &l.IniciaEm, &l.ExpiraEm, &l.Status) == nil {
			data = append(data, l)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarLicenca(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Plano          string  `json:"plano"`
		LimiteUsuarios *int    `json:"limite_usuarios"`
		LimiteFiliais  *int    `json:"limite_filiais"`
		IniciaEm       string  `json:"inicia_em"`
		ExpiraEm       *string `json:"expira_em"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Plano == "" || body.IniciaEm == "" {
		jsonErr(w, "plano e inicia_em são obrigatórios", http.StatusBadRequest)
		return
	}
	var lid int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO company_licenses (company_id, plano, limite_usuarios, limite_filiais, inicia_em, expira_em)
		VALUES ($1, $2, $3, $4, $5::date, $6::date) RETURNING id`,
		id, body.Plano, body.LimiteUsuarios, body.LimiteFiliais, body.IniciaEm, body.ExpiraEm).Scan(&lid)
	jsonOK(w, map[string]any{"id": lid}, http.StatusCreated)
}

// ── Company Users ─────────────────────────────────────────────────────────────

func (h *Handler) ListarCompanyUsers(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, user_id, branch_id, perfil_empresa, ativo FROM company_users WHERE company_id = $1`, id)
	defer rows.Close()
	type Row struct {
		ID             int64   `json:"id"`
		UserID         int64   `json:"user_id"`
		BranchID       *int64  `json:"branch_id"`
		PerfilEmpresa  *string `json:"perfil_empresa"`
		Ativo          bool    `json:"ativo"`
	}
	data := []Row{}
	for rows.Next() {
		var u Row
		if rows.Scan(&u.ID, &u.UserID, &u.BranchID, &u.PerfilEmpresa, &u.Ativo) == nil {
			data = append(data, u)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarCompanyUser(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		UserID        int64   `json:"user_id"`
		BranchID      *int64  `json:"branch_id"`
		PerfilEmpresa *string `json:"perfil_empresa"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.UserID == 0 {
		jsonErr(w, "user_id é obrigatório", http.StatusBadRequest)
		return
	}
	var uid int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO company_users (company_id, user_id, branch_id, perfil_empresa)
		VALUES ($1, $2, $3, $4) RETURNING id`,
		id, body.UserID, body.BranchID, body.PerfilEmpresa).Scan(&uid)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Utilizador já pertence a esta empresa", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": uid}, http.StatusCreated)
}

func (h *Handler) RemoverCompanyUser(w http.ResponseWriter, r *http.Request) {
	companyID := chi.URLParam(r, "id")
	userID := chi.URLParam(r, "userId")
	tag, _ := h.db.Exec(r.Context(), `DELETE FROM company_users WHERE company_id = $1 AND user_id = $2`, companyID, userID)
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Utilizador não encontrado nesta empresa", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
