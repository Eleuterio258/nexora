// Package pessoas dá acesso ao schema pessoas.* (entidade Pessoa central,
// ver docs/analise-modelo-pessoa-multi-tenant.md) a partir de qualquer
// módulo que crie contas de autenticação (auth.users).
package pessoas

import (
	"context"
	"errors"
	"strings"
	"time"

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
	return EnsureUserPessoaComIdentidade(ctx, tx, userID, nome, pessoaID, Identidade{})
}

// Identidade são os dados que identificam civilmente uma pessoa. O par
// (TipoDocumento, NumeroDocumento) é a chave de deduplicação — corresponde à
// restrição única uq_pessoas_documento — e é o que permite reconhecer que o
// candidato que agora se contrata já existe no sistema como aluno, cliente ou
// funcionário de outro tenant.
type Identidade struct {
	TipoDocumento   string
	NumeroDocumento string
	Nuit            string
	DataNascimento  *time.Time
	Nacionalidade   string
}

// temDocumento diz se a identidade traz a chave de deduplicação completa.
func (i Identidade) temDocumento() bool {
	return strings.TrimSpace(i.TipoDocumento) != "" && strings.TrimSpace(i.NumeroDocumento) != ""
}

// ErrDocumentoNoutraPessoa é devolvido quando o documento indicado já pertence
// a uma pessoa diferente daquela a que a conta está ligada. Significa que o
// mesmo humano existe duas vezes em pessoas.pessoas: resolver isso é uma fusão
// de registos, decisão de quem opera, não algo a fazer em silêncio a meio de
// uma contratação.
var ErrDocumentoNoutraPessoa = errors.New("documento já pertence a outra pessoa")

// EnsureUserPessoaComIdentidade é o EnsureUserPessoa com os dados civis da
// pessoa. Além de ligar a conta, faz duas coisas que a versão sem identidade
// não podia fazer:
//
//  1. procura por documento antes de criar — sem isto cada fluxo criava uma
//     pessoa nova a partir do nome e o mesmo humano acabava espalhado por
//     várias linhas;
//  2. completa os campos em falta da pessoa (documento, NUIT, nascimento,
//     nacionalidade), sem nunca sobrepor valores já preenchidos.
func EnsureUserPessoaComIdentidade(ctx context.Context, tx Execer, userID int64, nome string, pessoaID *int64, ident Identidade) (int64, error) {
	var actual *int64
	if err := tx.QueryRow(ctx, `SELECT pessoa_id FROM auth.users WHERE id = $1`, userID).Scan(&actual); err != nil {
		return 0, err
	}
	if actual != nil {
		if err := CompletarIdentidade(ctx, tx, *actual, ident); err != nil {
			return 0, err
		}
		return *actual, nil
	}

	var novoID int64
	switch {
	case pessoaID != nil && *pessoaID > 0:
		novoID = *pessoaID
		if err := CompletarIdentidade(ctx, tx, novoID, ident); err != nil {
			return 0, err
		}

	default:
		// Reconhecer antes de criar: se já existe alguém com este documento, é
		// a mesma pessoa noutro papel.
		if ident.temDocumento() {
			var existente int64
			err := tx.QueryRow(ctx, `
				SELECT id FROM pessoas.pessoas
				 WHERE tipo_documento = $1 AND numero_documento = $2`,
				strings.TrimSpace(ident.TipoDocumento), strings.TrimSpace(ident.NumeroDocumento),
			).Scan(&existente)
			switch {
			case err == nil:
				novoID = existente
				if err := CompletarIdentidade(ctx, tx, novoID, ident); err != nil {
					return 0, err
				}
			case errors.Is(err, pgx.ErrNoRows):
				// segue para a criação
			default:
				return 0, err
			}
		}
		if novoID == 0 {
			if err := tx.QueryRow(ctx, `
				INSERT INTO pessoas.pessoas
				    (nome_completo, tipo_documento, numero_documento, nuit, data_nascimento, nacionalidade)
				VALUES ($1, NULLIF($2,''), NULLIF($3,''), NULLIF($4,''), $5, NULLIF($6,''))
				RETURNING id`,
				nome, strings.TrimSpace(ident.TipoDocumento), strings.TrimSpace(ident.NumeroDocumento),
				strings.TrimSpace(ident.Nuit), ident.DataNascimento, strings.TrimSpace(ident.Nacionalidade),
			).Scan(&novoID); err != nil {
				return 0, err
			}
		}
	}

	if _, err := tx.Exec(ctx, `UPDATE auth.users SET pessoa_id = $1 WHERE id = $2`, novoID, userID); err != nil {
		return 0, err
	}
	return novoID, nil
}

// CompletarIdentidade preenche os campos civis que a pessoa ainda não tem.
// Nunca sobrepõe um valor existente (COALESCE sobre a coluna): o registo mais
// antigo é o que já foi conferido contra documento, e uma contratação não é
// sítio para o corrigir em silêncio.
func CompletarIdentidade(ctx context.Context, tx Execer, pessoaID int64, ident Identidade) error {
	if ident == (Identidade{}) {
		return nil
	}

	// Se o documento já está noutra pessoa, escrevê-lo aqui violaria
	// uq_pessoas_documento — e o que isso indica é um duplicado por fundir.
	if ident.temDocumento() {
		var dono int64
		err := tx.QueryRow(ctx, `
			SELECT id FROM pessoas.pessoas
			 WHERE tipo_documento = $1 AND numero_documento = $2`,
			strings.TrimSpace(ident.TipoDocumento), strings.TrimSpace(ident.NumeroDocumento),
		).Scan(&dono)
		if err != nil && !errors.Is(err, pgx.ErrNoRows) {
			return err
		}
		if err == nil && dono != pessoaID {
			return ErrDocumentoNoutraPessoa
		}
	}

	_, err := tx.Exec(ctx, `
		UPDATE pessoas.pessoas
		   SET tipo_documento   = COALESCE(tipo_documento,   NULLIF($2,'')),
		       numero_documento = COALESCE(numero_documento, NULLIF($3,'')),
		       nuit             = COALESCE(nuit,             NULLIF($4,'')),
		       data_nascimento  = COALESCE(data_nascimento,  $5),
		       nacionalidade    = COALESCE(nacionalidade,    NULLIF($6,'')),
		       updated_at       = NOW()
		 WHERE id = $1`,
		pessoaID, strings.TrimSpace(ident.TipoDocumento), strings.TrimSpace(ident.NumeroDocumento),
		strings.TrimSpace(ident.Nuit), ident.DataNascimento, strings.TrimSpace(ident.Nacionalidade))
	return err
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
