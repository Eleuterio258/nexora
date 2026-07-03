// Package aprovacoes expõe funções para integração de fluxos de aprovação
// em qualquer módulo do Nexora ERP.
//
// Uso típico (ex: compras ao submeter uma requisição):
//
//	flow, err := aprovacoes.NeedsApproval(ctx, db, tenantID, "compras.requisicoes", valor)
//	if err == nil && flow != nil {
//	    _ = aprovacoes.CreateRequest(ctx, db, tenantID, flow.ID, requisicaoID, userID,
//	                                 "compras.purchase_requests")
//	}
package aprovacoes

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Flow é o resumo de um fluxo de aprovação activo.
type Flow struct {
	ID     int64
	Nome   string
	Niveis int
}

// NeedsApproval verifica se existe um fluxo activo para a feature+tenant
// e se as condições (ex: valor_acima) se aplicam ao valor fornecido.
// Devolve nil quando não há fluxo — significa que não é necessária aprovação.
func NeedsApproval(ctx context.Context, db *pgxpool.Pool, tenantID int64, feature string, valor float64) (*Flow, error) {
	rows, err := db.Query(ctx, `
		SELECT id, nome, condicao, jsonb_array_length(niveis)
		  FROM saas.approval_flows
		 WHERE tenant_id = $1 AND feature = $2 AND ativo = TRUE
		 ORDER BY id
		 LIMIT 1`, tenantID, feature)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	if !rows.Next() {
		return nil, nil
	}

	var f Flow
	var condicao []byte
	if err := rows.Scan(&f.ID, &f.Nome, &condicao, &f.Niveis); err != nil {
		return nil, err
	}

	// Verificar condição de valor
	var cond map[string]any
	if err := json.Unmarshal(condicao, &cond); err == nil {
		if valorAcima, ok := cond["valor_acima"].(float64); ok && valor <= valorAcima {
			return nil, nil // Valor abaixo do limiar — sem aprovação necessária
		}
	}

	return &f, nil
}

// CreateRequest cria um pedido de aprovação para uma entidade.
// entidade: nome da tabela/recurso (ex: "compras.purchase_requests")
// entidadeID: PK da linha na tabela de origem
// criadoPor: ID do utilizador que submeteu
func CreateRequest(ctx context.Context, db *pgxpool.Pool, tenantID, flowID, entidadeID, criadoPor int64, entidade string) error {
	_, err := db.Exec(ctx, `
		INSERT INTO saas.approval_requests (tenant_id, flow_id, entidade, entidade_id, criado_por)
		VALUES ($1, $2, $3, $4, $5)`,
		tenantID, flowID, entidade, entidadeID, criadoPor)
	return err
}

// PendentesParaCargo devolve o número de pedidos pendentes que aguardam
// decisão do cargo indicado. Útil para badges de notificação.
func PendentesParaCargo(ctx context.Context, db *pgxpool.Pool, tenantID, cargoID int64) (int, error) {
	var count int
	err := db.QueryRow(ctx, `
		SELECT COUNT(*)
		  FROM saas.approval_requests ar
		  JOIN saas.approval_flows af ON af.id = ar.flow_id
		 WHERE ar.tenant_id = $1
		   AND ar.estado = 'pendente'
		   AND (af.niveis->>(ar.nivel_atual-1))::jsonb->>'cargo_id' = $2::text`,
		tenantID, cargoID).Scan(&count)
	return count, err
}
