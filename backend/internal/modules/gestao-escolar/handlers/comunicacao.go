package handlers

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
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
	msgID := chi.URLParam(r, "id")

	// Actualiza o status e devolve dados da mensagem para notificar
	var titulo, audienceType string
	var audienceID *int64
	err := h.db.QueryRow(r.Context(), `
		UPDATE gestao_escolar.school_messages
		SET status='publicado', publicado_em=NOW(), updated_at=NOW()
		WHERE id=$1 AND tenant_id=$2 AND status='rascunho'
		RETURNING titulo, audience_type, audience_id`, msgID, u.TenantID,
	).Scan(&titulo, &audienceType, &audienceID)
	if err != nil {
		jsonErr(w, "Mensagem nao encontrada ou ja publicada", http.StatusNotFound)
		return
	}

	// Notificar destinatários da mensagem em background (capturar variáveis antes do go)
	tenantID, msgTitulo, audType, audID := u.TenantID, titulo, audienceType, audienceID
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		// Preferir portal_email; fallback para auth.users.email
		var query string
		var args []any
		switch audType {
		case "todos":
			query = `SELECT COALESCE(NULLIF(s.portal_email,''), u.email) email, s.id
				  FROM gestao_escolar.school_students s
				  LEFT JOIN auth.users u ON u.id = s.user_id
				 WHERE s.tenant_id = $1 AND s.estado = 'activo'
				   AND COALESCE(NULLIF(s.portal_email,''), u.email) IS NOT NULL`
			args = []any{tenantID}
		case "turma":
			if audID == nil {
				return
			}
			query = `SELECT COALESCE(NULLIF(s.portal_email,''), u.email) email, s.id
				  FROM gestao_escolar.school_enrollments e
				  JOIN gestao_escolar.school_students s ON s.id = e.student_id
				  LEFT JOIN auth.users u ON u.id = s.user_id
				 WHERE e.class_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'
				   AND COALESCE(NULLIF(s.portal_email,''), u.email) IS NOT NULL`
			args = []any{*audID, tenantID}
		default:
			return
		}

		rows, err := h.db.Query(ctx, query, args...)
		if err != nil {
			return
		}
		defer rows.Close()
		for rows.Next() {
			var email string
			var studentID int64
			if rows.Scan(&email, &studentID) == nil && h.notification != nil {
				sid := studentID
				h.notification.Send(ctx, contracts.Notification{
					TenantID:       tenantID,
					CanalTipo:      "email",
					Destinatario:   email,
					Assunto:        fmt.Sprintf("Comunicado: %s", msgTitulo),
					Corpo:          fmt.Sprintf("Foi publicado um novo comunicado escolar: \"%s\". Aceda ao portal para ler a mensagem completa.", msgTitulo),
					ReferenciaTipo: "escolar.mensagem",
					ReferenciaID:   &sid,
				})
			}
		}
	}()

	w.WriteHeader(http.StatusNoContent)
}

// ── GET /api/escolar/notificacoes ─────────────────────────────────────────────
// Log de notificações enviadas pelo módulo escolar (últimos 30 dias).

func (h *Handler) ListarNotificacoesEscolares(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC), '[]') FROM (
			SELECT id, canal_tipo, destinatario, assunto, corpo,
			       referencia_tipo, referencia_id, status, tentativas,
			       erro, enviado_em, created_at
			  FROM notifications.notification_messages
			 WHERE tenant_id = $1
			   AND referencia_tipo LIKE 'escolar.%%'
			   AND created_at >= NOW() - INTERVAL '30 days'
			 LIMIT 500
		) x`, u.TenantID)
}

func (h *Handler) DashboardEscolar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT jsonb_build_object(
		'alunos',(SELECT COUNT(*) FROM gestao_escolar.school_students WHERE tenant_id=$1 AND estado='activo'),
		'turmas',(SELECT COUNT(*) FROM gestao_escolar.school_classes WHERE tenant_id=$1 AND activo),
		'professores',(SELECT COUNT(*) FROM gestao_escolar.school_teachers WHERE tenant_id=$1 AND status='activo'),
		'matriculas_activas',(SELECT COUNT(*) FROM gestao_escolar.school_enrollments WHERE tenant_id=$1 AND status='activa'),
		'disciplinas',(SELECT COUNT(*) FROM gestao_escolar.school_subjects WHERE tenant_id=$1 AND activo),
		'anos_lectivos',(SELECT COUNT(*) FROM gestao_escolar.school_years WHERE tenant_id=$1),
		'ano_activo',(SELECT nome FROM gestao_escolar.school_years WHERE tenant_id=$1 AND status='activo' ORDER BY id DESC LIMIT 1),
		'turmas_activas',(SELECT COUNT(*) FROM gestao_escolar.school_classes WHERE tenant_id=$1 AND activo),
		'presenca_hoje',(SELECT COALESCE(ROUND(100.0*COUNT(*) FILTER(WHERE estado='presente')/NULLIF(COUNT(*),0),1),0)
			FROM gestao_escolar.school_attendance WHERE tenant_id=$1 AND attendance_date=CURRENT_DATE),
		'registos_presenca_hoje',(SELECT COUNT(*) FROM gestao_escolar.school_attendance WHERE tenant_id=$1 AND attendance_date=CURRENT_DATE),
		'total_facturado',(SELECT COALESCE(SUM(valor_total-desconto),0) FROM gestao_escolar.school_fees WHERE tenant_id=$1),
		'total_recebido',(SELECT COALESCE(SUM(valor_pago),0) FROM gestao_escolar.school_fees WHERE tenant_id=$1),
		'total_em_aberto',(SELECT COALESCE(SUM(GREATEST(valor_total-desconto-valor_pago,0)),0)
			FROM gestao_escolar.school_fees WHERE tenant_id=$1 AND status IN ('pendente','emitida','parcial')),
		'total_vencido',(SELECT COALESCE(SUM(GREATEST(valor_total-desconto-valor_pago,0)),0)
			FROM gestao_escolar.school_fees WHERE tenant_id=$1 AND status IN ('pendente','emitida','parcial') AND data_vencimento<CURRENT_DATE),
		'cobrancas_pendentes',(SELECT COUNT(*) FROM gestao_escolar.school_fees WHERE tenant_id=$1 AND status IN ('pendente','emitida','parcial')),
		'cobrancas_pagas',(SELECT COUNT(*) FROM gestao_escolar.school_fees WHERE tenant_id=$1 AND status='paga'),
		'avaliacoes',(SELECT COUNT(*) FROM gestao_escolar.school_grade_items WHERE tenant_id=$1),
		'notas_lancadas',(SELECT COUNT(*) FROM gestao_escolar.school_grades WHERE tenant_id=$1),
		'atribuicoes',(SELECT COUNT(*) FROM gestao_escolar.school_teacher_assignments WHERE tenant_id=$1),
		'livros',(SELECT COUNT(*) FROM gestao_escolar.school_books WHERE tenant_id=$1),
		'emprestimos_activos',(SELECT COUNT(*) FROM gestao_escolar.school_library_loans WHERE tenant_id=$1 AND status='emprestado'),
		'emprestimos_atrasados',(SELECT COUNT(*) FROM gestao_escolar.school_library_loans
			WHERE tenant_id=$1 AND status='emprestado' AND devolucao_prevista<CURRENT_DATE),
		'comunicados_publicados',(SELECT COUNT(*) FROM gestao_escolar.school_messages WHERE tenant_id=$1 AND status='publicado'),
		'comunicados_rascunho',(SELECT COUNT(*) FROM gestao_escolar.school_messages WHERE tenant_id=$1 AND status='rascunho'),
		'inadimplentes',(SELECT COUNT(DISTINCT student_id) FROM gestao_escolar.school_fees
			WHERE tenant_id=$1 AND data_vencimento<CURRENT_DATE AND status IN ('pendente','emitida','parcial')),
		'ocorrencias_abertas',(SELECT COUNT(*) FROM gestao_escolar.school_student_incidents WHERE tenant_id=$1 AND status IN ('registada','em_analise')),
		'recentes_matriculas',(SELECT COALESCE(jsonb_agg(x ORDER BY x.criado DESC),'{}') FROM (
			SELECT e.id,e.created_at criado,s.nome aluno,s.codigo,c.nome turma
			FROM gestao_escolar.school_enrollments e
			JOIN gestao_escolar.school_students s ON s.id=e.student_id
			JOIN gestao_escolar.school_classes c ON c.id=e.class_id
			WHERE e.tenant_id=$1 AND e.status='activa' ORDER BY e.created_at DESC LIMIT 5) x),
		'recentes_pagamentos',(SELECT COALESCE(jsonb_agg(x ORDER BY x.pago_em DESC),'{}') FROM (
			SELECT p.id,p.pago_em,p.valor,p.moeda,p.metodo,s.nome aluno
			FROM gestao_escolar.school_payments p
			JOIN gestao_escolar.school_students s ON s.id=p.student_id
			WHERE p.tenant_id=$1 AND p.status='confirmado' ORDER BY p.pago_em DESC LIMIT 5) x)
	)`, u.TenantID)
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

// ── GET /api/escolar/relatorios/aging ────────────────────────────────────────
// Aging report de inadimplência com buckets de 30/60/90 dias (6.5).

func (h *Handler) RelatorioAging(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)

	// Resumo por faixa (para o painel de topo)
	var sumario any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.faixa), '[]') FROM (
			SELECT
				CASE
					WHEN CURRENT_DATE - f.data_vencimento <= 30  THEN '0-30'
					WHEN CURRENT_DATE - f.data_vencimento <= 60  THEN '31-60'
					WHEN CURRENT_DATE - f.data_vencimento <= 90  THEN '61-90'
					ELSE '90+'
				END faixa,
				CASE
					WHEN CURRENT_DATE - f.data_vencimento <= 30  THEN 1
					WHEN CURRENT_DATE - f.data_vencimento <= 60  THEN 2
					WHEN CURRENT_DATE - f.data_vencimento <= 90  THEN 3
					ELSE 4
				END faixa_ordem,
				COUNT(*)                                           cobrancas,
				COUNT(DISTINCT f.student_id)                      alunos,
				SUM(GREATEST(f.valor_total-f.desconto-f.valor_pago,0)) saldo,
				f.moeda
			FROM gestao_escolar.school_fees f
			WHERE f.tenant_id = $1
			  AND f.status IN ('emitida','parcial')
			  AND f.data_vencimento < CURRENT_DATE
			GROUP BY faixa, faixa_ordem, f.moeda
		) x`, u.TenantID,
	).Scan(&sumario)

	// Detalhe por aluno com faixa individual
	var detalhe any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.dias_atraso DESC), '[]') FROM (
			SELECT s.id student_id, s.codigo, s.nome,
				COUNT(f.id)                                                     cobrancas,
				MAX(CURRENT_DATE - f.data_vencimento)                           dias_atraso,
				SUM(GREATEST(f.valor_total-f.desconto-f.valor_pago,0))          saldo,
				f.moeda,
				CASE
					WHEN MAX(CURRENT_DATE - f.data_vencimento) <= 30 THEN '0-30'
					WHEN MAX(CURRENT_DATE - f.data_vencimento) <= 60 THEN '31-60'
					WHEN MAX(CURRENT_DATE - f.data_vencimento) <= 90 THEN '61-90'
					ELSE '90+'
				END faixa
			FROM gestao_escolar.school_fees f
			JOIN gestao_escolar.school_students s ON s.id = f.student_id
			WHERE f.tenant_id = $1
			  AND f.status IN ('emitida','parcial')
			  AND f.data_vencimento < CURRENT_DATE
			GROUP BY s.id, s.codigo, s.nome, f.moeda
			HAVING SUM(GREATEST(f.valor_total-f.desconto-f.valor_pago,0)) > 0
		) x`, u.TenantID,
	).Scan(&detalhe)

	jsonOK(w, map[string]any{"sumario": sumario, "detalhe": detalhe}, http.StatusOK)
}
