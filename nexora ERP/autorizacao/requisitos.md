# Requisitos — Modulo Autorizacao

## Requisitos Funcionais

### RF01 — Criacao de Roles
O sistema deve permitir criar roles por tenant com codigo unico, nome e descricao.

### RF02 — Definicao de Permissoes
O sistema deve suportar permissoes definidas por recurso e accao (ex: faturas:criar, clientes:editar).

### RF03 — Atribuicao de Permissoes a Roles
O sistema deve permitir associar multiplas permissoes a um role, e remover permissoes de um role.

### RF04 — Atribuicao de Roles a Utilizadores
O sistema deve permitir atribuir um ou mais roles a um utilizador, e remover roles de um utilizador.

### RF05 — Consulta de Permissoes por Utilizador
O sistema deve permitir consultar todas as permissoes efectivas de um utilizador (atraves dos seus roles).

### RF06 — Verificacao de Permissao
O sistema deve expor uma funcao de verificacao: dado um user_id e um codigo de permissao, retorna verdadeiro ou falso.

### RF07 — Roles por Tenant
Cada tenant pode definir os seus proprios roles. Roles de um tenant nao sao visiveis noutro.

### RF08 — Activacao e Desactivacao de Roles
O sistema deve permitir desactivar um role sem eliminar as suas permissoes ou atribuicoes.

---

## Requisitos Nao Funcionais

### RNF01 — Desempenho na Verificacao
A verificacao de permissao deve ser realizada em menos de 100ms, preferencialmente via cache.

### RNF02 — Cache de Permissoes
As permissoes efectivas por utilizador devem ser cacheadas e invalidadas quando roles ou permissoes sao alterados.

### RNF03 — Imutabilidade de Permissoes do Sistema
Permissoes base do sistema (definidas no codigo) nao devem poder ser eliminadas por utilizadores.

### RNF04 — Auditoria
Qualquer alteracao a roles, permissoes ou atribuicoes deve ser registada no modulo de auditoria.

### RNF05 — Principio do Menor Privilegio
Por omissao, um utilizador sem role nao deve ter acesso a nenhum recurso protegido.
