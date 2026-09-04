package assiduidade

import "context"

// AuditoriaEntry é um registo de auditoria para rh.auditoria_assiduidade —
// histórico completo de quem alterou o quê, nunca apagado (requisito
// secção 12). Mais granular que auditoria.audit_logs (que é genérico e
// populado por middleware): aqui regista-se explicitamente valor
// anterior/novo por campo, a partir do próprio service layer.
type AuditoriaEntry struct {
	TenantID       int64
	Tabela         string
	RegistoID      int64
	Operacao       string // 'INSERT', 'UPDATE', 'DELETE'
	Campo          *string
	ValorAnterior  []byte // JSON já serializado — pgx não faz marshal automático de structs Go para jsonb
	ValorNovo      []byte
	AlteradoPor    *int64
	Motivo         *string
	IPOrigem       *string
	Dispositivo    *string
	Localizacao    *string
	EstadoAnterior *string
	EstadoNovo     *string
}

// RegistarAuditoria grava uma entrada em rh.auditoria_assiduidade. Por
// omissão, uma falha de auditoria não deve impedir a operação de negócio que
// a originou — a maioria dos chamadores trata o erro apenas para log, não
// para abortar. A excepção é um chamador para o qual a auditoria é
// obrigatória (ex.: Service.registarEvento, que corre dentro da mesma
// transação do evento e propaga este erro de propósito, revertendo também o
// evento — Fase 0, item 4 de docs/analise-transactional-outbox-backends.md).
func RegistarAuditoria(ctx context.Context, db DBTX, e AuditoriaEntry) error {
	_, err := db.Exec(ctx, `
		INSERT INTO rh.auditoria_assiduidade (
			tenant_id, tabela, registo_id, operacao, campo,
			valor_anterior, valor_novo, alterado_por, motivo,
			ip_origem, dispositivo, localizacao, estado_anterior, estado_novo
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)`,
		e.TenantID, e.Tabela, e.RegistoID, e.Operacao, e.Campo,
		e.ValorAnterior, e.ValorNovo, e.AlteradoPor, e.Motivo,
		e.IPOrigem, e.Dispositivo, e.Localizacao, e.EstadoAnterior, e.EstadoNovo,
	)
	return err
}
