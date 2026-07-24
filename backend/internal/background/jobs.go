// Package background implementa jobs recorrentes em background.
package background

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
	"nexora/internal/shared/contracts"
)

// StartJobs lança os jobs em background e retorna quando ctx é cancelado.
func StartJobs(ctx context.Context, db *pgxpool.Pool, notif contracts.NotificationPort, cfg *config.Config) {
	mailer := newMailer(cfg)
	sms := newSMSSender(cfg)

	// Despacho de notificações pendentes — a cada 30s
	go runInterval(ctx, "dispatch-notifications", 30*time.Second, func() {
		dispatchNotifications(db, mailer, sms)
	})

	// Reminders de cobranças escolares — diário
	go runDaily(ctx, "notif-cobrancas-vencidas", func() {
		notifCobrancasVencidas(db, notif)
	})

	// Limpeza de sessões expiradas — diário
	go runDaily(ctx, "clean-expired-sessions", func() {
		cleanExpiredSessions(db)
	})

	// Alertas de stock mínimo — diário
	go runDaily(ctx, "stock-alerts", func() {
		checkStockAlerts(db)
	})

	// Geração de propinas escolares mensais — diário
	go runDaily(ctx, "generate-monthly-fees", func() {
		generateMonthlyFees(db)
	})

	// Renovação de assinaturas vencidas — diário
	go runDaily(ctx, "process-subscription-renewals", func() {
		processSubscriptionRenewals(db)
	})

	// Marcação de faltas (ausência de evento num dia útil) — diário.
	// Mantido em paralelo com o job novo abaixo: opera sobre o modelo antigo
	// (rh.presencas), que o self-service e outros leitores ainda consultam
	// enquanto a Fase F (migração de dados) não os move para o novo modelo.
	go runDaily(ctx, "process-daily-absences", func() {
		processDailyAbsences(db)
	})

	// Recálculo diário de resultados de assiduidade (modelo de eventos) —
	// diário. Complementa o job acima: escreve em rh.resultados_diarios via
	// assiduidade.RecalcularDia, incluindo a detecção de falta por ausência
	// de eventos num dia com horário configurado.
	go runDaily(ctx, "recalcular-resultados-assiduidade", func() {
		recalcularResultadosAssiduidade(db)
	})
}

// ── helpers de agendamento ────────────────────────────────────────────────────

// runDaily executa fn após 30s de warm-up e depois a cada 24h.
func runDaily(ctx context.Context, name string, fn func()) {
	select {
	case <-time.After(30 * time.Second):
	case <-ctx.Done():
		return
	}
	log.Printf("[background] %s: primeira execução", name)
	fn()

	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			log.Printf("[background] %s: execução periódica", name)
			fn()
		case <-ctx.Done():
			return
		}
	}
}

// runInterval executa fn em intervalos regulares sem warm-up inicial.
func runInterval(ctx context.Context, name string, interval time.Duration, fn func()) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			fn()
		case <-ctx.Done():
			log.Printf("[background] %s: parado", name)
			return
		}
	}
}

// ── dispatch de notificações ─────────────────────────────────────────────────

// dispatchNotifications lê mensagens pendentes e envia por email ou SMS.
// Até 3 tentativas por mensagem; após isso marca como 'falhou'.
func dispatchNotifications(db *pgxpool.Pool, mailer *smtpMailer, sms smsSender) {
	if !mailer.enabled() && sms == nil {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	rows, err := db.Query(ctx, `
		SELECT id, canal_tipo, destinatario, assunto, corpo, tentativas
		  FROM notifications.notification_messages
		 WHERE status = 'pendente' AND tentativas < 3
		 ORDER BY created_at
		 LIMIT 50
		 FOR UPDATE SKIP LOCKED`)
	if err != nil {
		log.Printf("[background] dispatch-notifications: query: %v", err)
		return
	}
	defer rows.Close()

	type msg struct {
		id          int64
		canalTipo   string
		destinatario string
		assunto     string
		corpo       string
		tentativas  int
	}
	var msgs []msg
	for rows.Next() {
		var m msg
		if err := rows.Scan(&m.id, &m.canalTipo, &m.destinatario, &m.assunto, &m.corpo, &m.tentativas); err != nil {
			continue
		}
		msgs = append(msgs, m)
	}
	rows.Close()

	var sent, failed int
	for _, m := range msgs {
		var sendErr error
		switch m.canalTipo {
		case "email":
			sendErr = mailer.send(m.destinatario, m.assunto, m.corpo)
		case "sms":
			sendErr = sms.send(m.destinatario, m.corpo)
		default:
			// Canais não suportados (push, whatsapp) são marcados como falha.
			sendErr = fmt.Errorf("canal %s não suportado", m.canalTipo)
		}

		if sendErr != nil {
			failed++
			novasTentativas := m.tentativas + 1
			novoStatus := "pendente"
			if novasTentativas >= 3 {
				novoStatus = "falhou"
			}
			_, _ = db.Exec(ctx, `
				UPDATE notifications.notification_messages
				   SET tentativas=$1, status=$2, erro=$3
				 WHERE id=$4`,
				novasTentativas, novoStatus, sendErr.Error(), m.id)
		} else {
			sent++
			_, _ = db.Exec(ctx, `
				UPDATE notifications.notification_messages
				   SET status='enviado', enviado_em=NOW(), tentativas=$1, erro=NULL
				 WHERE id=$2`,
				m.tentativas+1, m.id)
		}
	}

	if sent > 0 || failed > 0 {
		log.Printf("[background] dispatch-notifications: %d enviadas, %d falharam", sent, failed)
	}
}

// ── cobranças escolares vencidas ──────────────────────────────────────────────

// notifCobrancasVencidas envia reminders de cobranças em atraso a alunos
// com portal_email, no máximo uma vez por dia por cobrança.
func notifCobrancasVencidas(db *pgxpool.Pool, notif contracts.NotificationPort) {
	if notif == nil {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	rows, err := db.Query(ctx, `
		SELECT f.id, f.tenant_id, f.descricao,
		       f.valor_total - COALESCE(f.desconto,0) - COALESCE(f.valor_pago,0) saldo,
		       f.moeda, f.data_vencimento,
		       COALESCE(NULLIF(s.portal_email,''), '') email_aluno,
		       s.id student_id,
		       COALESCE(g.portal_email, '') email_encarregado
		  FROM gestao_escolar.school_fees f
		  JOIN gestao_escolar.school_students s ON s.id = f.student_id
		  LEFT JOIN gestao_escolar.school_guardians g
		         ON g.student_id = s.id AND g.principal = true
		        AND COALESCE(g.portal_email, '') <> '' AND g.portal_ativo = true
		 WHERE f.status IN ('emitida','parcial')
		   AND f.data_vencimento < NOW()
		   AND (f.ultima_notif_vencimento IS NULL
		        OR f.ultima_notif_vencimento < NOW() - INTERVAL '23 hours')
		   AND (COALESCE(NULLIF(s.portal_email,''), '') <> ''
		        OR COALESCE(g.portal_email, '') <> '')`)
	if err != nil {
		log.Printf("[background] notifCobrancasVencidas: query: %v", err)
		return
	}
	defer rows.Close()

	var sent int
	for rows.Next() {
		var feeID, tenantID, studentID int64
		var descricao, moeda, emailAluno, emailEncarregado string
		var saldo float64
		var dataVenc time.Time
		if err := rows.Scan(&feeID, &tenantID, &descricao, &saldo, &moeda, &dataVenc, &emailAluno, &studentID, &emailEncarregado); err != nil {
			continue
		}

		corpo := fmt.Sprintf("A cobrança \"%s\" no valor de %.2f %s encontra-se em atraso (venceu em %s). Por favor regularize o pagamento no portal.", descricao, saldo, moeda, dataVenc.Format("02/01/2006"))
		sid := studentID

		if emailAluno != "" {
			notif.Send(ctx, contracts.Notification{
				TenantID: tenantID, CanalTipo: "email",
				Destinatario: emailAluno, Assunto: "Cobrança em atraso — acção necessária",
				Corpo: corpo, ReferenciaTipo: "escolar.cobranca.vencimento", ReferenciaID: &sid,
			})
			sent++
		}
		if emailEncarregado != "" && emailEncarregado != emailAluno {
			notif.Send(ctx, contracts.Notification{
				TenantID: tenantID, CanalTipo: "email",
				Destinatario: emailEncarregado, Assunto: "Cobrança do seu educando em atraso",
				Corpo: "Encarregado, " + corpo, ReferenciaTipo: "escolar.cobranca.vencimento", ReferenciaID: &sid,
			})
			sent++
		}

		_, _ = db.Exec(ctx, `UPDATE gestao_escolar.school_fees SET ultima_notif_vencimento=NOW() WHERE id=$1`, feeID)
	}

	if sent > 0 {
		log.Printf("[background] notifCobrancasVencidas: %d notificações criadas", sent)
	}
}

// ── limpeza de sessões expiradas ──────────────────────────────────────────────

func cleanExpiredSessions(db *pgxpool.Pool) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	tag, err := db.Exec(ctx, `DELETE FROM auth.sessions WHERE expira_em < NOW()`)
	if err != nil {
		log.Printf("[background] clean-expired-sessions: %v", err)
		return
	}
	if tag.RowsAffected() > 0 {
		log.Printf("[background] clean-expired-sessions: %d sessões eliminadas", tag.RowsAffected())
	}
}

// ── alertas de stock mínimo ───────────────────────────────────────────────────

// ── propinas escolares mensais ────────────────────────────────────────────────

// generateMonthlyFees emite propinas mensais para matrículas activas com base
// nos planos de propinas (school_fee_plans) onde periodicidade='mensal'.
// Só cria uma propina por matrícula/plano se ainda não existir para o mês corrente.
func generateMonthlyFees(db *pgxpool.Pool) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	now := time.Now()
	mesRef := now.Format("2006-01") // ex: "2026-07"
	// Vencimento: dia configurado no plano, ou último dia do mês
	anoMes := fmt.Sprintf("%d-%02d", now.Year(), now.Month())

	rows, err := db.Query(ctx, `
		SELECT fp.id, fp.tenant_id, fp.nome, fp.valor, fp.moeda, fp.dia_vencimento,
		       e.id enrollment_id, e.student_id
		  FROM gestao_escolar.school_fee_plans fp
		  JOIN gestao_escolar.school_enrollments e
		         ON e.tenant_id = fp.tenant_id
		        AND e.status = 'activa'
		 WHERE fp.periodicidade = 'mensal'
		   AND fp.activo = TRUE
		   AND NOT EXISTS (
		       SELECT 1 FROM gestao_escolar.school_fees sf
		        WHERE sf.enrollment_id = e.id
		          AND sf.fee_plan_id   = fp.id
		          AND sf.mes_referencia = $1
		   )`, mesRef)
	if err != nil {
		log.Printf("[background] generate-monthly-fees: query: %v", err)
		return
	}
	defer rows.Close()

	var created int
	for rows.Next() {
		var planID, tenantID, enrollmentID, studentID int64
		var nome, moeda string
		var valor float64
		var diaVenc *int
		if err := rows.Scan(&planID, &tenantID, &nome, &valor, &moeda, &diaVenc, &enrollmentID, &studentID); err != nil {
			continue
		}
		dia := 28
		if diaVenc != nil && *diaVenc >= 1 && *diaVenc <= 28 {
			dia = *diaVenc
		}
		dataVenc := fmt.Sprintf("%s-%02d", anoMes, dia)
		descricao := fmt.Sprintf("%s — %s", nome, mesRef)
		numero := fmt.Sprintf("PROP-%d-%s-%d", tenantID, mesRef, enrollmentID)

		_, err := db.Exec(ctx, `
			INSERT INTO gestao_escolar.school_fees
				(tenant_id, enrollment_id, student_id, fee_plan_id, numero, descricao,
				 mes_referencia, data_vencimento, valor_total, moeda, status, emitida_em)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'emitida',NOW())`,
			tenantID, enrollmentID, studentID, planID, numero, descricao,
			mesRef, dataVenc, valor, moeda)
		if err != nil {
			log.Printf("[background] generate-monthly-fees: insert: %v", err)
			continue
		}
		created++
	}

	if created > 0 {
		log.Printf("[background] generate-monthly-fees: %d propinas emitidas (%s)", created, mesRef)
	}
}

// ── renovação de assinaturas ──────────────────────────────────────────────────

// processSubscriptionRenewals gera facturas de renovação para assinaturas
// com next_billing_date <= hoje, auto_renew=true e status='activo'.
func processSubscriptionRenewals(db *pgxpool.Pool) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	rows, err := db.Query(ctx, `
		SELECT s.id, s.tenant_id, s.plan_id, s.unit_price, s.moeda,
		       s.next_billing_date, p.billing_period
		  FROM assinaturas.subscriptions s
		  JOIN assinaturas.subscription_plans p ON p.id = s.plan_id
		 WHERE s.status = 'activo'
		   AND s.auto_renew = TRUE
		   AND s.next_billing_date <= CURRENT_DATE
		   AND NOT EXISTS (
		       SELECT 1 FROM assinaturas.subscription_invoices si
		        WHERE si.subscription_id = s.id
		          AND si.billing_period_start = s.next_billing_date
		   )`)
	if err != nil {
		log.Printf("[background] process-subscription-renewals: query: %v", err)
		return
	}
	defer rows.Close()

	var processed int
	for rows.Next() {
		var subID, tenantID, planID int64
		var unitPrice float64
		var moeda, billingPeriod string
		var nextBilling time.Time
		if err := rows.Scan(&subID, &tenantID, &planID, &unitPrice, &moeda, &nextBilling, &billingPeriod); err != nil {
			continue
		}

		// Calcular próximo período de faturação
		var periodEnd, nextDate time.Time
		switch billingPeriod {
		case "anual":
			periodEnd = nextBilling.AddDate(1, 0, -1)
			nextDate = nextBilling.AddDate(1, 0, 0)
		default: // mensal
			periodEnd = nextBilling.AddDate(0, 1, -1)
			nextDate = nextBilling.AddDate(0, 1, 0)
		}
		dueDate := nextBilling.AddDate(0, 0, 7) // 7 dias para pagar
		numero := fmt.Sprintf("INV-%d-%s", subID, nextBilling.Format("200601"))

		tx, err := db.Begin(ctx)
		if err != nil {
			continue
		}

		_, err = tx.Exec(ctx, `
			INSERT INTO assinaturas.subscription_invoices
				(tenant_id, subscription_id, numero, billing_period_start, billing_period_end,
				 due_date, valor_total, valor_pago, moeda, status)
			VALUES ($1,$2,$3,$4,$5,$6,$7,0,$8,'pendente')`,
			tenantID, subID, numero, nextBilling, periodEnd, dueDate, unitPrice, moeda)
		if err != nil {
			tx.Rollback(ctx)
			log.Printf("[background] process-subscription-renewals: insert invoice: %v", err)
			continue
		}

		_, err = tx.Exec(ctx, `
			UPDATE assinaturas.subscriptions
			   SET next_billing_date = $1, updated_at = NOW()
			 WHERE id = $2`, nextDate, subID)
		if err != nil {
			tx.Rollback(ctx)
			continue
		}

		if err := tx.Commit(ctx); err == nil {
			processed++
		}
	}

	if processed > 0 {
		log.Printf("[background] process-subscription-renewals: %d assinaturas renovadas", processed)
	}
}

// ── faltas por ausência de evento (tipo='falta') ─────────────────────────────

// processDailyAbsences marca tipo='falta' em rh.presencas para funcionários
// com horário de trabalho configurado que, no dia útil anterior (segundo
// horarios_trabalho.dias_semana), não tiveram qualquer entrada registada e
// não têm uma ausência aprovada (férias/doença/etc.) a cobrir esse dia.
//
// Corre sempre referente ao dia ANTERIOR: no dia corrente ainda pode surgir
// um evento de entrada mais tarde, por isso só faz sentido decidir 'falta'
// depois do dia útil ter terminado por completo.
//
// Complementa calcularTipoPresenca em hardware/service/processor.go, que só
// decide 'presente'/'atraso' a partir de um evento já recebido — 'falta' só
// é detectável pela AUSÊNCIA de qualquer evento, o que exigia esta rotina
// diária (documentado como pendente em CONTRATO-INTEGRACAO-ERP.md e no
// comentário da Fase 4 em processor.go).
//
// dias_semana usa convenção ISO (1=segunda ... 7=domingo), consistente com o
// valor por omissão '1,2,3,4,5' (segunda a sexta) usado em toda a BD.
func processDailyAbsences(db *pgxpool.Pool) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	data := time.Now().AddDate(0, 0, -1).Format("2006-01-02")
	marcadas, err := processAbsencesForDate(ctx, db, data)
	if err != nil {
		log.Printf("[background] process-daily-absences: %v", err)
		return
	}
	if marcadas > 0 {
		log.Printf("[background] process-daily-absences: %d faltas marcadas (%s)", marcadas, data)
	}
}

// processAbsencesForDate aplica a lógica de processDailyAbsences a uma data
// específica (formato "2006-01-02"), devolvendo quantas faltas foram
// marcadas. Extraído para ser exercitável em testes sem depender de
// time.Now() — a lógica de produção (processDailyAbsences) chama isto
// sempre com "ontem".
func processAbsencesForDate(ctx context.Context, db *pgxpool.Pool, data string) (int, error) {
	dataRef, err := time.Parse("2006-01-02", data)
	if err != nil {
		return 0, fmt.Errorf("data inválida: %w", err)
	}
	isoWeekday := int(dataRef.Weekday())
	if isoWeekday == 0 {
		isoWeekday = 7
	}
	diaSemana := fmt.Sprintf("%d", isoWeekday)

	rows, err := db.Query(ctx, `
		SELECT f.id, f.tenant_id
		  FROM rh.funcionarios f
		  JOIN rh.horarios_trabalho h ON h.id = f.horario_id
		 WHERE f.estado = 'ativo'
		   AND h.ativo = TRUE
		   AND f.data_admissao <= $1::date
		   AND (f.data_saida IS NULL OR f.data_saida >= $1::date)
		   AND $2 = ANY (SELECT trim(dia) FROM unnest(string_to_array(h.dias_semana, ',')) AS dia)
		   AND NOT EXISTS (
		       SELECT 1 FROM rh.presencas p
		        WHERE p.funcionario_id = f.id AND p.data = $1::date
		          AND p.hora_entrada IS NOT NULL AND p.hora_entrada <> ''
		   )
		   AND NOT EXISTS (
		       SELECT 1 FROM rh.ausencias a
		        WHERE a.funcionario_id = f.id
		          AND a.estado = 'aprovado'
		          AND $1::date BETWEEN a.data_inicio AND a.data_fim
		   )`,
		data, diaSemana)
	if err != nil {
		return 0, fmt.Errorf("query: %w", err)
	}
	defer rows.Close()

	type funcTenant struct {
		funcionarioID int64
		tenantID      int64
	}
	var alvos []funcTenant
	for rows.Next() {
		var ft funcTenant
		if err := rows.Scan(&ft.funcionarioID, &ft.tenantID); err != nil {
			continue
		}
		alvos = append(alvos, ft)
	}
	rows.Close()

	var marcadas int
	for _, ft := range alvos {
		_, err := db.Exec(ctx, `
			INSERT INTO rh.presencas (tenant_id, funcionario_id, data, tipo, observacoes)
			VALUES ($1, $2, $3::date, 'falta', 'Falta detectada automaticamente (sem registo de entrada)')
			ON CONFLICT (funcionario_id, data)
			DO UPDATE SET tipo = 'falta',
			              observacoes = 'Falta detectada automaticamente (sem registo de entrada)'`,
			ft.tenantID, ft.funcionarioID, data)
		if err != nil {
			log.Printf("[background] process-daily-absences: insert funcionario_id=%d: %v", ft.funcionarioID, err)
			continue
		}
		marcadas++
	}

	return marcadas, nil
}

// ── recálculo diário de resultados de assiduidade (modelo de eventos) ───────

// recalcularResultadosAssiduidade chama assiduidade.RecalcularDia para todos
// os funcionários com horário vigente ou eventos registados no dia ANTERIOR
// (mesma razão do process-daily-absences: o dia corrente ainda pode receber
// eventos mais tarde). RecalcularDia já trata a detecção de falta por
// ausência de eventos num dia com horário configurado (ver calculo.go).
func recalcularResultadosAssiduidade(db *pgxpool.Pool) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	data := time.Now().AddDate(0, 0, -1).Format("2006-01-02")
	recalculados, err := recalcularResultadosParaData(ctx, db, data)
	if err != nil {
		log.Printf("[background] recalcular-resultados-assiduidade: %v", err)
		return
	}
	if recalculados > 0 {
		log.Printf("[background] recalcular-resultados-assiduidade: %d funcionários recalculados (%s)", recalculados, data)
	}
}

// recalcularResultadosParaData aplica a lógica de
// recalcularResultadosAssiduidade a uma data específica (formato
// "2006-01-02"), devolvendo quantos funcionários foram recalculados.
// Extraído para ser exercitável em testes sem depender de time.Now(), mesmo
// padrão de processAbsencesForDate.
func recalcularResultadosParaData(ctx context.Context, db *pgxpool.Pool, data string) (int, error) {
	dataRef, err := time.Parse("2006-01-02", data)
	if err != nil {
		return 0, fmt.Errorf("data inválida: %w", err)
	}

	rows, err := db.Query(ctx, `
		SELECT DISTINCT f.id, f.tenant_id
		  FROM rh.funcionarios f
		 WHERE f.estado = 'ativo'
		   AND f.data_admissao <= $1::date
		   AND (f.data_saida IS NULL OR f.data_saida >= $1::date)
		   AND (
		       EXISTS (
		           SELECT 1 FROM rh.funcionario_horarios fh
			         JOIN rh.horarios_trabalho h ON h.id = fh.horario_id
			        WHERE fh.funcionario_id = f.id
			          AND fh.data_inicio <= $1::date
			          AND (fh.data_fim IS NULL OR fh.data_fim >= $1::date)
			          AND h.ativo = TRUE
		       )
		       OR EXISTS (
		           SELECT 1 FROM rh.eventos_assiduidade e
			        WHERE e.funcionario_id = f.id AND e.data_referencia = $1::date
		       )
		   )`,
		data)
	if err != nil {
		return 0, fmt.Errorf("query: %w", err)
	}

	type funcTenant struct {
		funcionarioID int64
		tenantID      int64
	}
	var alvos []funcTenant
	for rows.Next() {
		var ft funcTenant
		if err := rows.Scan(&ft.funcionarioID, &ft.tenantID); err != nil {
			continue
		}
		alvos = append(alvos, ft)
	}
	rows.Close()

	svc := assiduidade.NewService(db)
	var recalculados int
	for _, ft := range alvos {
		if _, err := svc.RecalcularDia(ctx, ft.tenantID, ft.funcionarioID, dataRef); err != nil {
			log.Printf("[background] recalcular-resultados-assiduidade: funcionario_id=%d: %v", ft.funcionarioID, err)
			continue
		}
		recalculados++
	}

	return recalculados, nil
}

// ── alertas de stock mínimo ───────────────────────────────────────────────────

// checkStockAlerts cria alertas para itens abaixo do stock mínimo
// e resolve alertas de itens que voltaram ao nível normal.
func checkStockAlerts(db *pgxpool.Pool) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	// Resolver alertas de itens que voltaram ao nível normal
	_, err := db.Exec(ctx, `
		UPDATE stock.stock_alerts sa
		   SET status = 'resolvido', updated_at = NOW()
		  FROM stock.stock_items si
		 WHERE sa.stock_item_id = si.id
		   AND sa.status = 'ativo'
		   AND sa.alert_type = 'stock_minimo'
		   AND si.available_quantity > si.minimum_quantity`)
	if err != nil {
		log.Printf("[background] stock-alerts: resolver alertas: %v", err)
	}

	// Criar alertas para itens abaixo do mínimo (sem alerta activo)
	rows, err := db.Query(ctx, `
		SELECT si.id, si.tenant_id, p.nome, si.available_quantity, si.minimum_quantity
		  FROM stock.stock_items si
		  JOIN produtos.products p ON p.id = si.product_id
		 WHERE si.minimum_quantity > 0
		   AND si.available_quantity <= si.minimum_quantity
		   AND NOT EXISTS (
		       SELECT 1 FROM stock.stock_alerts sa
		        WHERE sa.stock_item_id = si.id
		          AND sa.status = 'ativo'
		          AND sa.alert_type = 'stock_minimo'
		   )`)
	if err != nil {
		log.Printf("[background] stock-alerts: query itens: %v", err)
		return
	}
	defer rows.Close()

	var created int
	for rows.Next() {
		var itemID, tenantID int64
		var nome string
		var disponivel, minimo float64
		if err := rows.Scan(&itemID, &tenantID, &nome, &disponivel, &minimo); err != nil {
			continue
		}
		mensagem := fmt.Sprintf("Stock de \"%s\" abaixo do mínimo: %.0f unidades (mínimo: %.0f)", nome, disponivel, minimo)
		_, _ = db.Exec(ctx, `
			INSERT INTO stock.stock_alerts (tenant_id, stock_item_id, alert_type, status, mensagem)
			VALUES ($1, $2, 'stock_minimo', 'ativo', $3)`,
			tenantID, itemID, mensagem)
		created++
	}

	if created > 0 {
		log.Printf("[background] stock-alerts: %d novos alertas criados", created)
	}
}
