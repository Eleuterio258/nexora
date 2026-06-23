package handlers

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarMensagensEscolares(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "m.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "m.status", r.URL.Query().Get("status"))
	appendSchoolFilter(&where, &args, "m.audience_type", r.URL.Query().Get("audience_type"))
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(m) ORDER BY m.created_at DESC),'[]')
		FROM gestao_escolar.school_messages m WHERE `+where, args...)
}

func (h *Handler) CriarMensagemEscolar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_messages
		(tenant_id,titulo,conteudo,tipo,audience_type,audience_id,created_by)
		SELECT $1,j.titulo,j.conteudo,COALESCE(j.tipo,'comunicado'),COALESCE(j.audience_type,'todos'),j.audience_id,$3
		FROM jsonb_to_record($2::jsonb) AS j(titulo text,conteudo text,tipo text,audience_type text,audience_id bigint)
		WHERE j.titulo<>'' AND j.conteudo<>'' RETURNING id`, u.TenantID, body, u.ID)
}

func (h *Handler) PublicarMensagemEscolar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_messages SET
		status='publicado',publicado_em=NOW(),updated_at=NOW()
		WHERE id=$1 AND tenant_id=$2 AND status='rascunho'`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) DashboardDireccao(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT jsonb_build_object(
		'alunos_activos',(SELECT COUNT(*) FROM gestao_escolar.school_students WHERE tenant_id=$1 AND estado='activo'),
		'matriculas_activas',(SELECT COUNT(*) FROM gestao_escolar.school_enrollments WHERE tenant_id=$1 AND status='activa'),
		'turmas_activas',(SELECT COUNT(*) FROM gestao_escolar.school_classes WHERE tenant_id=$1 AND activo),
		'presenca_hoje',(SELECT COALESCE(ROUND(100.0*COUNT(*) FILTER(WHERE estado='presente')/NULLIF(COUNT(*),0),2),0)
			FROM gestao_escolar.school_attendance WHERE tenant_id=$1 AND attendance_date=CURRENT_DATE),
		'cobrancas_pendentes',(SELECT COUNT(*) FROM gestao_escolar.school_fees WHERE tenant_id=$1 AND status IN ('pendente','emitida','parcial')),
		'saldo_em_aberto',(SELECT COALESCE(SUM(GREATEST(valor_total-desconto-valor_pago,0)),0)
			FROM gestao_escolar.school_fees WHERE tenant_id=$1 AND status IN ('pendente','emitida','parcial')),
		'emprestimos_atrasados',(SELECT COUNT(*) FROM gestao_escolar.school_library_loans
			WHERE tenant_id=$1 AND status='emprestado' AND devolucao_prevista<CURRENT_DATE),
		'comunicados_publicados',(SELECT COUNT(*) FROM gestao_escolar.school_messages WHERE tenant_id=$1 AND status='publicado')
		)`, u.TenantID)
}

func (h *Handler) RelatorioAcademico(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	term := r.URL.Query().Get("term_id")
	if term == "" {
		term = "0"
	}
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.turma,x.disciplina),'[]') FROM (
		SELECT c.id class_id,c.nome turma,s.id subject_id,s.nome disciplina,COUNT(DISTINCT g.student_id) alunos_avaliados,
		ROUND(AVG(g.nota),2) media,ROUND(MIN(g.nota),2) nota_minima,ROUND(MAX(g.nota),2) nota_maxima,
		ROUND(100.0*COUNT(*) FILTER(WHERE g.nota>=s.nota_minima)/NULLIF(COUNT(*),0),2) taxa_aprovacao
		FROM gestao_escolar.school_grade_items i JOIN gestao_escolar.school_grades g ON g.grade_item_id=i.id
		JOIN gestao_escolar.school_classes c ON c.id=i.class_id JOIN gestao_escolar.school_subjects s ON s.id=i.subject_id
		WHERE i.tenant_id=$1 AND ($2::bigint=0 OR i.term_id=$2) GROUP BY c.id,s.id) x`, u.TenantID, term)
}

func (h *Handler) RelatorioFinanceiroEscolar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT jsonb_build_object(
		'total_facturado',COALESCE(SUM(valor_total-desconto),0),
		'total_recebido',COALESCE(SUM(valor_pago),0),
		'total_em_aberto',COALESCE(SUM(GREATEST(valor_total-desconto-valor_pago,0)),0),
		'total_vencido',COALESCE(SUM(GREATEST(valor_total-desconto-valor_pago,0))
			FILTER(WHERE data_vencimento<CURRENT_DATE),0),
		'cobrancas',COUNT(*),
		'pagas',COUNT(*) FILTER(WHERE status='paga'),
		'pendentes',COUNT(*) FILTER(WHERE status IN ('pendente','emitida','parcial')))
		FROM gestao_escolar.school_fees WHERE tenant_id=$1`, u.TenantID)
}

func (h *Handler) RelatorioInadimplencia(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.saldo_vencido DESC),'[]') FROM (
		SELECT s.id student_id,s.codigo,s.nome,COUNT(f.id) cobrancas_vencidas,
		MIN(f.data_vencimento) vencimento_mais_antigo,
		SUM(GREATEST(f.valor_total-f.desconto-f.valor_pago,0)) saldo_vencido
		FROM gestao_escolar.school_students s JOIN gestao_escolar.school_fees f ON f.student_id=s.id
		WHERE s.tenant_id=$1 AND f.data_vencimento<CURRENT_DATE
		AND f.status IN ('pendente','emitida','parcial') GROUP BY s.id
		HAVING SUM(GREATEST(f.valor_total-f.desconto-f.valor_pago,0))>0) x`, u.TenantID)
}
