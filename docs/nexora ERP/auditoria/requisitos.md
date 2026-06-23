# Requisitos — Modulo Auditoria

## Requisitos Funcionais

### RF01 — Registo de Accao
O sistema deve registar cada accao relevante com: tenant_id, user_id, modulo, entidade, entidade_id, accao, detalhes e IP.

### RF02 — Detalhe em JSONB
O campo detalhes deve armazenar o estado anterior e/ou posterior da entidade alterada em formato JSONB.

### RF03 — Consulta por Filtros
O sistema deve permitir consultar audit_logs filtrando por: modulo, entidade, entidade_id, user_id e intervalo de datas.

### RF04 — Consulta por Tenant
Cada tenant deve ver apenas os seus proprios registos de auditoria.

### RF05 — Tipos de Accao Suportados
O sistema deve suportar os tipos de accao: criacao, alteracao, eliminacao, login, logout, bloqueio, exportacao e outros.

### RF06 — Registo sem Autenticacao
O sistema deve permitir registar eventos mesmo quando o user_id e desconhecido (ex: tentativas de login falhadas).

---

## Requisitos Nao Funcionais

### RNF01 — Imutabilidade
Registos de auditoria nunca devem ser alterados ou eliminados por utilizadores. Sao de escrita unica (append-only).

### RNF02 — Sem FK para users
A tabela audit_logs nao deve ter FK com cascata para users, garantindo que logs nao sao perdidos se um utilizador for eliminado.

### RNF03 — Desempenho de Escrita
O registo de auditoria deve ser assincrono (nao bloquear a operacao principal) e concluir em menos de 200ms.

### RNF04 — Retencao de Dados
Os registos de auditoria devem ser retidos por no minimo 2 anos. Registos mais antigos podem ser arquivados.

### RNF05 — Indexacao
Os campos tenant_id, modulo, user_id e created_at devem ser indexados para garantir consultas rapidas.

### RNF06 — Integridade
Nenhuma operacao do sistema pode suprimir o registo de auditoria correspondente, mesmo em caso de erro da operacao principal.
