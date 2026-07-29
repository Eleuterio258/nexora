-- Backfill da identidade civil em pessoas.pessoas a partir de rh.funcionarios.
--
-- pessoas.pessoas tem uma restrição única em (tipo_documento, numero_documento)
-- que é a chave de deduplicação da entidade Pessoa — é o que permite reconhecer
-- que o candidato que se está a contratar já existe no sistema como aluno,
-- cliente ou funcionário de outro tenant. Até aqui essa chave estava vazia em
-- TODAS as 162 pessoas: os fluxos criavam a pessoa só com o nome
-- (pessoas.EnsureUserPessoa) e gravavam o documento apenas na cópia em
-- rh.funcionarios. Resultado: a deduplicação nunca podia funcionar, e o mesmo
-- humano acabou espalhado por várias linhas (ELEUTERIO FULAHO NOTICO em 5).
--
-- O código passou a escrever a identidade na pessoa (EnsureUserPessoaComIdentidade),
-- mas isso só vale para registos novos. Esta migração trata dos que já existem.
--
-- COALESCE em todos os campos: nunca sobrepõe um valor já presente na pessoa —
-- se os dois lados divergem, o registo da pessoa é o que fica, e a divergência
-- é para resolver à mão, não em silêncio dentro de uma migração.

BEGIN;

UPDATE pessoas.pessoas p
   SET tipo_documento   = COALESCE(p.tipo_documento,   NULLIF(f.tipo_documento, '')),
       numero_documento = COALESCE(p.numero_documento, NULLIF(f.numero_documento, '')),
       nuit             = COALESCE(p.nuit,             NULLIF(f.nuit, '')),
       data_nascimento  = COALESCE(p.data_nascimento,  f.data_nascimento),
       nacionalidade    = COALESCE(p.nacionalidade,    NULLIF(f.nacionalidade, '')),
       updated_at       = NOW()
  FROM rh.funcionarios f
 WHERE f.pessoa_id = p.id
   -- Só quando o documento a copiar não colide com outra pessoa: uma colisão
   -- significa dois registos para o mesmo humano, o que se resolve fundindo,
   -- não escrevendo por cima.
   AND (
        f.numero_documento IS NULL OR f.numero_documento = ''
        OR NOT EXISTS (
            SELECT 1 FROM pessoas.pessoas p2
             WHERE p2.id <> p.id
               AND p2.tipo_documento   = NULLIF(f.tipo_documento, '')
               AND p2.numero_documento = NULLIF(f.numero_documento, '')
        )
   );

COMMIT;
