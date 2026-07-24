package adapters

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/shared/contracts"
)

// SignatureAdapter implementa contracts.SignaturePort escrevendo
// directamente em assinatura_digital.documentos/signatarios.
type SignatureAdapter struct {
	db *pgxpool.Pool
}

// NewSignatureAdapter cria um novo adaptador de Assinatura Digital.
func NewSignatureAdapter(db *pgxpool.Pool) *SignatureAdapter {
	return &SignatureAdapter{db: db}
}

// CreateForSigning cria o documento em estado 'rascunho' e um único
// signatário. Não gera convite nem envia — isso fica a cargo do fluxo normal
// do assinatura-digital (POST /documentos/{id}/enviar), accionado por um
// humano do módulo de origem.
func (a *SignatureAdapter) CreateForSigning(ctx context.Context, r contracts.SignatureDocumentRequest) (int64, error) {
	var docID int64
	if err := a.db.QueryRow(ctx, `
		INSERT INTO assinatura_digital.documentos
			(tenant_id, titulo, descricao, hash_sha256, storage_key, ficheiro_url, status, created_by, origem_modulo, origem_id)
		VALUES ($1,$2,$3,$4,$5,$6,'rascunho',$7,$8,$9)
		RETURNING id`,
		r.TenantID, r.Titulo, nullStr(r.Descricao), r.HashSHA256, r.StorageKey, r.FicheiroURL, r.CreatedBy,
		r.OrigemModulo, r.OrigemID).Scan(&docID); err != nil {
		return 0, err
	}

	if _, err := a.db.Exec(ctx, `
		INSERT INTO assinatura_digital.signatarios (documento_id, tenant_id, nome, email, ordem, tipo, user_id)
		VALUES ($1,$2,$3,$4,1,'assinatura',$5)`,
		docID, r.TenantID, r.SignatarioNome, nullStr(r.SignatarioEmail), r.SignatarioUserID); err != nil {
		return 0, err
	}

	return docID, nil
}
