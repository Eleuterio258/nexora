-- pessoas.v_pessoa_tipos — os papéis de domínio de uma pessoa.
--
-- A vista que já existia, v_pessoa_papeis, só olha para auth.memberships:
-- responde "em que tenants esta conta entra e com que cargo", não "o que é
-- esta pessoa". No modelo Pessoa o tipo não é uma coluna — é a existência de
-- uma linha no domínio: alguém é funcionário PORQUE tem linha em
-- rh.funcionarios, candidato PORQUE tem linha em recrutamento.candidatos. Uma
-- mesma pessoa pode ter várias em simultâneo, inclusive em tenants diferentes
-- (foi o caso da Ana Paulo Machava: candidata e funcionária sobre a pessoa 102).
--
-- Esta vista materializa essa leitura num sítio só, para o /api/auth/me não ter
-- de repetir seis UNIONs e para que acrescentar um domínio novo seja mudar aqui.
--
-- referencia_id é o id da linha no domínio (funcionario_id, aluno_id, ...), para
-- quem consome poder navegar até ao registo.

CREATE OR REPLACE VIEW pessoas.v_pessoa_tipos AS
    SELECT f.pessoa_id, 'funcionario'::text AS tipo, f.tenant_id, f.id AS referencia_id,
           f.nome_completo AS nome, (f.estado = 'ativo') AS activo
      FROM rh.funcionarios f
     WHERE f.pessoa_id IS NOT NULL
 UNION ALL
    SELECT c.pessoa_id, 'candidato', c.tenant_id, c.id, c.nome, c.ativo
      FROM recrutamento.candidatos c
     WHERE c.pessoa_id IS NOT NULL
 UNION ALL
    SELECT t.pessoa_id, 'professor', t.tenant_id, t.id, t.nome_completo, (t.status = 'ativo')
      FROM gestao_escolar.school_teachers t
     WHERE t.pessoa_id IS NOT NULL
 UNION ALL
    SELECT s.pessoa_id, 'aluno', s.tenant_id, s.id, s.nome, (s.estado = 'ativo')
      FROM gestao_escolar.school_students s
     WHERE s.pessoa_id IS NOT NULL
 UNION ALL
    SELECT g.pessoa_id, 'encarregado', g.tenant_id, g.id, g.nome, TRUE
      FROM gestao_escolar.school_guardians g
     WHERE g.pessoa_id IS NOT NULL
 UNION ALL
    SELECT cl.pessoa_id, 'cliente', cl.tenant_id, cl.id, cl.nome, (cl.estado = 'ativo')
      FROM clientes.customers cl
     WHERE cl.pessoa_id IS NOT NULL;

COMMENT ON VIEW pessoas.v_pessoa_tipos IS
    'Papéis de domínio por pessoa (funcionario/candidato/professor/aluno/encarregado/cliente). '
    'Complementa v_pessoa_papeis, que cobre apenas as memberships de autenticação.';
