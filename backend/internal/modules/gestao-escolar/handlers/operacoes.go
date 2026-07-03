package handlers

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarPlanosPropinas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(p) ORDER BY p.nome),'[]')
		FROM gestao_escolar.school_fee_plans p WHERE tenant_id=$1`, u.TenantID)
}

func (h *Handler) ObterPlanoPropina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT to_jsonb(p) FROM gestao_escolar.school_fee_plans p
		WHERE p.id=$1 AND p.tenant_id=$2`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) CriarPlanoPropina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_fee_plans
		(tenant_id,school_year_id,codigo,nome,tipo,valor,moeda,periodicidade,dia_vencimento,classe_nivel)
		SELECT $1,j.year_id,j.codigo,j.nome,COALESCE(j.tipo,'propina'),j.valor,COALESCE(j.moeda,'MZN'),
		COALESCE(j.periodicidade,'mensal'),j.dia_vencimento,j.classe_nivel
		FROM jsonb_to_record($2::jsonb) AS j(year_id bigint,codigo text,nome text,tipo text,valor numeric,
		moeda text,periodicidade text,dia_vencimento int,classe_nivel text)
		WHERE j.codigo<>'' AND j.nome<>'' AND j.valor>=0 RETURNING id`, u.TenantID, body)
}

func (h *Handler) GerarCobrancaAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_fees
		(tenant_id,enrollment_id,student_id,fee_plan_id,numero,descricao,mes_referencia,data_vencimento,
		valor_total,moeda,entidade,referencia)
		SELECT $1,e.id,e.student_id,p.id,j.numero,COALESCE(j.descricao,p.nome),j.mes_referencia,j.data_vencimento,
		COALESCE(j.valor,p.valor),p.moeda,j.entidade,j.referencia
		FROM jsonb_to_record($2::jsonb) AS j(enrollment_id bigint,fee_plan_id bigint,numero text,descricao text,
		mes_referencia text,data_vencimento date,valor numeric,entidade text,referencia text)
		JOIN gestao_escolar.school_enrollments e ON e.id=j.enrollment_id AND e.tenant_id=$1
		JOIN gestao_escolar.school_fee_plans p ON p.id=j.fee_plan_id AND p.tenant_id=$1
		WHERE j.numero<>'' RETURNING school_fees.id`, u.TenantID, body)
}

func (h *Handler) ListarCobrancasAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "f.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "f.student_id", r.URL.Query().Get("student_id"))
	appendSchoolFilter(&where, &args, "f.status", r.URL.Query().Get("status"))
	if v := r.URL.Query().Get("vencimento_ate"); v != "" {
		args = append(args, v)
		where += " AND f.data_vencimento<=$" + strconv.Itoa(len(args))
	}
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.data_vencimento DESC),'[]') FROM (
		SELECT f.*,s.codigo aluno_codigo,s.nome aluno,GREATEST(f.valor_total-f.desconto-f.valor_pago,0) saldo
		FROM gestao_escolar.school_fees f JOIN gestao_escolar.school_students s ON s.id=f.student_id
		WHERE `+where+`) x`, args...)
}

func (h *Handler) ObterCobrancaAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT to_jsonb(f)||jsonb_build_object('aluno',to_jsonb(s),
		'saldo',GREATEST(f.valor_total-f.desconto-f.valor_pago,0),
		'pagamentos',COALESCE((SELECT jsonb_agg(to_jsonb(p) ORDER BY p.pago_em DESC)
		FROM gestao_escolar.school_payments p WHERE p.school_fee_id=f.id),'[]'))
		FROM gestao_escolar.school_fees f JOIN gestao_escolar.school_students s ON s.id=f.student_id
		WHERE f.id=$1 AND f.tenant_id=$2`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) EmitirCobrancaAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_fees SET status='emitida',emitida_em=NOW(),updated_at=NOW()
		WHERE id=$1 AND tenant_id=$2 AND status='pendente'`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) CallbackPagamentoEscolar(w http.ResponseWriter, r *http.Request) {
	// Validar assinatura HMAC-SHA256 do gateway quando segredo configurado
	if h.cfg.GatewayWebhookSecret != "" {
		rawBody, err := io.ReadAll(io.LimitReader(r.Body, 2<<20))
		if err != nil {
			jsonErr(w, "Erro ao ler corpo", http.StatusBadRequest)
			return
		}
		// Repor body para leitura posterior por registarPagamento
		r.Body = io.NopCloser(bytes.NewReader(rawBody))

		sig := r.Header.Get("X-Signature")
		if !validarAssinaturaWebhook(rawBody, sig, h.cfg.GatewayWebhookSecret) {
			jsonErr(w, "Assinatura inválida", http.StatusUnauthorized)
			return
		}
	}
	h.registarPagamento(w, r, true)
}

// validarAssinaturaWebhook verifica HMAC-SHA256 no formato "sha256=<hex>".
func validarAssinaturaWebhook(body []byte, signature, secret string) bool {
	if len(signature) < 7 || signature[:7] != "sha256=" {
		return false
	}
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(signature[7:]), []byte(expected))
}

func (h *Handler) registarPagamento(w http.ResponseWriter, r *http.Request, callback bool) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", 500)
		return
	}
	defer tx.Rollback(r.Context())
	var id int64
	err = tx.QueryRow(r.Context(), `INSERT INTO gestao_escolar.school_payments
		(tenant_id,school_fee_id,student_id,external_id,metodo,referencia,valor,moeda,status,conciliado,created_by,payload_gateway)
		SELECT $1,f.id,f.student_id,j.external_id,j.metodo,j.referencia,j.valor,COALESCE(j.moeda,f.moeda),
		COALESCE(j.status,'confirmado'),$4,$3,CASE WHEN $4 THEN $2::jsonb ELSE NULL END
		FROM jsonb_to_record($2::jsonb) AS j(fee_id bigint,external_id text,metodo text,referencia text,
		valor numeric,moeda text,status text)
		JOIN gestao_escolar.school_fees f ON f.id=j.fee_id AND f.tenant_id=$1
		WHERE j.valor>0 AND j.valor<=GREATEST(f.valor_total-f.desconto-f.valor_pago,0) RETURNING school_payments.id`,
		u.TenantID, body, u.ID, callback).Scan(&id)
	if err != nil {
		jsonErr(w, "Pagamento duplicado, excessivo ou cobranca invalida", http.StatusUnprocessableEntity)
		return
	}
	_, err = tx.Exec(r.Context(), `UPDATE gestao_escolar.school_fees f SET
		valor_pago=f.valor_pago+p.valor,
		status=CASE WHEN f.valor_pago+p.valor>=f.valor_total-f.desconto THEN 'paga' ELSE 'parcial' END,
		updated_at=NOW() FROM gestao_escolar.school_payments p
		WHERE p.id=$1 AND p.school_fee_id=f.id AND p.status='confirmado'`, id)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao confirmar pagamento", 500)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterPagamentoEscolar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT to_jsonb(p)||jsonb_build_object('cobranca',to_jsonb(f),'aluno',to_jsonb(s))
		FROM gestao_escolar.school_payments p JOIN gestao_escolar.school_fees f ON f.id=p.school_fee_id
		JOIN gestao_escolar.school_students s ON s.id=p.student_id WHERE p.id=$1 AND p.tenant_id=$2`,
		chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ObterReciboEscolar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT jsonb_build_object('numero','RE-'||LPAD(p.id::text,8,'0'),'pagamento_id',p.id,
		'pago_em',p.pago_em,'metodo',p.metodo,'referencia',p.referencia,'valor',p.valor,'moeda',p.moeda,
		'aluno',jsonb_build_object('id',s.id,'codigo',s.codigo,'nome',s.nome),
		'cobranca',jsonb_build_object('id',f.id,'numero',f.numero,'descricao',f.descricao))
		FROM gestao_escolar.school_payments p JOIN gestao_escolar.school_fees f ON f.id=p.school_fee_id
		JOIN gestao_escolar.school_students s ON s.id=p.student_id
		WHERE p.id=$1 AND p.tenant_id=$2 AND p.status='confirmado'`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ListarLivros(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(b) ORDER BY b.titulo),'[]')
		FROM gestao_escolar.school_books b WHERE tenant_id=$1`, u.TenantID)
}

func (h *Handler) CriarLivro(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_books
		(tenant_id,isbn,codigo,titulo,autor,editora,ano_publicacao,categoria,exemplares_total,exemplares_disponiveis)
		SELECT $1,j.isbn,j.codigo,j.titulo,j.autor,j.editora,j.ano_publicacao,j.categoria,
		COALESCE(j.exemplares,1),COALESCE(j.exemplares,1)
		FROM jsonb_to_record($2::jsonb) AS j(isbn text,codigo text,titulo text,autor text,editora text,
		ano_publicacao int,categoria text,exemplares int)
		WHERE j.codigo<>'' AND j.titulo<>'' AND COALESCE(j.exemplares,1)>0 RETURNING id`, u.TenantID, body)
}

func (h *Handler) ListarEmprestimos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "l.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "l.status", r.URL.Query().Get("status"))
	appendSchoolFilter(&where, &args, "l.student_id", r.URL.Query().Get("student_id"))
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.emprestado_em DESC),'[]') FROM (
		SELECT l.*,b.codigo livro_codigo,b.titulo,s.nome aluno,
		(l.status='emprestado' AND l.devolucao_prevista<CURRENT_DATE) atrasado
		FROM gestao_escolar.school_library_loans l JOIN gestao_escolar.school_books b ON b.id=l.book_id
		LEFT JOIN gestao_escolar.school_students s ON s.id=l.student_id WHERE `+where+`) x`, args...)
}

func (h *Handler) RegistarEmprestimo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var id int64
	err = tx.QueryRow(r.Context(), `INSERT INTO gestao_escolar.school_library_loans
		(tenant_id,book_id,student_id,borrower_type,borrower_id,emprestado_em,devolucao_prevista,observacoes,created_by)
		SELECT $1,b.id,j.student_id,COALESCE(j.borrower_type,'aluno'),j.borrower_id,
		COALESCE(j.emprestado_em,CURRENT_DATE),j.devolucao_prevista,j.observacoes,$3
		FROM jsonb_to_record($2::jsonb) AS j(book_id bigint,student_id bigint,borrower_type text,
		borrower_id bigint,emprestado_em date,devolucao_prevista date,observacoes text)
		JOIN gestao_escolar.school_books b ON b.id=j.book_id AND b.tenant_id=$1
		WHERE b.exemplares_disponiveis>0 AND j.devolucao_prevista>=COALESCE(j.emprestado_em,CURRENT_DATE)
		RETURNING school_library_loans.id`, u.TenantID, body, u.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Livro indisponivel ou dados invalidos", http.StatusConflict)
		return
	}
	_, err = tx.Exec(r.Context(), `UPDATE gestao_escolar.school_books b SET exemplares_disponiveis=exemplares_disponiveis-1,
		updated_at=NOW() FROM gestao_escolar.school_library_loans l WHERE l.id=$1 AND b.id=l.book_id`, id)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro interno", 500)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ConfirmarDevolucao(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var bookID int64
	err := tx.QueryRow(r.Context(), `UPDATE gestao_escolar.school_library_loans SET
		status='devolvido',devolvido_em=CURRENT_DATE WHERE id=$1 AND tenant_id=$2
		AND status IN ('emprestado','atrasado') RETURNING book_id`, chi.URLParam(r, "id"), u.TenantID).Scan(&bookID)
	if err != nil {
		jsonErr(w, "Emprestimo nao encontrado ou ja devolvido", http.StatusConflict)
		return
	}
	_, _ = tx.Exec(r.Context(), `UPDATE gestao_escolar.school_books SET
		exemplares_disponiveis=LEAST(exemplares_total,exemplares_disponiveis+1),updated_at=NOW() WHERE id=$1`, bookID)
	if tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro interno", 500)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
