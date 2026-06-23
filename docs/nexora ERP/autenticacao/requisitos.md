# Requisitos — Modulo Autenticacao

## Requisitos Funcionais

### RF01 — Criacao de Conta
O sistema deve permitir criar utilizadores com nome, email, password e telefone, associados a um tenant.

### RF02 — Login por Email e Password
O sistema deve autenticar utilizadores por email e password, gerando um token de sessao em caso de sucesso.

### RF03 — Registo de Tentativas de Login
O sistema deve registar todas as tentativas de login (sucesso e falha), incluindo IP, user agent e motivo de falha.

### RF04 — Gestao de Sessoes
O sistema deve criar sessoes com prazo de expiracao, permitir renovacao (refresh) e revogacao manual.

### RF05 — Bloqueio de Conta
O sistema deve permitir bloquear manualmente uma conta de utilizador, impedindo novos logins.

### RF06 — Recuperacao de Password
O sistema deve gerar tokens de recuperacao de password com prazo de validade e invalidar o token apos uso.

### RF07 — Autenticacao por API Key
O sistema deve suportar autenticacao via API Key para integracoes externas, com controlo de expiracao e revogacao.

### RF08 — Listagem de Sessoes Activas
O sistema deve permitir ao utilizador ver e revogar as suas sessoes activas em qualquer dispositivo.

### RF09 — Estados de Utilizador
O sistema deve suportar os estados: ativo, bloqueado, pendente e inativo.

### RF10 — Email Unico por Tenant
O email deve ser unico por empresa (tenant), permitindo que o mesmo email exista em empresas diferentes.

---

## Requisitos Nao Funcionais

### RNF01 — Seguranca de Passwords
As passwords devem ser armazenadas com hash seguro (bcrypt ou argon2). Nunca em texto simples.

### RNF02 — Seguranca de Tokens
Tokens de sessao e API Keys devem ser armazenados como hash. O valor em claro nunca deve ser persistido.

### RNF03 — Expiracao de Sessao
Sessoes devem expirar apos inactividade configuravel. O refresh token deve ter expiracao mais longa que o access token.

### RNF04 — Proteccao contra Brute Force
Apos N tentativas de login falhadas consecutivas, a conta deve ser bloqueada temporariamente.

### RNF05 — Desempenho
A verificacao de credenciais deve responder em menos de 500ms em condicoes normais de carga.

### RNF06 — HTTPS Obrigatorio
Todos os endpoints de autenticacao devem operar exclusivamente sobre HTTPS.

### RNF07 — Auditoria
Todos os logins, logouts, bloqueios e alteracoes de password devem ser registados no modulo de auditoria.
