package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

var tiposContratoValidos = map[string]bool{
	"efetivo": true, "indeterminado": true, "termo_certo": true, "termo_incerto": true, "estagio": true, "prestacao_servico": true,
}

var estadosFuncionarioValidos = map[string]bool{
	"ativo": true, "suspenso": true, "licenca": true, "desligado": true,
}

var generosValidos = map[string]bool{
	"M": true, "F": true, "outro": true,
}

var tiposUnidadeValidos = map[string]bool{
	"departamento": true, "equipa": true, "divisao": true, "seccao": true, "direccao": true, "gabinete": true, "projeto": true, "outro": true,
}

var estadosPeriodoValidos = map[string]bool{
	"aberto": true, "encerrado": true,
}

// businessDays conta os dias úteis (segunda a sexta) entre inicio e fim, inclusive.
func businessDays(inicio, fim time.Time) int {
	dias := 0
	for d := inicio; !d.After(fim); d = d.AddDate(0, 0, 1) {
		if wd := d.Weekday(); wd != time.Saturday && wd != time.Sunday {
			dias++
		}
	}
	return dias
}

// ── Unidades Organizacionais ────────────────────────────────────────────────

func (h *Handler) ListarUnidades(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT u.id, u.codigo, u.nome, u.tipo, u.descricao, u.parent_id, p.nome, u.responsavel_id, f.nome_completo, u.ativo,
		       (SELECT COUNT(*) FROM rh.funcionarios fu WHERE fu.unit_id = u.id)
		  FROM rh.unidades_organizacionais u
		  LEFT JOIN rh.funcionarios f ON f.id = u.responsavel_id
		  LEFT JOIN rh.unidades_organizacionais p ON p.id = u.parent_id
		 WHERE u.tenant_id=$1
		 ORDER BY u.nome`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID              int64   `json:"id"`
		Codigo          string  `json:"codigo"`
		Nome            string  `json:"nome"`
		Tipo            string  `json:"tipo"`
		Descricao       *string `json:"descricao"`
		ParentID        *int64  `json:"parent_id"`
		UnidadePaiNome  *string `json:"unidade_pai_nome"`
		ResponsavelID   *int64  `json:"responsavel_id"`
		ResponsavelNome *string `json:"responsavel_nome"`
		Ativo           bool    `json:"ativo"`
		NumFuncionarios int     `json:"num_funcionarios"`
	}
	data := []Row{}
	for rows.Next() {
		var u Row
		if rows.Scan(&u.ID, &u.Codigo, &u.Nome, &u.Tipo, &u.Descricao, &u.ParentID, &u.UnidadePaiNome, &u.ResponsavelID, &u.ResponsavelNome, &u.Ativo, &u.NumFuncionarios) == nil {
			data = append(data, u)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo        string  `json:"codigo"`
		Nome          string  `json:"nome"`
		Tipo          *string `json:"tipo"`
		Descricao     *string `json:"descricao"`
		ResponsavelID *int64  `json:"responsavel_id"`
		ParentID      *int64  `json:"parent_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	tipo := "departamento"
	if body.Tipo != nil && *body.Tipo != "" {
		if !tiposUnidadeValidos[*body.Tipo] {
			jsonErr(w, "tipo inválido", http.StatusBadRequest)
			return
		}
		tipo = *body.Tipo
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.unidades_organizacionais (tenant_id, codigo, nome, tipo, descricao, responsavel_id, parent_id)
		VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, tipo, body.Descricao, body.ResponsavelID, body.ParentID).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Unidade já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo        *string `json:"codigo"`
		Nome          *string `json:"nome"`
		Tipo          *string `json:"tipo"`
		Descricao     *string `json:"descricao"`
		ResponsavelID *int64  `json:"responsavel_id"`
		ParentID      *int64  `json:"parent_id"`
		Ativo         *bool   `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	if body.Tipo != nil && *body.Tipo != "" && !tiposUnidadeValidos[*body.Tipo] {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}
	_, err := h.db.Exec(r.Context(), `
		UPDATE rh.unidades_organizacionais SET codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), tipo=COALESCE($3,tipo),
		  descricao=COALESCE($4,descricao), responsavel_id=COALESCE($5,responsavel_id), parent_id=COALESCE($6,parent_id),
		  ativo=COALESCE($7,ativo), updated_at=NOW()
		WHERE id=$8 AND tenant_id=$9`,
		body.Codigo, body.Nome, body.Tipo, body.Descricao, body.ResponsavelID, body.ParentID, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Unidade já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Funcionários ────────────────────────────────────────────────────────────

func (h *Handler) ListarFuncionarios(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "f.tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("unit_id"); v != "" {
		args = append(args, v)
		where += " AND f.unit_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("estado"); v != "" {
		args = append(args, v)
		where += " AND f.estado=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("q"); v != "" {
		args = append(args, "%"+v+"%")
		n := strconv.Itoa(len(args))
		where += " AND (f.nome_completo ILIKE $" + n + " OR f.numero_funcionario ILIKE $" + n + ")"
	}

	// Paginação opcional: se o cliente enviar page, retorna {data, meta}.
	page := 0
	limit := 0
	if v := q.Get("page"); v != "" {
		page, _ = strconv.Atoi(v)
		if page < 1 {
			page = 1
		}
		limit, _ = strconv.Atoi(q.Get("limit"))
		if limit < 1 || limit > 100 {
			limit = 20
		}
	}

	type Row struct {
		ID                int64     `json:"id"`
		NumeroFuncionario *string   `json:"numero_funcionario"`
		NomeCompleto      string    `json:"nome_completo"`
		UnitID            *int64    `json:"unit_id"`
		UnidadeNome       *string   `json:"unidade_nome"`
		Cargo             *string   `json:"cargo"`
		CargoID           *int64    `json:"cargo_id"`
		HorarioID         *int64    `json:"horario_id"`
		DataAdmissao      time.Time `json:"data_admissao"`
		TipoContrato      string    `json:"tipo_contrato"`
		Estado            string    `json:"estado"`
		UserID            *int64    `json:"user_id"`
	}
	data := []Row{}

	if page > 0 {
		countArgs := make([]any, len(args))
		copy(countArgs, args)

		offset := (page - 1) * limit
		dataArgs := append(args, limit, offset)
		rows, _ := h.db.Query(r.Context(), `
			SELECT f.id, f.numero_funcionario, f.nome_completo, f.unit_id, u.nome, f.cargo, f.cargo_id, f.horario_id,
			       f.data_admissao, f.tipo_contrato, f.estado, f.user_id
			  FROM rh.funcionarios f
			  LEFT JOIN rh.unidades_organizacionais u ON u.id = f.unit_id
			 WHERE `+where+`
			 ORDER BY f.nome_completo
			 LIMIT $`+strconv.Itoa(len(dataArgs)-1)+` OFFSET $`+strconv.Itoa(len(dataArgs)), dataArgs...)
		defer rows.Close()
		for rows.Next() {
			var f Row
			if rows.Scan(&f.ID, &f.NumeroFuncionario, &f.NomeCompleto, &f.UnitID, &f.UnidadeNome, &f.Cargo, &f.CargoID, &f.HorarioID, &f.DataAdmissao, &f.TipoContrato, &f.Estado, &f.UserID) == nil {
				data = append(data, f)
			}
		}

		var total int
		h.db.QueryRow(r.Context(), `
			SELECT COUNT(*)
			  FROM rh.funcionarios f
			  LEFT JOIN rh.unidades_organizacionais u ON u.id = f.unit_id
			 WHERE `+where, countArgs...).Scan(&total)

		jsonOK(w, map[string]any{
			"data": data,
			"meta": map[string]int{"total": total, "page": page, "limit": limit},
		}, http.StatusOK)
		return
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT f.id, f.numero_funcionario, f.nome_completo, f.unit_id, u.nome, f.cargo, f.cargo_id, f.horario_id,
		       f.data_admissao, f.tipo_contrato, f.estado, f.user_id
		  FROM rh.funcionarios f
		  LEFT JOIN rh.unidades_organizacionais u ON u.id = f.unit_id
		 WHERE `+where+`
		 ORDER BY f.nome_completo`, args...)
	defer rows.Close()
	for rows.Next() {
		var f Row
		if rows.Scan(&f.ID, &f.NumeroFuncionario, &f.NomeCompleto, &f.UnitID, &f.UnidadeNome, &f.Cargo, &f.CargoID, &f.HorarioID, &f.DataAdmissao, &f.TipoContrato, &f.Estado, &f.UserID) == nil {
			data = append(data, f)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		NumeroFuncionario *string  `json:"numero_funcionario"`
		NomeCompleto      string   `json:"nome_completo"`
		DataNascimento    *string  `json:"data_nascimento"`
		Genero            *string  `json:"genero"`
		Nuit              *string  `json:"nuit"`
		Telefone          *string  `json:"telefone"`
		Email             *string  `json:"email"`
		Endereco          *string  `json:"endereco"`
		Provincia         *string  `json:"provincia"`
		Cidade            *string  `json:"cidade"`
		Bairro            *string  `json:"bairro"`
		UnitID            *int64   `json:"unit_id"`
		Cargo             *string  `json:"cargo"`
		CargoID           *int64   `json:"cargo_id"`
		HorarioID         *int64   `json:"horario_id"`
		DataAdmissao      *string  `json:"data_admissao"`
		TipoContrato      *string  `json:"tipo_contrato"`
		SalarioBase       *float64 `json:"salario_base"`
		Estado            *string  `json:"estado"`
		UserID            *int64   `json:"user_id"`
		CentroCustoID     *int64   `json:"centro_custo_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.NomeCompleto == "" {
		jsonErr(w, "nome_completo é obrigatório", http.StatusBadRequest)
		return
	}
	if body.Genero != nil && *body.Genero != "" && !generosValidos[*body.Genero] {
		jsonErr(w, "género inválido", http.StatusBadRequest)
		return
	}
	tipoContrato := "efetivo"
	if body.TipoContrato != nil && *body.TipoContrato != "" {
		if !tiposContratoValidos[*body.TipoContrato] {
			jsonErr(w, "tipo_contrato inválido", http.StatusBadRequest)
			return
		}
		tipoContrato = *body.TipoContrato
	}
	estado := "ativo"
	if body.Estado != nil && *body.Estado != "" {
		if !estadosFuncionarioValidos[*body.Estado] {
			jsonErr(w, "estado inválido", http.StatusBadRequest)
			return
		}
		estado = *body.Estado
	}
	var genero *string
	if body.Genero != nil && *body.Genero != "" {
		genero = body.Genero
	}

	var cargoID *int64
	if body.CargoID != nil && *body.CargoID > 0 {
		var nome string
		if err := h.db.QueryRow(r.Context(), `SELECT nome FROM rh.cargos WHERE id=$1 AND tenant_id=$2`, *body.CargoID, user.TenantID).Scan(&nome); err != nil {
			jsonErr(w, "Cargo inválido", http.StatusBadRequest)
			return
		}
		cargoID = body.CargoID
		body.Cargo = &nome
	}

	var horarioID *int64
	if body.HorarioID != nil && *body.HorarioID > 0 {
		var existe bool
		if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.horarios_trabalho WHERE id=$1 AND tenant_id=$2)`, *body.HorarioID, user.TenantID).Scan(&existe); err != nil || !existe {
			jsonErr(w, "Horário inválido", http.StatusBadRequest)
			return
		}
		horarioID = body.HorarioID
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.funcionarios (tenant_id, numero_funcionario, nome_completo, data_nascimento, genero, nuit, telefone, email,
		  endereco, provincia, cidade, bairro, unit_id, cargo, cargo_id, horario_id, data_admissao, tipo_contrato, salario_base, estado, user_id)
		VALUES ($1,$2,$3,$4::date,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,COALESCE($17::date,CURRENT_DATE),$18,$19,$20,$21) RETURNING id`,
		user.TenantID, body.NumeroFuncionario, body.NomeCompleto, body.DataNascimento, genero, body.Nuit, body.Telefone, body.Email,
		body.Endereco, body.Provincia, body.Cidade, body.Bairro, body.UnitID, body.Cargo, cargoID, horarioID, body.DataAdmissao, tipoContrato, body.SalarioBase, estado, body.UserID).Scan(&id)
	if err != nil {
		switch uniqueViolationConstraint(err) {
		case "uq_funcionarios_user_id":
			jsonErr(w, "Este utilizador já está associado a outro funcionário", http.StatusConflict)
		case "uq_funcionarios_tenant_numero":
			jsonErr(w, "Já existe um funcionário com este número", http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}

	if body.UserID != nil {
		aplicarPermissoesTipo(r.Context(), h.db, *body.UserID)
	}

	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var f struct {
		ID                int64      `json:"id"`
		NumeroFuncionario *string    `json:"numero_funcionario"`
		NomeCompleto      string     `json:"nome_completo"`
		DataNascimento    *time.Time `json:"data_nascimento"`
		Genero            *string    `json:"genero"`
		Nuit              *string    `json:"nuit"`
		Telefone          *string    `json:"telefone"`
		Email             *string    `json:"email"`
		Endereco          *string    `json:"endereco"`
		Provincia         *string    `json:"provincia"`
		Cidade            *string    `json:"cidade"`
		Bairro            *string    `json:"bairro"`
		UnitID            *int64     `json:"unit_id"`
		UnidadeNome       *string    `json:"unidade_nome"`
		Cargo             *string    `json:"cargo"`
		CargoID           *int64     `json:"cargo_id"`
		HorarioID         *int64     `json:"horario_id"`
		DataAdmissao      time.Time  `json:"data_admissao"`
		DataSaida         *time.Time `json:"data_saida"`
		TipoContrato      string     `json:"tipo_contrato"`
		SalarioBase       *float64   `json:"salario_base"`
		Estado            string     `json:"estado"`
		UserID            *int64     `json:"user_id"`
		CentroCustoID     *int64     `json:"centro_custo_id"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT f.id, f.numero_funcionario, f.nome_completo, f.data_nascimento, f.genero, f.nuit, f.telefone, f.email,
		       f.endereco, f.provincia, f.cidade, f.bairro, f.unit_id, u.nome, f.cargo, f.cargo_id, f.horario_id, f.data_admissao, f.data_saida, f.tipo_contrato, f.salario_base, f.estado, f.user_id, f.centro_custo_id
		  FROM rh.funcionarios f
		  LEFT JOIN rh.unidades_organizacionais u ON u.id = f.unit_id
		 WHERE f.id=$1 AND f.tenant_id=$2`, id, user.TenantID).
		Scan(&f.ID, &f.NumeroFuncionario, &f.NomeCompleto, &f.DataNascimento, &f.Genero, &f.Nuit, &f.Telefone, &f.Email,
			&f.Endereco, &f.Provincia, &f.Cidade, &f.Bairro, &f.UnitID, &f.UnidadeNome, &f.Cargo, &f.CargoID, &f.HorarioID, &f.DataAdmissao, &f.DataSaida, &f.TipoContrato, &f.SalarioBase, &f.Estado, &f.UserID, &f.CentroCustoID)
	if err != nil {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	contratoRows, _ := h.db.Query(r.Context(), `
		SELECT id, tipo, funcao, data_inicio, data_fim, salario, ficheiro_url, estado
		  FROM rh.contratos WHERE funcionario_id=$1 ORDER BY data_inicio DESC`, id)
	defer contratoRows.Close()
	type Contrato struct {
		ID          int64      `json:"id"`
		Tipo        string     `json:"tipo"`
		Funcao      *string    `json:"funcao"`
		DataInicio  time.Time  `json:"data_inicio"`
		DataFim     *time.Time `json:"data_fim"`
		Salario     *float64   `json:"salario"`
		FicheiroURL *string    `json:"ficheiro_url"`
		Estado      string     `json:"estado"`
	}
	contratos := []Contrato{}
	for contratoRows.Next() {
		var c Contrato
		if contratoRows.Scan(&c.ID, &c.Tipo, &c.Funcao, &c.DataInicio, &c.DataFim, &c.Salario, &c.FicheiroURL, &c.Estado) == nil {
			contratos = append(contratos, c)
		}
	}

	ausenciaRows, _ := h.db.Query(r.Context(), `
		SELECT a.id, a.tipo_id, ta.nome, a.data_inicio, a.data_fim, a.dias, a.motivo, a.estado, a.aprovado_em
		  FROM rh.ausencias a
		  LEFT JOIN rh.tipos_ausencia ta ON ta.id = a.tipo_id
		 WHERE a.funcionario_id=$1 ORDER BY a.created_at DESC`, id)
	defer ausenciaRows.Close()
	type Ausencia struct {
		ID         int64      `json:"id"`
		TipoID     *int64     `json:"tipo_id"`
		TipoNome   *string    `json:"tipo_nome"`
		DataInicio time.Time  `json:"data_inicio"`
		DataFim    time.Time  `json:"data_fim"`
		Dias       *int       `json:"dias"`
		Motivo     *string    `json:"motivo"`
		Estado     string     `json:"estado"`
		AprovadoEm *time.Time `json:"aprovado_em"`
	}
	ausencias := []Ausencia{}
	for ausenciaRows.Next() {
		var a Ausencia
		if ausenciaRows.Scan(&a.ID, &a.TipoID, &a.TipoNome, &a.DataInicio, &a.DataFim, &a.Dias, &a.Motivo, &a.Estado, &a.AprovadoEm) == nil {
			ausencias = append(ausencias, a)
		}
	}

	podeAprovar := user.Tipo == "superadmin"
	if !podeAprovar {
		if meuFuncionarioID, err := h.GetUserFuncionario(r.Context(), user.TenantID, user.ID); err == nil && meuFuncionarioID != nil {
			podeAprovar, _ = h.IsResponsavelHierarquico(r.Context(), user.TenantID, *meuFuncionarioID, f.ID)
		}
	}

	podeVerSalarios := h.PodeVerSalarios(r)
	if !podeVerSalarios {
		f.SalarioBase = nil
		for i := range contratos {
			contratos[i].Salario = nil
		}
	}

	avaliacaoRows, _ := h.db.Query(r.Context(), `
		SELECT av.id, av.periodo_id, p.nome, av.pontuacao, av.comentarios, av.estado, av.avaliador_id, av.created_at,
		       COALESCE((SELECT json_agg(json_build_object('criterio_id', ac.criterio_id, 'criterio_nome', ca.nome, 'pontuacao', ac.pontuacao, 'peso', ca.peso) ORDER BY ca.nome)
		                   FROM rh.avaliacao_criterios ac JOIN rh.criterios_avaliacao ca ON ca.id = ac.criterio_id
		                  WHERE ac.avaliacao_id = av.id), '[]'::json)
		  FROM rh.avaliacoes av
		  LEFT JOIN rh.periodos_avaliacao p ON p.id = av.periodo_id
		 WHERE av.funcionario_id=$1 ORDER BY av.created_at DESC`, id)
	defer avaliacaoRows.Close()
	type Avaliacao struct {
		ID           int64           `json:"id"`
		PeriodoID    *int64          `json:"periodo_id"`
		PeriodoNome  *string         `json:"periodo_nome"`
		Pontuacao    *float64        `json:"pontuacao"`
		Comentarios  *string         `json:"comentarios"`
		Estado       string          `json:"estado"`
		CreatedAt    time.Time       `json:"created_at"`
		Criterios    json.RawMessage `json:"criterios"`
		PodeSubmeter bool            `json:"pode_submeter"`
	}
	avaliacoes := []Avaliacao{}
	for avaliacaoRows.Next() {
		var a Avaliacao
		var avaliadorID int64
		if avaliacaoRows.Scan(&a.ID, &a.PeriodoID, &a.PeriodoNome, &a.Pontuacao, &a.Comentarios, &a.Estado, &avaliadorID, &a.CreatedAt, &a.Criterios) == nil {
			a.PodeSubmeter = avaliadorID == user.ID || user.Tipo == "superadmin"
			avaliacoes = append(avaliacoes, a)
		}
	}

	contactoRows, _ := h.db.Query(r.Context(), `
		SELECT id, nome, parentesco, telefone, email
		  FROM rh.contactos_emergencia WHERE funcionario_id=$1 ORDER BY id`, id)
	defer contactoRows.Close()
	type ContactoEmergencia struct {
		ID         int64   `json:"id"`
		Nome       string  `json:"nome"`
		Parentesco *string `json:"parentesco"`
		Telefone   string  `json:"telefone"`
		Email      *string `json:"email"`
	}
	contactosEmergencia := []ContactoEmergencia{}
	for contactoRows.Next() {
		var c ContactoEmergencia
		if contactoRows.Scan(&c.ID, &c.Nome, &c.Parentesco, &c.Telefone, &c.Email) == nil {
			contactosEmergencia = append(contactosEmergencia, c)
		}
	}

	documentoRows, _ := h.db.Query(r.Context(), `
		SELECT id, tipo, numero, data_emissao, data_validade, ficheiro_url
		  FROM rh.documentos_funcionario WHERE funcionario_id=$1 ORDER BY created_at DESC`, id)
	defer documentoRows.Close()
	type Documento struct {
		ID           int64      `json:"id"`
		Tipo         string     `json:"tipo"`
		Numero       *string    `json:"numero"`
		DataEmissao  *time.Time `json:"data_emissao"`
		DataValidade *time.Time `json:"data_validade"`
		FicheiroURL  *string    `json:"ficheiro_url"`
	}
	documentos := []Documento{}
	for documentoRows.Next() {
		var d Documento
		if documentoRows.Scan(&d.ID, &d.Tipo, &d.Numero, &d.DataEmissao, &d.DataValidade, &d.FicheiroURL) == nil {
			documentos = append(documentos, d)
		}
	}

	jsonOK(w, map[string]any{
		"funcionario": f, "contratos": contratos, "ausencias": ausencias, "avaliacoes": avaliacoes,
		"contactos_emergencia": contactosEmergencia, "documentos": documentos, "pode_aprovar": podeAprovar,
		"pode_ver_salarios": podeVerSalarios,
	}, http.StatusOK)
}

func (h *Handler) ActualizarFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		NumeroFuncionario *string  `json:"numero_funcionario"`
		NomeCompleto      *string  `json:"nome_completo"`
		DataNascimento    *string  `json:"data_nascimento"`
		Genero            *string  `json:"genero"`
		Nuit              *string  `json:"nuit"`
		Telefone          *string  `json:"telefone"`
		Email             *string  `json:"email"`
		Endereco          *string  `json:"endereco"`
		Provincia         *string  `json:"provincia"`
		Cidade            *string  `json:"cidade"`
		Bairro            *string  `json:"bairro"`
		UnitID            *int64   `json:"unit_id"`
		Cargo             *string  `json:"cargo"`
		CargoID           *int64   `json:"cargo_id"`
		HorarioID         *int64   `json:"horario_id"`
		DataAdmissao      *string  `json:"data_admissao"`
		TipoContrato      *string  `json:"tipo_contrato"`
		SalarioBase       *float64 `json:"salario_base"`
		Estado            *string  `json:"estado"`
		UserID            *int64   `json:"user_id"`
		CentroCustoID     *int64   `json:"centro_custo_id"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	if body.TipoContrato != nil && *body.TipoContrato != "" && !tiposContratoValidos[*body.TipoContrato] {
		jsonErr(w, "tipo_contrato inválido", http.StatusBadRequest)
		return
	}
	if body.Estado != nil && *body.Estado != "" && !estadosFuncionarioValidos[*body.Estado] {
		jsonErr(w, "estado inválido", http.StatusBadRequest)
		return
	}
	if body.Genero != nil && *body.Genero != "" && !generosValidos[*body.Genero] {
		jsonErr(w, "género inválido", http.StatusBadRequest)
		return
	}
	var cargoID *int64
	if body.CargoID != nil && *body.CargoID > 0 {
		var nome string
		if err := h.db.QueryRow(r.Context(), `SELECT nome FROM rh.cargos WHERE id=$1 AND tenant_id=$2`, *body.CargoID, user.TenantID).Scan(&nome); err != nil {
			jsonErr(w, "Cargo inválido", http.StatusBadRequest)
			return
		}
		cargoID = body.CargoID
		body.Cargo = &nome
	}
	var horarioID *int64
	if body.HorarioID != nil && *body.HorarioID > 0 {
		var existe bool
		if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.horarios_trabalho WHERE id=$1 AND tenant_id=$2)`, *body.HorarioID, user.TenantID).Scan(&existe); err != nil || !existe {
			jsonErr(w, "Horário inválido", http.StatusBadRequest)
			return
		}
		horarioID = body.HorarioID
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.funcionarios SET
		  numero_funcionario=COALESCE($1,numero_funcionario), nome_completo=COALESCE($2,nome_completo),
		  data_nascimento=COALESCE($3::date,data_nascimento), genero=COALESCE($4,genero), nuit=COALESCE($5,nuit),
		  telefone=COALESCE($6,telefone), email=COALESCE($7,email), endereco=COALESCE($8,endereco),
		  provincia=COALESCE($9,provincia), cidade=COALESCE($10,cidade), bairro=COALESCE($11,bairro),
		  unit_id=COALESCE($12,unit_id), cargo=COALESCE($13,cargo), cargo_id=COALESCE($14,cargo_id), horario_id=COALESCE($15,horario_id),
		  data_admissao=COALESCE($16::date,data_admissao), tipo_contrato=COALESCE($17,tipo_contrato),
		  salario_base=COALESCE($18,salario_base), estado=COALESCE($19,estado), user_id=COALESCE($20,user_id),
		  centro_custo_id=COALESCE($21,centro_custo_id), updated_at=NOW()
		WHERE id=$22 AND tenant_id=$23`,
		body.NumeroFuncionario, body.NomeCompleto, body.DataNascimento, body.Genero, body.Nuit,
		body.Telefone, body.Email, body.Endereco, body.Provincia, body.Cidade, body.Bairro,
		body.UnitID, body.Cargo, cargoID, horarioID,
		body.DataAdmissao, body.TipoContrato, body.SalarioBase, body.Estado, body.UserID, body.CentroCustoID, id, user.TenantID)
	if err != nil {
		switch uniqueViolationConstraint(err) {
		case "uq_funcionarios_user_id":
			jsonErr(w, "Este utilizador já está associado a outro funcionário", http.StatusConflict)
		case "uq_funcionarios_tenant_numero":
			jsonErr(w, "Já existe um funcionário com este número", http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	if body.UserID != nil {
		aplicarPermissoesTipo(r.Context(), h.db, *body.UserID)
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) DesligarFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		DataSaida *string `json:"data_saida"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var userID *int64
	var nome, email string
	err = tx.QueryRow(r.Context(), `
		UPDATE rh.funcionarios SET estado='desligado', data_saida=COALESCE($1::date,CURRENT_DATE), updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3
		RETURNING user_id, nome_completo, COALESCE(email, '')`,
		body.DataSaida, id, user.TenantID).Scan(&userID, &nome, &email)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Revogar acesso ao ERP e activar/manter o perfil de candidato, sem tocar
	// em auth.users.estado (que representa apenas o bloqueio global da conta).
	if userID != nil {
		if _, err := tx.Exec(r.Context(),
			`UPDATE auth.memberships SET ativo=false, updated_at=NOW() WHERE user_id=$1`, *userID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if _, err := tx.Exec(r.Context(),
			`UPDATE auth.sessions SET ativa=false, encerrado_em=NOW() WHERE user_id=$1 AND ativa=true`, *userID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if _, err := tx.Exec(r.Context(),
			`UPDATE auth.users SET tipo='candidato' WHERE id=$1 AND tipo='funcionario'`, *userID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if email != "" {
			if _, err := tx.Exec(r.Context(), `
				INSERT INTO recrutamento.candidatos (tenant_id, user_id, email, nome, ativo)
				VALUES ($1, $2, $3, $4, true)
				ON CONFLICT (tenant_id, email) DO UPDATE SET user_id=EXCLUDED.user_id, ativo=true`,
				user.TenantID, *userID, email, nome); err != nil {
				jsonErr(w, "Erro interno", http.StatusInternalServerError)
				return
			}
		}
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// rhNumConfig lê as configurações de numeração de funcionários para um tenant.
func (h *Handler) rhNumConfig(ctx context.Context, tenantID int64) (prefixo, sep string, digitos, inicio int) {
	prefixo = "FUNC"
	sep = "-"
	digitos = 3
	inicio = 1
	rows, err := h.db.Query(ctx, `
		SELECT DISTINCT ON (chave) chave, COALESCE(valor,'') FROM sistema_configuracao.settings
		WHERE tenant_id=$1 AND chave IN (
			'rh.prefixo_funcionario','rh.separador_funcionario',
			'rh.digitos_funcionario','rh.numero_inicial_funcionario'
		) ORDER BY chave, id DESC`, tenantID)
	if err != nil {
		return
	}
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
			if n, err := strconv.Atoi(v); err == nil && n >= 1 && n <= 10 {
				digitos = n
			}
		case "rh.numero_inicial_funcionario":
			if n, err := strconv.Atoi(v); err == nil && n >= 1 {
				inicio = n
			}
		}
	}
	return
}

// ProximoNumeroFuncionario devolve o próximo número sequencial usando as configurações do tenant.
func (h *Handler) ProximoNumeroFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	prefixo, sep, digitos, inicio := h.rhNumConfig(r.Context(), user.TenantID)

	// padrão de matching dinâmico baseado no prefixo + separador configurados
	padrao := fmt.Sprintf(`^%s%s[0-9]+$`, prefixo, sep)
	var maxSeq int
	h.db.QueryRow(r.Context(), `
		SELECT COALESCE(MAX(
			CASE WHEN numero_funcionario ~ $2
			THEN CAST(SUBSTRING(numero_funcionario FROM '[0-9]+$') AS INTEGER)
			ELSE 0 END
		), 0)
		FROM rh.funcionarios WHERE tenant_id=$1`,
		user.TenantID, padrao).Scan(&maxSeq)

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

// ObterConfiguracoesRH devolve as settings com prefixo "rh." deste tenant.
func (h *Handler) ObterConfiguracoesRH(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT DISTINCT ON (chave) chave, valor
		FROM sistema_configuracao.settings
		WHERE tenant_id=$1 AND chave LIKE 'rh.%'
		ORDER BY chave, id DESC`, user.TenantID)
	defer rows.Close()
	cfg := map[string]any{}
	for rows.Next() {
		var chave string
		var valor *string
		if rows.Scan(&chave, &valor) == nil {
			cfg[chave] = valor
		}
	}
	// defaults
	defaults := map[string]string{
		"rh.prefixo_funcionario":         "FUNC",
		"rh.separador_funcionario":        "-",
		"rh.digitos_funcionario":          "3",
		"rh.numero_inicial_funcionario":   "1",
	}
	for k, v := range defaults {
		if cfg[k] == nil {
			cfg[k] = v
		}
	}
	jsonOK(w, cfg, http.StatusOK)
}

// GuardarConfiguracaoRH guarda (upsert) uma setting com prefixo "rh." para este tenant.
func (h *Handler) GuardarConfiguracaoRH(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Chave string  `json:"chave"`
		Valor *string `json:"valor"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Chave == "" {
		jsonErr(w, "chave é obrigatória", http.StatusBadRequest)
		return
	}
	if len(body.Chave) < 4 || body.Chave[:3] != "rh." {
		jsonErr(w, "chave deve começar com rh.", http.StatusBadRequest)
		return
	}
	// DELETE + INSERT atomico: evita duplicados sem unique constraint
	_, err := h.db.Exec(r.Context(), `
		WITH del AS (
			DELETE FROM sistema_configuracao.settings WHERE tenant_id=$1 AND chave=$2
		)
		INSERT INTO sistema_configuracao.settings (tenant_id, chave, valor, escopo)
		VALUES ($1, $2, $3, 'tenant')`,
		user.TenantID, body.Chave, body.Valor)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Contratos ───────────────────────────────────────────────────────────────

func (h *Handler) ListarContratos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("funcionario_id"); v != "" {
		args = append(args, v)
		where += " AND funcionario_id=$" + strconv.Itoa(len(args))
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, funcionario_id, tipo, funcao, data_inicio, data_fim, salario, ficheiro_url, estado
		  FROM rh.contratos WHERE `+where+` ORDER BY data_inicio DESC`, args...)
	defer rows.Close()
	type Row struct {
		ID            int64      `json:"id"`
		FuncionarioID int64      `json:"funcionario_id"`
		Tipo          string     `json:"tipo"`
		Funcao        *string    `json:"funcao"`
		DataInicio    time.Time  `json:"data_inicio"`
		DataFim       *time.Time `json:"data_fim"`
		Salario       *float64   `json:"salario"`
		FicheiroURL   *string    `json:"ficheiro_url"`
		Estado        string     `json:"estado"`
	}
	podeVerSalarios := h.PodeVerSalarios(r)
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.FuncionarioID, &c.Tipo, &c.Funcao, &c.DataInicio, &c.DataFim, &c.Salario, &c.FicheiroURL, &c.Estado) == nil {
			if !podeVerSalarios {
				c.Salario = nil
			}
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarContrato(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		FuncionarioID int64    `json:"funcionario_id"`
		Tipo          string   `json:"tipo"`
		Funcao        *string  `json:"funcao"`
		DataInicio    string   `json:"data_inicio"`
		DataFim       *string  `json:"data_fim"`
		Salario       *float64 `json:"salario"`
		FicheiroURL   *string  `json:"ficheiro_url"`
		Estado        *string  `json:"estado"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.FuncionarioID == 0 || !tiposContratoValidos[body.Tipo] || body.DataInicio == "" {
		jsonErr(w, "funcionario_id, tipo e data_inicio são obrigatórios", http.StatusBadRequest)
		return
	}
	estado := "ativo"
	if body.Estado != nil && *body.Estado != "" {
		estado = *body.Estado
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.contratos (tenant_id, funcionario_id, tipo, funcao, data_inicio, data_fim, salario, ficheiro_url, estado)
		VALUES ($1,$2,$3,$4,$5::date,$6::date,$7,$8,$9) RETURNING id`,
		user.TenantID, body.FuncionarioID, body.Tipo, body.Funcao, body.DataInicio, body.DataFim, body.Salario, body.FicheiroURL, estado).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterContrato(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var c struct {
		ID            int64      `json:"id"`
		FuncionarioID int64      `json:"funcionario_id"`
		Tipo          string     `json:"tipo"`
		Funcao        *string    `json:"funcao"`
		DataInicio    time.Time  `json:"data_inicio"`
		DataFim       *time.Time `json:"data_fim"`
		Salario       *float64   `json:"salario"`
		FicheiroURL   *string    `json:"ficheiro_url"`
		Estado        string     `json:"estado"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, funcionario_id, tipo, funcao, data_inicio, data_fim, salario, ficheiro_url, estado
		  FROM rh.contratos WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&c.ID, &c.FuncionarioID, &c.Tipo, &c.Funcao, &c.DataInicio, &c.DataFim, &c.Salario, &c.FicheiroURL, &c.Estado)
	if err != nil {
		jsonErr(w, "Contrato não encontrado", http.StatusNotFound)
		return
	}
	if !h.PodeVerSalarios(r) {
		c.Salario = nil
	}
	jsonOK(w, c, http.StatusOK)
}

func (h *Handler) ActualizarContrato(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Tipo        *string  `json:"tipo"`
		Funcao      *string  `json:"funcao"`
		DataInicio  *string  `json:"data_inicio"`
		DataFim     *string  `json:"data_fim"`
		Salario     *float64 `json:"salario"`
		FicheiroURL *string  `json:"ficheiro_url"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Dados inválidos", http.StatusBadRequest)
		return
	}
	if body.Tipo != nil && !tiposContratoValidos[*body.Tipo] {
		jsonErr(w, "Tipo de contrato inválido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.contratos SET
			tipo=COALESCE($1,tipo), funcao=COALESCE($2,funcao),
			data_inicio=COALESCE($3::date,data_inicio), data_fim=COALESCE($4::date,data_fim),
			salario=COALESCE($5,salario), ficheiro_url=COALESCE($6,ficheiro_url)
		WHERE id=$7 AND tenant_id=$8`,
		body.Tipo, body.Funcao, body.DataInicio, body.DataFim, body.Salario, body.FicheiroURL, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Contrato não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// RenovarContrato encerra o contrato actual e cria um novo, seguindo a partir
// do dia seguinte à data de fim do contrato anterior.
func (h *Handler) RenovarContrato(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		DataFim string   `json:"data_fim"`
		Salario *float64 `json:"salario"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.DataFim == "" {
		jsonErr(w, "data_fim é obrigatória", http.StatusBadRequest)
		return
	}
	novoFim, err := time.Parse("2006-01-02", body.DataFim)
	if err != nil {
		jsonErr(w, "data_fim inválida", http.StatusBadRequest)
		return
	}

	var (
		funcionarioID int64
		tipo          string
		funcao        *string
		dataFimAtual  *time.Time
		salarioAtual  *float64
		estado        string
	)
	err = h.db.QueryRow(r.Context(), `
		SELECT funcionario_id, tipo, funcao, data_fim, salario, estado
		  FROM rh.contratos WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&funcionarioID, &tipo, &funcao, &dataFimAtual, &salarioAtual, &estado)
	if err != nil {
		jsonErr(w, "Contrato não encontrado", http.StatusNotFound)
		return
	}
	if estado != "ativo" {
		jsonErr(w, "Apenas contratos activos podem ser renovados", http.StatusConflict)
		return
	}
	if dataFimAtual == nil {
		jsonErr(w, "Apenas contratos com data de fim definida podem ser renovados", http.StatusBadRequest)
		return
	}

	novoInicio := dataFimAtual.AddDate(0, 0, 1)
	if novoFim.Before(novoInicio) {
		jsonErr(w, "data_fim deve ser posterior à data de fim do contrato actual", http.StatusBadRequest)
		return
	}

	salario := salarioAtual
	if body.Salario != nil {
		salario = body.Salario
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	if _, err := tx.Exec(r.Context(), `UPDATE rh.contratos SET estado='encerrado' WHERE id=$1`, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var novoID int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO rh.contratos (tenant_id, funcionario_id, tipo, funcao, data_inicio, data_fim, salario, estado)
		VALUES ($1,$2,$3,$4,$5::date,$6::date,$7,'ativo') RETURNING id`,
		user.TenantID, funcionarioID, tipo, funcao, novoInicio.Format("2006-01-02"), body.DataFim, salario).Scan(&novoID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": novoID}, http.StatusCreated)
}

func (h *Handler) RescindirContrato(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		DataFim *string `json:"data_fim"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.contratos SET estado='rescindido', data_fim=COALESCE($1::date,CURRENT_DATE)
		 WHERE id=$2 AND tenant_id=$3 AND estado='ativo'`,
		body.DataFim, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Contrato não encontrado ou já não está activo", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Ausências ───────────────────────────────────────────────────────────────

func (h *Handler) ListarAusencias(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "a.tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("funcionario_id"); v != "" {
		args = append(args, v)
		where += " AND a.funcionario_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("estado"); v != "" {
		args = append(args, v)
		where += " AND a.estado=$" + strconv.Itoa(len(args))
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT a.id, a.funcionario_id, f.nome_completo, a.tipo_id, ta.nome, a.data_inicio, a.data_fim, a.dias, a.motivo, a.estado, a.aprovado_em
		  FROM rh.ausencias a
		  LEFT JOIN rh.funcionarios f ON f.id = a.funcionario_id
		  LEFT JOIN rh.tipos_ausencia ta ON ta.id = a.tipo_id
		 WHERE `+where+`
		 ORDER BY a.created_at DESC`, args...)
	defer rows.Close()
	type Row struct {
		ID              int64      `json:"id"`
		FuncionarioID   int64      `json:"funcionario_id"`
		FuncionarioNome *string    `json:"funcionario_nome"`
		TipoID          *int64     `json:"tipo_id"`
		TipoNome        *string    `json:"tipo_nome"`
		DataInicio      time.Time  `json:"data_inicio"`
		DataFim         time.Time  `json:"data_fim"`
		Dias            *int       `json:"dias"`
		Motivo          *string    `json:"motivo"`
		Estado          string     `json:"estado"`
		AprovadoEm      *time.Time `json:"aprovado_em"`
	}
	data := []Row{}
	for rows.Next() {
		var a Row
		if rows.Scan(&a.ID, &a.FuncionarioID, &a.FuncionarioNome, &a.TipoID, &a.TipoNome, &a.DataInicio, &a.DataFim, &a.Dias, &a.Motivo, &a.Estado, &a.AprovadoEm) == nil {
			data = append(data, a)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarAusencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		FuncionarioID int64   `json:"funcionario_id"`
		TipoID        int64   `json:"tipo_id"`
		DataInicio    string  `json:"data_inicio"`
		DataFim       string  `json:"data_fim"`
		Motivo        *string `json:"motivo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.FuncionarioID == 0 || body.TipoID == 0 || body.DataInicio == "" || body.DataFim == "" {
		jsonErr(w, "funcionario_id, tipo_id, data_inicio e data_fim são obrigatórios", http.StatusBadRequest)
		return
	}

	var tipoExiste bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.tipos_ausencia WHERE id=$1 AND tenant_id=$2 AND ativo)`, body.TipoID, user.TenantID).Scan(&tipoExiste); err != nil || !tipoExiste {
		jsonErr(w, "Tipo de ausência inválido", http.StatusBadRequest)
		return
	}

	inicio, err1 := time.Parse("2006-01-02", body.DataInicio)
	fim, err2 := time.Parse("2006-01-02", body.DataFim)
	if err1 != nil || err2 != nil || fim.Before(inicio) {
		jsonErr(w, "data_fim deve ser igual ou posterior a data_inicio", http.StatusBadRequest)
		return
	}
	dias := businessDays(inicio, fim)

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.ausencias (tenant_id, funcionario_id, tipo_id, data_inicio, data_fim, dias, motivo, estado)
		VALUES ($1,$2,$3,$4::date,$5::date,$6,$7,'pendente') RETURNING id`,
		user.TenantID, body.FuncionarioID, body.TipoID, body.DataInicio, body.DataFim, dias, body.Motivo).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) AprovarAusencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	var tipoID *int64
	var dias *int
	var dataInicio time.Time
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id, tipo_id, dias, data_inicio FROM rh.ausencias WHERE id=$1 AND tenant_id=$2 AND estado='pendente'`,
		id, user.TenantID).Scan(&funcionarioID, &tipoID, &dias, &dataInicio); err != nil {
		jsonErr(w, "Pedido não encontrado ou já processado", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para aprovar este pedido", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.ausencias SET estado='aprovado', aprovado_por=$1, aprovado_em=NOW()
		 WHERE id=$2 AND tenant_id=$3 AND estado='pendente'`,
		user.ID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Pedido já foi processado", http.StatusConflict)
		return
	}

	if tipoID != nil && dias != nil {
		var afetaSaldo bool
		if h.db.QueryRow(r.Context(), `SELECT afeta_saldo FROM rh.tipos_ausencia WHERE id=$1`, *tipoID).Scan(&afetaSaldo) == nil && afetaSaldo {
			h.ajustarSaldoAusencia(r.Context(), user.TenantID, funcionarioID, *tipoID, dataInicio.Year(), float64(*dias))
		}
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RejeitarAusencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id FROM rh.ausencias WHERE id=$1 AND tenant_id=$2 AND estado='pendente'`,
		id, user.TenantID).Scan(&funcionarioID); err != nil {
		jsonErr(w, "Pedido não encontrado ou já processado", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para rejeitar este pedido", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.ausencias SET estado='rejeitado', aprovado_por=$1, aprovado_em=NOW()
		 WHERE id=$2 AND tenant_id=$3 AND estado='pendente'`,
		user.ID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Pedido já foi processado", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Avaliações ──────────────────────────────────────────────────────────────

func (h *Handler) ListarAvaliacoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "av.tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("funcionario_id"); v != "" {
		args = append(args, v)
		where += " AND av.funcionario_id=$" + strconv.Itoa(len(args))
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT av.id, av.funcionario_id, f.nome_completo, av.periodo_id, p.nome, av.pontuacao, av.comentarios, av.estado, av.created_at,
		       COALESCE((SELECT json_agg(json_build_object('criterio_id', ac.criterio_id, 'criterio_nome', ca.nome, 'pontuacao', ac.pontuacao, 'peso', ca.peso) ORDER BY ca.nome)
		                   FROM rh.avaliacao_criterios ac JOIN rh.criterios_avaliacao ca ON ca.id = ac.criterio_id
		                  WHERE ac.avaliacao_id = av.id), '[]'::json)
		  FROM rh.avaliacoes av
		  LEFT JOIN rh.funcionarios f ON f.id = av.funcionario_id
		  LEFT JOIN rh.periodos_avaliacao p ON p.id = av.periodo_id
		 WHERE `+where+`
		 ORDER BY av.created_at DESC`, args...)
	defer rows.Close()
	type Row struct {
		ID              int64           `json:"id"`
		FuncionarioID   int64           `json:"funcionario_id"`
		FuncionarioNome *string         `json:"funcionario_nome"`
		PeriodoID       *int64          `json:"periodo_id"`
		PeriodoNome     *string         `json:"periodo_nome"`
		Pontuacao       *float64        `json:"pontuacao"`
		Comentarios     *string         `json:"comentarios"`
		Estado          string          `json:"estado"`
		CreatedAt       time.Time       `json:"created_at"`
		Criterios       json.RawMessage `json:"criterios"`
	}
	data := []Row{}
	for rows.Next() {
		var a Row
		if rows.Scan(&a.ID, &a.FuncionarioID, &a.FuncionarioNome, &a.PeriodoID, &a.PeriodoNome, &a.Pontuacao, &a.Comentarios, &a.Estado, &a.CreatedAt, &a.Criterios) == nil {
			data = append(data, a)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarAvaliacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		FuncionarioID int64   `json:"funcionario_id"`
		PeriodoID     int64   `json:"periodo_id"`
		Comentarios   *string `json:"comentarios"`
		Criterios     []struct {
			CriterioID int64   `json:"criterio_id"`
			Pontuacao  float64 `json:"pontuacao"`
		} `json:"criterios"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.FuncionarioID == 0 || body.PeriodoID == 0 || len(body.Criterios) == 0 {
		jsonErr(w, "funcionario_id, periodo_id e critérios são obrigatórios", http.StatusBadRequest)
		return
	}

	var periodoValido bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.periodos_avaliacao WHERE id=$1 AND tenant_id=$2 AND estado='aberto')`,
		body.PeriodoID, user.TenantID).Scan(&periodoValido)
	if !periodoValido {
		jsonErr(w, "Período de avaliação inválido ou encerrado", http.StatusBadRequest)
		return
	}

	if user.Tipo != "superadmin" {
		meuFuncionarioID, err := h.GetUserFuncionario(r.Context(), user.TenantID, user.ID)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if meuFuncionarioID == nil {
			jsonErr(w, "Utilizador sem perfil de funcionário associado", http.StatusForbidden)
			return
		}
		autorizado, err := h.IsResponsavelHierarquico(r.Context(), user.TenantID, *meuFuncionarioID, body.FuncionarioID)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if !autorizado {
			jsonErr(w, "Sem permissão para avaliar este funcionário", http.StatusForbidden)
			return
		}
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var somaPonderada, somaPesos float64
	for _, c := range body.Criterios {
		if c.Pontuacao < 0 {
			jsonErr(w, "Pontuação inválida", http.StatusBadRequest)
			return
		}
		var peso float64
		if err := tx.QueryRow(ctx, `SELECT peso FROM rh.criterios_avaliacao WHERE id=$1 AND tenant_id=$2 AND ativo`,
			c.CriterioID, user.TenantID).Scan(&peso); err != nil {
			jsonErr(w, "Critério de avaliação inválido", http.StatusBadRequest)
			return
		}
		somaPonderada += c.Pontuacao * peso
		somaPesos += peso
	}
	pontuacao := somaPonderada / somaPesos

	var id int64
	if err := tx.QueryRow(ctx, `
		INSERT INTO rh.avaliacoes (tenant_id, funcionario_id, periodo_id, avaliador_id, pontuacao, comentarios, estado)
		VALUES ($1,$2,$3,$4,$5,$6,'rascunho') RETURNING id`,
		user.TenantID, body.FuncionarioID, body.PeriodoID, user.ID, pontuacao, body.Comentarios).Scan(&id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	for _, c := range body.Criterios {
		if _, err := tx.Exec(ctx, `INSERT INTO rh.avaliacao_criterios (avaliacao_id, criterio_id, pontuacao) VALUES ($1,$2,$3)`,
			id, c.CriterioID, c.Pontuacao); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Períodos de Avaliação ───────────────────────────────────────────────────

func (h *Handler) ListarPeriodos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, nome, data_inicio, data_fim, estado
		  FROM rh.periodos_avaliacao WHERE tenant_id=$1 ORDER BY data_inicio DESC`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID         int64     `json:"id"`
		Nome       string    `json:"nome"`
		DataInicio time.Time `json:"data_inicio"`
		DataFim    time.Time `json:"data_fim"`
		Estado     string    `json:"estado"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.Nome, &p.DataInicio, &p.DataFim, &p.Estado) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarPeriodo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Nome       string `json:"nome"`
		DataInicio string `json:"data_inicio"`
		DataFim    string `json:"data_fim"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" || body.DataInicio == "" || body.DataFim == "" {
		jsonErr(w, "nome, data_inicio e data_fim são obrigatórios", http.StatusBadRequest)
		return
	}
	inicio, err1 := time.Parse("2006-01-02", body.DataInicio)
	fim, err2 := time.Parse("2006-01-02", body.DataFim)
	if err1 != nil || err2 != nil || fim.Before(inicio) {
		jsonErr(w, "data_fim deve ser igual ou posterior a data_inicio", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.periodos_avaliacao (tenant_id, nome, data_inicio, data_fim)
		VALUES ($1,$2,$3::date,$4::date) RETURNING id`,
		user.TenantID, body.Nome, body.DataInicio, body.DataFim).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um período com este nome", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarPeriodo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Estado *string `json:"estado"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Estado == nil || !estadosPeriodoValidos[*body.Estado] {
		jsonErr(w, "estado inválido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `UPDATE rh.periodos_avaliacao SET estado=$1 WHERE id=$2 AND tenant_id=$3`,
		*body.Estado, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Período não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
