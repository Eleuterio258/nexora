// Package background implementa jobs recorrentes em background.
package background

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/pkg/nexorapay"
	"nexora/internal/push"
	"nexora/internal/shared/contracts"
	"nexora/internal/storage"
)

// notificationDB é a interface mínima usada pelo dispatcher de notificações
// — tanto *pgxpool.Pool (produção) como pgxmock (testes) a implementam, sem
// precisar de uma BD real para testar claim/lease/finalize.
type notificationDB interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

// pushSender é a interface mínima do serviço de push usada pelo dispatcher
// — satisfeita por *push.Service; permite testar o case "push" com um stub,
// sem precisar de credenciais FCM reais (Fase 3 de
// docs/analise-transactional-outbox-backends.md).
type pushSender interface {
	Enabled() bool
	SendOne(ctx context.Context, token, title, body string, data map[string]string) error
}

// StartJobs lança os jobs em background e retorna quando ctx é cancelado.
func StartJobs(ctx context.Context, db *pgxpool.Pool, notif contracts.NotificationPort, pushSvc *push.Service, paySvc *nexorapay.PaymentService, cfg *config.Config, store storage.Provider) {
	mailer := newMailer(cfg)
	sms := newSMSSender(cfg)
	workerID := notificationWorkerID()

	// Despacho de notificações pendentes — a cada 30s
	go runInterval(ctx, "dispatch-notifications", 30*time.Second, func() {
		dispatchNotifications(db, mailer, sms, pushSvc, store, workerID)
	})

	// Reconciliação de pagamentos ambíguos (payment_intents em
	// pending/processing/unknown vencidos) — a cada 2min. Fase 4 de
	// docs/analise-transactional-outbox-backends.md, item 5.
	go runInterval(ctx, "reconciliar-pagamentos", 2*time.Minute, func() {
		if paySvc == nil {
			return
		}
		reconcilePaymentIntents(paySvc, workerID)
	})

	// Reminders de cobranças escolares — diário
	go runDaily(ctx, "notif-cobrancas-vencidas", func() {
		notifCobrancasVencidas(db, notif)
	})

	// Limpeza de sessões expiradas — diário
	go runDaily(ctx, "clean-expired-sessions", func() {
		cleanExpiredSessions(db)
	})

	// Geração de propinas escolares mensais — diário
	go runDaily(ctx, "generate-monthly-fees", func() {
		generateMonthlyFees(db)
	})

}

// ── reconciliação de pagamentos ──────────────────────────────────────────────

const paymentLeaseTimeout = 5 * time.Minute

// paymentReconciler é a interface mínima usada pelo job de reconciliação —
// satisfeita por *nexorapay.PaymentService; permite testar com um stub, sem
// precisar de credenciais Nexora Pay reais.
type paymentReconciler interface {
	RecoverExpiredLeases(ctx context.Context, leaseTimeout time.Duration) (int64, error)
	ClaimForReconciliation(ctx context.Context, workerID string, limit int) ([]nexorapay.PaymentIntent, error)
	Reconcile(ctx context.Context, intent nexorapay.PaymentIntent) error
}

// reconcilePaymentIntents resolve payment_intents ambíguos (pending/
// processing/unknown vencidos): recupera leases expiradas, reserva um lote
// atomicamente (mesmo padrão de claimPendingNotifications) e reconcilia cada
// um — consulta o estado no gateway quando já se conhece o
// gateway_transaction_id, ou reenvia o POST original com a mesma
// idempotency_key quando não se conhece. Fase 4, item 5, de
// docs/analise-transactional-outbox-backends.md.
func reconcilePaymentIntents(svc paymentReconciler, workerID string) {
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	if _, err := svc.RecoverExpiredLeases(ctx, paymentLeaseTimeout); err != nil {
		log.Printf("[background] reconciliar-pagamentos: recuperar leases expiradas: %v", err)
	}

	intents, err := svc.ClaimForReconciliation(ctx, workerID, 50)
	if err != nil {
		log.Printf("[background] reconciliar-pagamentos: reservar intents: %v", err)
		return
	}
	for _, intent := range intents {
		if err := svc.Reconcile(ctx, intent); err != nil {
			log.Printf("[background] reconciliar-pagamentos: reconciliar intent %s: %v", intent.ID, err)
		}
	}
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
//
// Fase 2 de docs/analise-transactional-outbox-backends.md: reserva atómica
// (item 4), lease com recuperação (item 3), backoff exponencial (item 5) e
// todos os UPDATE de estado com erro verificado e logado (item 6).

// notificationMaxAttempts é o tecto de tentativas antes de uma mensagem
// passar a 'falha' (dead-letter). notificationLeaseTimeout é quanto tempo
// uma mensagem pode ficar 'processando' antes de se considerar que o worker
// que a reservou morreu a meio do envio e a reserva ser recuperada.
const (
	notificationMaxAttempts  = 6
	notificationLeaseTimeout = 5 * time.Minute
)

// notificationBackoff é o atraso antes da próxima tentativa, indexado por
// número de tentativas já feitas (1ª posição = depois da 1ª falha). Mais
// curta que o outbox FaceClock→ERP (Fase 1): email/SMS são canais menos
// críticos e o próprio documento não fixa números para este item.
var notificationBackoff = []time.Duration{
	1 * time.Minute,
	5 * time.Minute,
	20 * time.Minute,
	1 * time.Hour,
	4 * time.Hour,
	12 * time.Hour,
}

// notificationBackoffFor devolve o atraso para a tentativa `attempts`
// (1-based); fica fixo no último valor da tabela além do seu tamanho.
func notificationBackoffFor(attempts int) time.Duration {
	idx := min(max(attempts-1, 0), len(notificationBackoff)-1)
	return notificationBackoff[idx]
}

// notificationWorkerID identifica este processo nas colunas locked_by —
// necessário porque, a partir da Fase 2 item 7, o dispatcher pode correr
// tanto dentro da API como num binário separado (cmd/worker), por vezes os
// dois ao mesmo tempo por má configuração; o claim atómico abaixo é o que
// torna isso seguro. Mesmo padrão do worker Python da Fase 1 (hostname+pid).
func notificationWorkerID() string {
	host, _ := os.Hostname()
	return fmt.Sprintf("%s-%d", host, os.Getpid())
}

type notificationClaim struct {
	id              int64
	canalTipo       string
	destinatario    string
	assunto         string
	corpo           string
	tentativas      int
	anexoStorageKey string
	anexoNome       string
	payload         []byte
}

// recoverExpiredNotificationLeases devolve a 'pendente' mensagens presas em
// 'processando' cujo lease expirou (worker morto a meio do envio).
func recoverExpiredNotificationLeases(ctx context.Context, db notificationDB, leaseTimeout time.Duration) {
	tag, err := db.Exec(ctx, `
		UPDATE notifications.notification_messages
		   SET status='pendente', locked_at=NULL, locked_by=NULL
		 WHERE status='processando' AND locked_at < NOW() - ($1 * INTERVAL '1 second')`,
		leaseTimeout.Seconds())
	if err != nil {
		log.Printf("[background] dispatch-notifications: recuperar leases expiradas: %v", err)
		return
	}
	if n := tag.RowsAffected(); n > 0 {
		log.Printf("[background] dispatch-notifications: %d lease(s) expirada(s) recuperada(s)", n)
	}
}

// claimPendingNotifications reserva até `limit` mensagens pendentes e
// vencidas para workerID, numa única instrução SQL — o SELECT ... FOR UPDATE
// SKIP LOCKED e o UPDATE que marca 'processando' fazem parte da mesma
// operação atómica (ver docs/analise-transactional-outbox-backends.md,
// secção 29.3), sem a janela que antes permitia duas réplicas do dispatcher
// seleccionarem e enviarem a mesma mensagem.
func claimPendingNotifications(ctx context.Context, db notificationDB, workerID string, limit int) ([]notificationClaim, error) {
	rows, err := db.Query(ctx, `
		WITH candidatos AS (
			SELECT id
			  FROM notifications.notification_messages
			 WHERE status = 'pendente' AND available_at <= NOW()
			 ORDER BY available_at, created_at, id
			 LIMIT $1
			 FOR UPDATE SKIP LOCKED
		)
		UPDATE notifications.notification_messages m
		   SET status = 'processando', locked_at = NOW(), locked_by = $2
		  FROM candidatos c
		 WHERE m.id = c.id
		RETURNING m.id, m.canal_tipo, m.destinatario, m.assunto, m.corpo, m.tentativas,
		          COALESCE(m.anexo_storage_key,''), COALESCE(m.anexo_nome,''), m.payload`,
		limit, workerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var claims []notificationClaim
	for rows.Next() {
		var c notificationClaim
		if err := rows.Scan(&c.id, &c.canalTipo, &c.destinatario, &c.assunto, &c.corpo, &c.tentativas,
			&c.anexoStorageKey, &c.anexoNome, &c.payload); err != nil {
			continue
		}
		claims = append(claims, c)
	}
	return claims, rows.Err()
}

// finalizeNotification grava o resultado do envio de uma mensagem já
// reservada: sucesso fecha em 'enviado'; falha com tentativas esgotadas vai
// para 'falha' (dead-letter); falha com tentativas ainda disponíveis volta a
// 'pendente' com available_at adiado pelo backoff exponencial. Todo o Exec é
// verificado e logado — nunca mais `_, _ = db.Exec(...)`.
func finalizeNotification(ctx context.Context, db notificationDB, m notificationClaim, sendErr error) {
	if sendErr == nil {
		if _, err := db.Exec(ctx, `
			UPDATE notifications.notification_messages
			   SET status='enviado', enviado_em=NOW(), tentativas=$1, erro=NULL,
			       locked_at=NULL, locked_by=NULL
			 WHERE id=$2`,
			m.tentativas+1, m.id); err != nil {
			log.Printf("[background] dispatch-notifications: marcar enviada id=%d: %v", m.id, err)
		}
		return
	}

	novasTentativas := m.tentativas + 1
	if novasTentativas >= notificationMaxAttempts {
		if _, err := db.Exec(ctx, `
			UPDATE notifications.notification_messages
			   SET status='falha', tentativas=$1, erro=$2, locked_at=NULL, locked_by=NULL
			 WHERE id=$3`,
			novasTentativas, sendErr.Error(), m.id); err != nil {
			log.Printf("[background] dispatch-notifications: marcar falha id=%d: %v", m.id, err)
		}
		return
	}

	if _, err := db.Exec(ctx, `
		UPDATE notifications.notification_messages
		   SET status='pendente', tentativas=$1, erro=$2,
		       available_at=NOW() + ($3 * INTERVAL '1 second'),
		       locked_at=NULL, locked_by=NULL
		 WHERE id=$4`,
		novasTentativas, sendErr.Error(), notificationBackoffFor(novasTentativas).Seconds(), m.id); err != nil {
		log.Printf("[background] dispatch-notifications: agendar retry id=%d: %v", m.id, err)
	}
}

// dispatchNotifications lê mensagens pendentes e envia por email, SMS ou
// push (Fase 3 de docs/analise-transactional-outbox-backends.md).
func dispatchNotifications(db notificationDB, mailer *sesMailer, sms smsSender, pushSvc pushSender, store storage.Provider, workerID string) {
	pushEnabled := pushSvc != nil && pushSvc.Enabled()
	if !mailer.enabled() && sms == nil && !pushEnabled {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	recoverExpiredNotificationLeases(ctx, db, notificationLeaseTimeout)

	claims, err := claimPendingNotifications(ctx, db, workerID, 50)
	if err != nil {
		log.Printf("[background] dispatch-notifications: reservar mensagens: %v", err)
		return
	}

	var sent, failed int
	for _, m := range claims {
		var sendErr error
		switch m.canalTipo {
		case "email":
			if m.anexoStorageKey != "" && store != nil {
				sendErr = sendEmailComAnexo(ctx, mailer, store, m.destinatario, m.assunto, m.corpo, m.anexoNome, m.anexoStorageKey)
			} else {
				sendErr = mailer.send(m.destinatario, m.assunto, m.corpo)
			}
		case "sms":
			sendErr = sms.send(m.destinatario, m.corpo)
		case "push":
			var data map[string]string
			if len(m.payload) > 0 {
				if err := json.Unmarshal(m.payload, &data); err != nil {
					log.Printf("[background] dispatch-notifications: payload invalido id=%d: %v", m.id, err)
				}
			}
			sendErr = pushSvc.SendOne(ctx, m.destinatario, m.assunto, m.corpo, data)
		default:
			// Canais não suportados (whatsapp) são marcados como falha.
			sendErr = fmt.Errorf("canal %s não suportado", m.canalTipo)
		}

		if sendErr != nil {
			failed++
		} else {
			sent++
		}
		finalizeNotification(ctx, db, m, sendErr)
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
			if err := notif.Send(ctx, contracts.Notification{
				TenantID: tenantID, CanalTipo: "email",
				Destinatario: emailAluno, Assunto: "Cobrança em atraso — acção necessária",
				Corpo: corpo, ReferenciaTipo: "escolar.cobranca.vencimento", ReferenciaID: &sid,
			}); err != nil {
				log.Printf("[background] notifCobrancasVencidas: enfileirar para aluno: %v", err)
			}
			sent++
		}
		if emailEncarregado != "" && emailEncarregado != emailAluno {
			if err := notif.Send(ctx, contracts.Notification{
				TenantID: tenantID, CanalTipo: "email",
				Destinatario: emailEncarregado, Assunto: "Cobrança do seu educando em atraso",
				Corpo: "Encarregado, " + corpo, ReferenciaTipo: "escolar.cobranca.vencimento", ReferenciaID: &sid,
			}); err != nil {
				log.Printf("[background] notifCobrancasVencidas: enfileirar para encarregado: %v", err)
			}
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
//
// O plano aplicável é escolhido pelo ano lectivo da matrícula. Como não existe
// ligação matrícula→plano no schema (o classe_nivel do plano é texto livre que
// não casa com school_classes.nivel), este job só factura quando a escolha é
// inequívoca: exactamente um plano mensal activo no ano lectivo. Onde houver
// mais do que um, salta e regista aviso — cabe ao operador gerar por
// FeeService.GenerateFromPlan, escolhendo explicitamente o plano.
//
// Até 2026-09 o join era só por tenant_id, um produto cartesiano de todos os
// planos por todas as matrículas. O `numero` não incluía o plano, por isso a
// constraint uq_school_fees(tenant_id, numero) rejeitava todas as linhas menos
// a primeira e o job facturava toda a gente ao plano que calhasse na ordem do
// join, despejando um erro de chave duplicada por cada linha rejeitada.
func generateMonthlyFees(db *pgxpool.Pool) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	now := time.Now()
	mesRef := now.Format("2006-01") // ex: "2026-07"
	// Vencimento: dia configurado no plano, ou último dia do mês
	anoMes := fmt.Sprintf("%d-%02d", now.Year(), now.Month())

	logAmbiguousFeePlans(ctx, db)

	rows, err := db.Query(ctx, `
		WITH planos_mensais AS (
		    SELECT fp.id, fp.tenant_id, fp.school_year_id, fp.nome, fp.valor,
		           fp.moeda, fp.dia_vencimento,
		           COUNT(*) OVER (PARTITION BY fp.tenant_id, fp.school_year_id) planos_no_ano
		      FROM gestao_escolar.school_fee_plans fp
		     WHERE fp.periodicidade = 'mensal'
		       AND fp.activo = TRUE
		       AND fp.school_year_id IS NOT NULL
		)
		SELECT p.id, p.tenant_id, p.nome, p.valor, p.moeda, p.dia_vencimento,
		       e.id enrollment_id, e.student_id
		  FROM planos_mensais p
		  JOIN gestao_escolar.school_enrollments e
		         ON e.tenant_id      = p.tenant_id
		        AND e.school_year_id = p.school_year_id
		        AND e.status = 'activa'
		 WHERE p.planos_no_ano = 1
		   AND NOT EXISTS (
		       SELECT 1 FROM gestao_escolar.school_fees sf
		        WHERE sf.enrollment_id = e.id
		          AND sf.fee_plan_id   = p.id
		          AND sf.mes_referencia = $1
		   )`, mesRef)
	if err != nil {
		log.Printf("[background] generate-monthly-fees: query: %v", err)
		return
	}
	defer rows.Close()

	type propina struct {
		planID, tenantID, enrollmentID, studentID int64
		nome, moeda                               string
		valor                                     float64
		diaVenc                                   *int
	}
	var pendentes []propina
	for rows.Next() {
		var p propina
		if err := rows.Scan(&p.planID, &p.tenantID, &p.nome, &p.valor, &p.moeda, &p.diaVenc, &p.enrollmentID, &p.studentID); err != nil {
			continue
		}
		pendentes = append(pendentes, p)
	}
	if err := rows.Err(); err != nil {
		log.Printf("[background] generate-monthly-fees: iterar: %v", err)
		return
	}

	var created int
	for _, p := range pendentes {
		dia := 28
		if p.diaVenc != nil && *p.diaVenc >= 1 && *p.diaVenc <= 28 {
			dia = *p.diaVenc
		}
		dataVenc := fmt.Sprintf("%s-%02d", anoMes, dia)
		descricao := fmt.Sprintf("%s — %s", p.nome, mesRef)
		// O plano entra no número: sem ele duas propinas do mesmo mês para a
		// mesma matrícula colidem em uq_school_fees(tenant_id, numero).
		numero := fmt.Sprintf("PROP-%d-%s-%d-%d", p.tenantID, mesRef, p.planID, p.enrollmentID)

		tag, err := db.Exec(ctx, `
			INSERT INTO gestao_escolar.school_fees
				(tenant_id, enrollment_id, student_id, fee_plan_id, numero, descricao,
				 mes_referencia, data_vencimento, valor_total, moeda, status, emitida_em)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'emitida',NOW())
			ON CONFLICT (tenant_id, numero) DO NOTHING`,
			p.tenantID, p.enrollmentID, p.studentID, p.planID, numero, descricao,
			mesRef, dataVenc, p.valor, p.moeda)
		if err != nil {
			log.Printf("[background] generate-monthly-fees: insert: %v", err)
			continue
		}
		created += int(tag.RowsAffected())
	}

	if created > 0 {
		log.Printf("[background] generate-monthly-fees: %d propinas emitidas (%s)", created, mesRef)
	}
}

// logAmbiguousFeePlans avisa sobre anos lectivos com mais do que um plano
// mensal activo. generateMonthlyFees salta-os por não conseguir decidir qual
// aplicar a cada matrícula.
func logAmbiguousFeePlans(ctx context.Context, db *pgxpool.Pool) {
	rows, err := db.Query(ctx, `
		SELECT tenant_id, school_year_id, COUNT(*)
		  FROM gestao_escolar.school_fee_plans
		 WHERE periodicidade = 'mensal'
		   AND activo = TRUE
		   AND school_year_id IS NOT NULL
		 GROUP BY tenant_id, school_year_id
		HAVING COUNT(*) > 1`)
	if err != nil {
		return
	}
	defer rows.Close()

	for rows.Next() {
		var tenantID, schoolYearID int64
		var planos int
		if err := rows.Scan(&tenantID, &schoolYearID, &planos); err != nil {
			continue
		}
		log.Printf("[background] generate-monthly-fees: tenant %d, ano lectivo %d tem %d planos mensais activos — nenhuma propina gerada automaticamente; use a geração por plano", tenantID, schoolYearID, planos)
	}
}

// ── renovação de assinaturas ──────────────────────────────────────────────────

// ── faltas por ausência de evento (tipo='falta') ─────────────────────────────

// ── recálculo diário de resultados de assiduidade (modelo de eventos) ───────

// ── alertas de stock mínimo ───────────────────────────────────────────────────
