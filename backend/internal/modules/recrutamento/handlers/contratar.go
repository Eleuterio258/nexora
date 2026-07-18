package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/pessoas"
	"nexora/internal/storage"
)

// ContrataResult dados devolvidos após a contratação de um candidato.
type ContrataResult struct {
	CandidaturaID int64  `json:"candidatura_id"`
	EmployeeID    int64  `json:"rh_employee_id"`
	UserID        int64  `json:"user_id"`
	ContractID    int64  `json:"rh_contract_id"`
	TeacherID     *int64 `json:"teacher_id,omitempty"`
	Mensagem      string `json:"mensagem"`
}

// ContactoEmergenciaInput dados de contacto de emergência do funcionário.
type ContactoEmergenciaInput struct {
	Nome       string  `json:"nome"`
	Parentesco *string `json:"parentesco"`
	Telefone   string  `json:"telefone"`
	Email      *string `json:"email"`
}

// ContratarRequest body opcional para enriquecer a contratação.
type ContratarRequest struct {
	TipoContrato            *string                   `json:"tipo_contrato"`
	SalarioBase             *float64                  `json:"salario_base"`
	DataAdmissao            *string                   `json:"data_admissao"`   // YYYY-MM-DD
	DataNascimento          *string                   `json:"data_nascimento"` // YYYY-MM-DD
	CargoID                 *int64                    `json:"cargo_id"`
	UnitID                  *int64                    `json:"unit_id"`
	HorarioID               *int64                    `json:"horario_id"`
	CentroCustoID           *int64                    `json:"centro_custo_id"`
	DataFim                 *string                   `json:"data_fim"` // YYYY-MM-DD (contrato a prazo)
	Nacionalidade           *string                   `json:"nacionalidade"`
	TipoDocumento           *string                   `json:"tipo_documento"`
	NumeroDocumento         *string                   `json:"numero_documento"`
	Nuit                    *string                   `json:"nuit"`
	AutorizacaoTrabalho     *string                   `json:"autorizacao_trabalho"`
	DataValidadeAutorizacao *string                   `json:"data_validade_autorizacao"` // YYYY-MM-DD
	ExameMedico             *string                   `json:"exame_medico"`              // path relativo no storage
	CriarProfessor          *bool                     `json:"criar_professor"`
	ContactosEmergencia     []ContactoEmergenciaInput `json:"contactos_emergencia"`
}

// ContratarCandidato efectua a contratação de um candidato aprovado:
//  1. Valida a candidatura e o consentimento de dados
//  2. Valida referências do RH e requisitos legais de Moçambique
//  3. Resolve/cria a conta auth.users
//  4. Gera número de funcionário segundo configuração do tenant
//  5. Cria funcionário em rh.funcionarios
//  6. Cria contrato em rh.contratos
//  7. Copia CV/carta/exame médico para rh.documentos_funcionario
//  8. Cria contactos de emergência
//  9. Cria professor na Gestão Escolar (se solicitado)
//
// 10. Marca candidatura como 'contratado' e guarda rh_funcionario_id
// 11. Notifica o candidato (email/SMS/push)
// 12. Regista auditoria
//
// Os passos 1–11 correm dentro de uma transação para garantir atomicidade.
func (h *Handler) ContratarCandidato(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	candIDStr := h.decodeID(chi.URLParam(r, "id"))
	candID, err := strconv.ParseInt(candIDStr, 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}

	var body ContratarRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil && err.Error() != "EOF" {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	// 1. Obter dados da candidatura (bloqueada para atualização)
	var cand struct {
		ID             int64
		Nome           string
		Email          string
		Telefone       *string
		Estado         string
		VagaTitulo     string
		VagaArea       *string
		VagaCargoID    *int64
		VagaCargoNome  *string
		VagaSalarioMin *float64
		VagaSalarioMax *float64
		CandidatoUser  *int64
		Consentimento  bool
		Cidade         *string
		Provincia      *string
		CVFicheiro     *string
		CartaFicheiro  *string
	}
	err = tx.QueryRow(ctx, `
		SELECT c.id, c.nome, c.email, c.telefone, c.estado, c.vaga_titulo, v.area,
		       v.cargo_id, rc.nome, rc.salario_min, rc.salario_max, cd.user_id,
		       c.consentimento_dados, c.cidade, c.provincia, c.cv_ficheiro, c.carta_ficheiro
		FROM recrutamento.candidaturas c
		LEFT JOIN recrutamento.vagas v ON v.id = c.vaga_id
		LEFT JOIN rh.cargos rc ON rc.id = v.cargo_id
		LEFT JOIN recrutamento.candidatos cd ON cd.id = c.candidato_id
		WHERE c.id = $1 AND c.tenant_id = $2
		FOR UPDATE`,
		candID, u.TenantID,
	).Scan(&cand.ID, &cand.Nome, &cand.Email, &cand.Telefone, &cand.Estado, &cand.VagaTitulo,
		&cand.VagaArea, &cand.VagaCargoID, &cand.VagaCargoNome, &cand.VagaSalarioMin, &cand.VagaSalarioMax,
		&cand.CandidatoUser, &cand.Consentimento, &cand.Cidade, &cand.Provincia,
		&cand.CVFicheiro, &cand.CartaFicheiro)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Candidatura não encontrada", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if cand.Estado != "aprovada" {
		jsonErr(w, "Só candidaturas aprovadas podem ser contratadas", http.StatusConflict)
		return
	}
	if !cand.Consentimento {
		jsonErr(w, "Candidato não consentiu o tratamento de dados", http.StatusUnprocessableEntity)
		return
	}

	// 2. Resolver o cargo a aplicar ao funcionário: o cargo definido na vaga
	// é a fonte autoritativa (configurado uma vez, ao criar a vaga); o cargo
	// enviado no pedido serve apenas de reserva para vagas antigas sem cargo
	// definido — nunca substitui o cargo da vaga quando este existe.
	cargoID := cand.VagaCargoID
	if cargoID == nil && body.CargoID != nil && *body.CargoID > 0 {
		var existe bool
		if err := tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM rh.cargos WHERE id=$1 AND tenant_id=$2)`, *body.CargoID, u.TenantID).Scan(&existe); err != nil || !existe {
			jsonErr(w, "Cargo inválido", http.StatusBadRequest)
			return
		}
		cargoID = body.CargoID
	}

	// 2.1. Validar restantes referências do RH (unidade, horário) se fornecidas
	if body.UnitID != nil && *body.UnitID > 0 {
		var existe bool
		if err := tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM rh.unidades_organizacionais WHERE id=$1 AND tenant_id=$2)`, *body.UnitID, u.TenantID).Scan(&existe); err != nil || !existe {
			jsonErr(w, "Unidade organizacional inválida", http.StatusBadRequest)
			return
		}
	}
	if body.HorarioID != nil && *body.HorarioID > 0 {
		var existe bool
		if err := tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM rh.horarios_trabalho WHERE id=$1 AND tenant_id=$2)`, *body.HorarioID, u.TenantID).Scan(&existe); err != nil || !existe {
			jsonErr(w, "Horário de trabalho inválido", http.StatusBadRequest)
			return
		}
	}

	// 2.2. Validações legais de Moçambique
	if err := validarIdade(ptrString(body.DataNascimento)); err != nil {
		jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}
	if estrangeiroSemAutorizacao(
		ptrString(body.Nacionalidade),
		ptrString(body.AutorizacaoTrabalho),
		ptrString(body.DataValidadeAutorizacao),
	) {
		jsonErr(w, "Trabalhador estrangeiro requer autorização de trabalho válida", http.StatusUnprocessableEntity)
		return
	}
	if body.ExameMedico != nil && nomePareceHIV(*body.ExameMedico) {
		jsonErr(w, "É proibido exigir ou arquivar exames de HIV/SIDA", http.StatusUnprocessableEntity)
		return
	}

	// 3. Resolver/criar a conta de utilizador (auth.users)
	var userID int64
	if cand.CandidatoUser != nil {
		userID = *cand.CandidatoUser
	} else {
		err = tx.QueryRow(ctx, `SELECT id FROM auth.users WHERE email = $1`, cand.Email).Scan(&userID)
		if err == pgx.ErrNoRows {
			err = tx.QueryRow(ctx, `
				INSERT INTO auth.users (nome, email, password_hash, estado, tipo)
				VALUES ($1, LOWER($2), '', 'pendente', 'funcionario') RETURNING id`,
				cand.Nome, cand.Email).Scan(&userID)
		}
		if err != nil {
			jsonErr(w, "Erro ao criar conta de utilizador", http.StatusInternalServerError)
			return
		}
	}

	// 3.1. Ligar a conta a uma pessoa (cria uma se ainda não existir — ver
	// docs/analise-modelo-pessoa-multi-tenant.md). Idempotente: se o
	// candidato já tinha conta com pessoa associada, é reutilizada.
	// pessoaID é propagado para rh.funcionarios.pessoa_id no passo 7 e usado
	// no passo 10 para ligar os contactos de emergência (secção 9).
	pessoaID, err := pessoas.EnsureUserPessoa(ctx, tx, userID, cand.Nome, nil)
	if err != nil {
		jsonErr(w, "Erro ao associar pessoa", http.StatusInternalServerError)
		return
	}

	// 4. Garantir membership ERP ativa como funcionário. O conflito é
	// resolvido pela chave composta (user_id, tenant_id, escopo, papel) —
	// "papel" tem de ir explícito no INSERT: com NULL dos dois lados o
	// Postgres não considera NULL=NULL um conflito, e o upsert deixaria de
	// ser idempotente (criaria uma membership nova a cada contratação
	// repetida da mesma pessoa no mesmo tenant).
	_, err = tx.Exec(ctx, `
		INSERT INTO auth.memberships (user_id, tenant_id, escopo, papel, ativo)
		VALUES ($1, $2, 'erp', 'funcionario', true)
		ON CONFLICT (user_id, tenant_id, escopo, papel)
		DO UPDATE SET ativo = true, updated_at = NOW()`,
		userID, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao associar utilizador ao tenant", http.StatusInternalServerError)
		return
	}

	// 5. Gerar número de funcionário
	numero, err := h.proximoNumeroFuncionario(ctx, tx, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao gerar número de funcionário", http.StatusInternalServerError)
		return
	}

	// 6. Preparar dados do funcionário
	dataAdmissao := time.Now()
	if body.DataAdmissao != nil && *body.DataAdmissao != "" {
		if d, err := time.Parse("2006-01-02", *body.DataAdmissao); err == nil {
			dataAdmissao = d
		}
	}

	tipoContrato := "efetivo"
	if body.TipoContrato != nil && *body.TipoContrato != "" {
		tipoContrato = *body.TipoContrato
	}

	var cargo *string
	switch {
	case cand.VagaCargoNome != nil && *cand.VagaCargoNome != "":
		cargo = cand.VagaCargoNome
	case cand.VagaArea != nil && *cand.VagaArea != "":
		cargo = cand.VagaArea
	}

	// Salário: se não for indicado explicitamente, sugere-se a partir da
	// faixa salarial do cargo (mínimo, ou o próprio máximo se não houver
	// mínimo definido) — só uma sugestão de partida, nunca substitui um
	// valor que o recrutador tenha efectivamente indicado.
	salarioBase := body.SalarioBase
	if salarioBase == nil {
		switch {
		case cand.VagaSalarioMin != nil:
			salarioBase = cand.VagaSalarioMin
		case cand.VagaSalarioMax != nil:
			salarioBase = cand.VagaSalarioMax
		}
	}

	telefone := ""
	if cand.Telefone != nil {
		telefone = *cand.Telefone
	}

	// 7. Inserir funcionário
	var dataNascimento interface{}
	if body.DataNascimento != nil && *body.DataNascimento != "" {
		if d, err := time.Parse("2006-01-02", *body.DataNascimento); err == nil {
			dataNascimento = d
		}
	}

	var empID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO rh.funcionarios
		(tenant_id, numero_funcionario, nome_completo, email, telefone, nuit,
		 data_nascimento, provincia, cidade, cargo, cargo_id, unit_id, horario_id, centro_custo_id,
		 data_admissao, tipo_contrato, salario_base, estado, user_id, pessoa_id,
		 nacionalidade, tipo_documento, numero_documento)
		VALUES ($1, $2, $3, LOWER($4), $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, 'ativo', $18, $19, $20, $21, $22)
		RETURNING id`,
		u.TenantID, numero, cand.Nome, cand.Email, nullIfEmpty(telefone), body.Nuit,
		dataNascimento, cand.Provincia, cand.Cidade, cargo, cargoID, body.UnitID, body.HorarioID, body.CentroCustoID,
		dataAdmissao, tipoContrato, salarioBase, userID, pessoaID,
		body.Nacionalidade, body.TipoDocumento, body.NumeroDocumento,
	).Scan(&empID)
	if err != nil {
		jsonErr(w, "Erro ao criar funcionário", http.StatusInternalServerError)
		return
	}

	// 8. Criar contrato
	var contratoID int64
	var dataFim interface{}
	if body.DataFim != nil && *body.DataFim != "" {
		if d, err := time.Parse("2006-01-02", *body.DataFim); err == nil {
			dataFim = d
		}
	}
	err = tx.QueryRow(ctx, `
		INSERT INTO rh.contratos
		(tenant_id, funcionario_id, tipo, funcao, data_inicio, data_fim, salario, estado)
		VALUES ($1, $2, $3, $4, $5, $6, $7, 'ativo')
		RETURNING id`,
		u.TenantID, empID, tipoContrato, cargo, dataAdmissao, dataFim, salarioBase,
	).Scan(&contratoID)
	if err != nil {
		jsonErr(w, "Erro ao criar contrato", http.StatusInternalServerError)
		return
	}

	// 9. Copiar CV e carta para documentos do funcionário
	if cand.CVFicheiro != nil && *cand.CVFicheiro != "" {
		if _, err := h.copiarDocumentoFuncionario(ctx, tx, u.TenantID, empID, *cand.CVFicheiro, "cv"); err != nil {
			jsonErr(w, "Erro ao copiar CV", http.StatusInternalServerError)
			return
		}
	}
	if cand.CartaFicheiro != nil && *cand.CartaFicheiro != "" {
		if _, err := h.copiarDocumentoFuncionario(ctx, tx, u.TenantID, empID, *cand.CartaFicheiro, "carta_motivacao"); err != nil {
			jsonErr(w, "Erro ao copiar carta", http.StatusInternalServerError)
			return
		}
	}

	// 9.1. Copiar exame médico de admissão (se fornecido)
	if body.ExameMedico != nil && *body.ExameMedico != "" {
		if _, err := h.copiarDocumentoFuncionario(ctx, tx, u.TenantID, empID, *body.ExameMedico, "exame_medico_admissao"); err != nil {
			jsonErr(w, "Erro ao copiar exame médico", http.StatusInternalServerError)
			return
		}
	}

	// 10. Criar contactos de emergência (ligados a pessoas.pessoas — secção 9)
	for _, c := range body.ContactosEmergencia {
		if c.Nome == "" || c.Telefone == "" {
			continue
		}
		contactoPessoaID, err := pessoas.EnsurePessoa(ctx, tx, c.Nome)
		if err != nil {
			jsonErr(w, "Erro ao associar pessoa do contacto de emergência", http.StatusInternalServerError)
			return
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO rh.contactos_emergencia
			(tenant_id, funcionario_id, nome, parentesco, telefone, email, pessoa_id)
			VALUES ($1, $2, $3, $4, $5, $6, $7)`,
			u.TenantID, empID, c.Nome, c.Parentesco, c.Telefone, c.Email, contactoPessoaID)
		if err != nil {
			jsonErr(w, "Erro ao criar contacto de emergência", http.StatusInternalServerError)
			return
		}
		parentesco := ""
		if c.Parentesco != nil {
			parentesco = *c.Parentesco
		}
		_ = pessoas.LinkPessoaRelacao(ctx, tx, u.TenantID, contactoPessoaID, pessoaID, parentesco, false)
	}

	// 10.1. Criar professor na Gestão Escolar (se solicitado)
	var teacherID *int64
	if body.CriarProfessor != nil && *body.CriarProfessor {
		codigoProf := fmt.Sprintf("PROF-%s", numero)
		var tid int64
		err = tx.QueryRow(ctx, `
			INSERT INTO gestao_escolar.school_teachers
			(tenant_id, user_id, codigo, nome_completo, genero, telefone, email,
			 documento_identificacao, especialidade, carga_horaria_maxima_semanal, status, rh_employee_id, pessoa_id)
			VALUES ($1, $2, $3, $4, $5, $6, LOWER($7), $8, $9, $10, 'activo', $11, $12)
			RETURNING id`,
			u.TenantID, userID, codigoProf, cand.Nome, nil, nullIfEmpty(telefone), cand.Email,
			body.NumeroDocumento, cargo, 40, empID, pessoaID,
		).Scan(&tid)
		if err != nil {
			jsonErr(w, "Erro ao criar professor", http.StatusInternalServerError)
			return
		}
		teacherID = &tid

		// Ajustar escopo da membership para portal do professor. Filtra
		// também por escopo/papel da membership acabada de criar acima,
		// para não mexer noutra membership da mesma pessoa no mesmo tenant
		// (ex.: se também for aluno).
		_, _ = tx.Exec(ctx, `
			UPDATE auth.memberships SET escopo = 'portal_professor', updated_at = NOW()
			WHERE user_id = $1 AND tenant_id = $2 AND escopo = 'erp' AND papel = 'funcionario'`,
			userID, u.TenantID)
	}

	// 11. Marcar candidatura como contratada e guardar vínculo
	_, err = tx.Exec(ctx, `
		UPDATE recrutamento.candidaturas
		SET estado = 'contratado', rh_funcionario_id = $1, updated_at = NOW()
		WHERE id = $2 AND tenant_id = $3`,
		empID, cand.ID, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar candidatura", http.StatusInternalServerError)
		return
	}

	// 12. Notificar candidato da contratação (dentro da transação — email/SMS)
	varsExtra := map[string]string{
		"numero_funcionario": numero,
		"data_admissao":      dataAdmissao.Format("02/01/2006"),
	}
	if err := h.notificarCandidatura(ctx, tx, u.TenantID, cand.ID, "contratado", varsExtra); err != nil {
		// Não falhar a contratação se a notificação falhar; o erro fica no log do serviço
	}

	// 13. Registar nota de sistema
	_, _ = tx.Exec(ctx, `
		INSERT INTO recrutamento.candidatura_notas (candidatura_id, autor, tipo, conteudo)
		VALUES ($1, 'sistema', 'sistema', $2)`,
		cand.ID, fmt.Sprintf("Candidato contratado como funcionário RH n.º %s (ID %d)", numero, empID))

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro ao finalizar contratação", http.StatusInternalServerError)
		return
	}

	// 14. Push de boas-vindas ao candidato (fora da transação, após commit)
	h.notificarCandidatoPush(ctx, cand.ID, "Recursos Humanos",
		fmt.Sprintf("Foste contratado(a)! Número de funcionário: %s. Bem-vindo(a) à equipa.", numero))

	// 15. Auditoria (fora da transação — não deve falhar a resposta ao cliente)
	detalhesAudit, _ := json.Marshal(map[string]any{
		"candidatura_id":     cand.ID,
		"funcionario_id":     empID,
		"contrato_id":        contratoID,
		"user_id":            userID,
		"numero_funcionario": numero,
		"tipo_contrato":      tipoContrato,
	})
	h.registarAuditoria(ctx, u.TenantID, u.ID, cand.ID, empID, detalhesAudit, r.RemoteAddr)

	result := ContrataResult{
		CandidaturaID: cand.ID,
		EmployeeID:    empID,
		UserID:        userID,
		ContractID:    contratoID,
		TeacherID:     teacherID,
		Mensagem: fmt.Sprintf(
			"Candidato contratado com sucesso. Funcionário RH n.º %s criado a %s.",
			numero, dataAdmissao.Format("02/01/2006"),
		),
	}
	if teacherID != nil {
		result.Mensagem += fmt.Sprintf(" Professor vinculado à Gestão Escolar (id=%d).", *teacherID)
	}
	jsonOK(w, result, http.StatusCreated)
}

// copiarDocumentoFuncionario copia um ficheiro do recrutamento para o storage de RH
// e regista-o em rh.documentos_funcionario. Devolve o ID do documento criado.
func (h *Handler) copiarDocumentoFuncionario(ctx context.Context, tx pgx.Tx, tenantID, funcionarioID int64, origemRel, tipo string) (int64, error) {
	origemKey := storage.JoinPath("uploads", fmt.Sprintf("tenant-%d", tenantID), origemRel)

	reader, _, err := h.storage.Get(ctx, origemKey)
	if err != nil {
		return 0, fmt.Errorf("ficheiro origem não encontrado: %w", err)
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return 0, fmt.Errorf("erro ao ler ficheiro origem: %w", err)
	}

	ext := filepath.Ext(origemRel)
	base := filepath.Base(origemRel)
	novoNome := fmt.Sprintf("%s_%d%s", base[:len(base)-len(ext)], time.Now().Unix(), ext)
	destinoRel := storage.JoinPath("rh", "documentos", tipo, novoNome)
	destinoKey := storage.JoinPath("uploads", fmt.Sprintf("tenant-%d", tenantID), destinoRel)

	contentType := "application/octet-stream"
	if ext == ".pdf" {
		contentType = "application/pdf"
	}

	if _, err := h.storage.Put(ctx, destinoKey, data, contentType); err != nil {
		return 0, fmt.Errorf("erro ao guardar documento RH: %w", err)
	}

	var docID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO rh.documentos_funcionario
		(tenant_id, funcionario_id, tipo, ficheiro_url)
		VALUES ($1, $2, $3, $4)
		RETURNING id`,
		tenantID, funcionarioID, tipo, destinoRel,
	).Scan(&docID)
	if err != nil {
		return 0, fmt.Errorf("erro ao registar documento: %w", err)
	}
	return docID, nil
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
			if v != "" {
				sep = v
			}
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

// proximoNumeroFuncionario devolve o próximo número sequencial dentro da transação.
func (h *Handler) proximoNumeroFuncionario(ctx context.Context, tx pgx.Tx, tenantID int64) (string, error) {
	prefixo, sep, digitos, inicio := h.rhNumConfig(ctx, tenantID)
	padrao := fmt.Sprintf(`^%s%s[0-9]+$`, prefixo, sep)
	var maxSeq int
	err := tx.QueryRow(ctx, `
		SELECT COALESCE(MAX(
			CASE WHEN numero_funcionario ~ $2
			THEN CAST(SUBSTRING(numero_funcionario FROM '[0-9]+$') AS INTEGER)
			ELSE 0 END
		), 0)
		FROM rh.funcionarios WHERE tenant_id=$1`, tenantID, padrao).Scan(&maxSeq)
	if err != nil {
		return "", err
	}
	proxima := maxSeq + 1
	if proxima < inicio {
		proxima = inicio
	}
	formato := fmt.Sprintf("%%s%%s%%0%dd", digitos)
	return fmt.Sprintf(formato, prefixo, sep, proxima), nil
}

// validarIdade verifica se o candidato tem idade mínima legal (18 anos).
// A admissão de menores (15-17) exige autorização do representante legal,
// que neste fluxo não é suportada, pelo que é rejeitada.
func validarIdade(dataNascimento string) error {
	if dataNascimento == "" {
		return fmt.Errorf("data de nascimento é obrigatória")
	}
	d, err := time.Parse("2006-01-02", dataNascimento)
	if err != nil {
		return fmt.Errorf("data de nascimento inválida")
	}
	idade := time.Now().Year() - d.Year()
	if time.Now().Month() < d.Month() || (time.Now().Month() == d.Month() && time.Now().Day() < d.Day()) {
		idade--
	}
	if idade < 18 {
		return fmt.Errorf("idade inferior à mínima legal (18 anos)")
	}
	return nil
}

// normalizarNacionalidade compara de forma tolerante a nacionalidade.
func normalizarNacionalidade(n string) string {
	if n == "" {
		return ""
	}
	n = strings.ToLower(strings.TrimSpace(n))
	n = strings.ReplaceAll(n, "ç", "c")
	n = strings.ReplaceAll(n, "ã", "a")
	return n
}

// estrangeiroSemAutorizacao verifica se é trabalhador estrangeiro sem autorização válida.
func estrangeiroSemAutorizacao(nacionalidade, autorizacao, validade string) bool {
	if normalizarNacionalidade(nacionalidade) == "" || normalizarNacionalidade(nacionalidade) == "mocambicana" {
		return false
	}
	if strings.TrimSpace(autorizacao) == "" {
		return true
	}
	if validade != "" {
		if d, err := time.Parse("2006-01-02", validade); err == nil && d.Before(time.Now()) {
			return true
		}
	}
	return false
}

// nomePareceHIV detecta nomes de ficheiro que indiquem exame de HIV/SIDA.
func nomePareceHIV(nome string) bool {
	n := strings.ToLower(nome)
	palavras := []string{"hiv", "sida", "aids", "vih", "sid", "hivsida", "sidahiv"}
	for _, p := range palavras {
		if strings.Contains(n, p) {
			return true
		}
	}
	return false
}

// registarAuditoria grava um log da contratação em auditoria.audit_logs.
func (h *Handler) registarAuditoria(ctx context.Context, tenantID, userID, candidaturaID, funcionarioID int64, detalhes json.RawMessage, ip string) {
	h.db.Exec(ctx, `
		INSERT INTO auditoria.audit_logs (tenant_id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address)
		VALUES ($1, $2, 'recrutamento', 'candidatura_contratacao', $3, 'contratar', $4, $5)`,
		tenantID, userID, candidaturaID, detalhes, ip)
}

// ptrString converte *string em string vazia quando nil.
func ptrString(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
