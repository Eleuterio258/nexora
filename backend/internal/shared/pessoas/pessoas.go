// Package pessoas dá acesso ao schema pessoas.* (entidade Pessoa central,
// ver docs/analise-modelo-pessoa-multi-tenant.md) a partir de qualquer
// módulo que crie contas de autenticação (auth.users).
package pessoas

import (
	"context"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

// Execer é o subconjunto de *pgxpool.Pool / pgx.Tx necessário para ligar
// contas a pessoas. Permite chamar EnsureUserPessoa tanto fora como dentro
// de uma transacção.
type Execer interface {
	QueryRow(ctx context.Context, sql string, args ...interface{}) pgx.Row
	Exec(ctx context.Context, sql string, args ...interface{}) (pgconn.CommandTag, error)
}

// EnsureUserPessoa garante que auth.users.id=userID tem pessoa_id
// preenchido e devolve esse id. É idempotente:
//   - se o user já tiver pessoa_id, devolve-o sem alterar nada;
//   - se pessoaID for indicado (não nil), liga a conta a essa pessoa
//     existente — cabe ao chamador validar que faz sentido ligar-se a ela;
//   - caso contrário, cria uma pessoa nova a partir do nome (mesma lógica
//     do backfill da migration 20260713000001_pessoas_fase1).
func EnsureUserPessoa(ctx context.Context, tx Execer, userID int64, nome string, pessoaID *int64) (int64, error) {
	var actual *int64
	if err := tx.QueryRow(ctx, `SELECT pessoa_id FROM auth.users WHERE id = $1`, userID).Scan(&actual); err != nil {
		return 0, err
	}
	if actual != nil {
		return *actual, nil
	}

	var novoID int64
	if pessoaID != nil && *pessoaID > 0 {
		novoID = *pessoaID
	} else {
		if err := tx.QueryRow(ctx, `
			INSERT INTO pessoas.pessoas (nome_completo) VALUES ($1)
			RETURNING id`, nome).Scan(&novoID); err != nil {
			return 0, err
		}
	}

	if _, err := tx.Exec(ctx, `UPDATE auth.users SET pessoa_id = $1 WHERE id = $2`, novoID, userID); err != nil {
		return 0, err
	}
	return novoID, nil
}

// EnsurePessoa cria sempre uma pessoa nova a partir do nome, sem conta de
// autenticação associada — usada para encarregados/contactos de emergência,
// que não têm (nem precisam de) auth.users.
func EnsurePessoa(ctx context.Context, tx Execer, nome string) (int64, error) {
	var novoID int64
	if err := tx.QueryRow(ctx, `
		INSERT INTO pessoas.pessoas (nome_completo) VALUES ($1)
		RETURNING id`, nome).Scan(&novoID); err != nil {
		return 0, err
	}
	return novoID, nil
}

// tiposRelacaoValidos espelha o CHECK de pessoas.pessoa_relacoes.tipo_relacao.
var tiposRelacaoValidos = map[string]string{
	"pai": "pai", "mae": "mae", "mãe": "mae",
	"tutor": "tutor", "encarregado": "encarregado", "encarregada": "encarregado",
	"filho": "filho", "filha": "filha",
	"conjuge": "conjuge", "cônjuge": "conjuge", "esposo": "conjuge", "esposa": "conjuge",
	"irmao": "irmao", "irmão": "irmao", "irma": "irma", "irmã": "irma",
	"avo": "avo", "avô": "avo", "avó": "avo",
	"avo materno": "avo_materno", "avô materno": "avo_materno", "avó materna": "avo_materno",
	"avo paterno": "avo_paterno", "avô paterno": "avo_paterno", "avó paterna": "avo_paterno",
	"tio": "tio", "tia": "tia",
}

// normalizarTipoRelacao mapeia um parentesco em texto livre (ex.: "Pai",
// "Tio", "Mãe") para um dos valores aceites por pessoa_relacoes.tipo_relacao,
// com fallback 'outro' quando não reconhecido — nunca falha.
func normalizarTipoRelacao(parentesco string) string {
	chave := strings.ToLower(strings.TrimSpace(parentesco))
	if tipo, ok := tiposRelacaoValidos[chave]; ok {
		return tipo
	}
	return "outro"
}

// LinkPessoaRelacao regista uma relação pessoa→pessoa (ex.: encarregado→aluno,
// contacto de emergência→funcionário), mapeando o parentesco em texto livre
// para o tipo_relacao permitido (fallback 'outro' — nunca bloqueia a criação
// do registo de negócio por causa de um parentesco não reconhecido).
func LinkPessoaRelacao(ctx context.Context, tx Execer, tenantID, pessoaID, pessoaRelacionadaID int64, parentesco string, principal bool) error {
	_, err := tx.Exec(ctx, `
		INSERT INTO pessoas.pessoa_relacoes (tenant_id, pessoa_id, pessoa_relacionada_id, tipo_relacao, principal)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (tenant_id, pessoa_id, pessoa_relacionada_id, tipo_relacao, data_inicio) DO NOTHING`,
		tenantID, pessoaID, pessoaRelacionadaID, normalizarTipoRelacao(parentesco), principal)
	return err
}
