# User Stories — Sprint 1: Fundação da Plataforma

**Duração:** 2 semanas  
**Objetivo da Sprint:** Estabelecer a base técnica do sistema (ambiente, base de dados espacial, autenticação e gestão inicial de organizações e divisões administrativas).

---

## US-001: Configurar ambiente de desenvolvimento containerizado

**Como** desenvolvedor,  
**quero** ter um ambiente de desenvolvimento padronizado com Docker Compose,  
**para que** toda a equipa possa iniciar a aplicação localmente de forma consistente.

### Critérios de Aceitação
- [ ] O repositório contém `docker-compose.yml` com PostgreSQL/PostGIS, GeoServer e MinIO.
- [ ] O backend ASP.NET Core inicia corretamente via Docker.
- [ ] Existe documentação (`README.md`) com instruções de setup.
- [ ] O frontend web inicia localmente e comunica com a API.

### Tarefas Técnicas
1. Criar estrutura de solução .NET (API, Application, Domain, Infrastructure).
2. Configurar Dockerfile para a API.
3. Configurar `docker-compose.yml` com rede interna e volumes persistentes.
4. Criar `appsettings.Development.json` com connection strings.
5. Documentar passos de instalação no `README.md`.

**Estimativa:** 5 pontos  
**Responsável:** DevOps / Tech Lead

---

## US-002: Criar base de dados espacial com PostGIS

**Como** arquiteto de software,  
**quero** que o schema do PostgreSQL/PostGIS esteja criado e versionado via migrations,  
**para que** os dados geoespaciais possam ser armazenados e consultados corretamente.

### Critérios de Aceitação
- [ ] O schema `territorial`, `cadastro`, `gis`, `workflow` e `audit` está criado.
- [ ] A tabela `territorial.divisao_administrativa` suporta hierarquia recursiva e geometria.
- [ ] As tabelas `cadastro.parcela`, `cadastro.edificacao` e `cadastro.entidade` estão criadas.
- [ ] As triggers de auditoria estão ativas nas tabelas principais.
- [ ] As migrations do EF Core podem ser aplicadas com `dotnet ef database update`.

### Tarefas Técnicas
1. Configurar EF Core com Npgsql e NetTopologySuite.
2. Mapear as entidades principais (organização, utilizador, divisão administrativa, parcela, edificação).
3. Criar a primeira migration inicial.
4. Executar o script SQL de schema e verificar a criação das tabelas.
5. Criar teste de integração para verificar conexão e aplicação da migration.

**Estimativa:** 8 pontos  
**Responsável:** Backend / DBA

---

## US-003: Implementar autenticação com JWT

**Como** utilizador do sistema,  
**quero** poder fazer login com username e password,  
**para que** possa aceder de forma segura às funcionalidades autorizadas.

### Critérios de Aceitação
- [ ] Endpoint `POST /api/v1/auth/login` autentica utilizador e retorna JWT.
- [ ] Endpoint `POST /api/v1/auth/refresh` renova o token.
- [ ] Endpoint `POST /api/v1/auth/register` cria novos utilizadores (apenas admin).
- [ ] Passwords são armazenadas com hash seguro (bcrypt/argon2).
- [ ] Tentativas de login inválidas retornam 401.

### Tarefas Técnicas
1. Implementar Identity ou serviço customizado de autenticação.
2. Configurar JWT issuer, audience, expiration e secret.
3. Criar controller `AuthController`.
4. Adicionar middleware de autenticação na pipeline.
5. Criar testes unitários para login e registo.

**Estimativa:** 8 pontos  
**Responsável:** Backend

---

## US-004: Criar perfis e permissões base

**Como** administrador,  
**quero** definir perfis de utilizador e permissões por recurso,  
**para que** cada utilizador aceda apenas ao que lhe compete.

### Critérios de Aceitação
- [ ] Perfis pré-definidos: Administrador, Gestor do Plano, Técnico GIS, Topógrafo, Técnico de Campo, Fiscal, Consulta.
- [ ] Tabela `territorial.permissao` permite configurar `perfil`, `recurso` e `acao`.
- [ ] O middleware de autorização verifica permissão antes de executar a ação.
- [ ] Apenas Administrador pode criar utilizadores.

### Tarefas Técnicas
1. Criar entidade `Permissao` e seed inicial.
2. Implementar serviço de autorização baseado em claims.
3. Criar atributo `[RequerPermissao("recurso", "acao")]`.
4. Aplicar autorização nos controllers.
5. Testar cenários de acesso permitido e negado.

**Estimativa:** 5 pontos  
**Responsável:** Backend

---

## US-005: Gerir organizações (multi-tenant)

**Como** administrador,  
**quero** criar e gerir organizações (municípios, empresas, instituições),  
**para que** os dados de cada cliente estejam isolados.

### Critérios de Aceitação
- [ ] CRUD de organizações via `POST/GET/PUT/DELETE /api/v1/organizations`.
- [ ] Cada utilizador pertence a uma única organização.
- [ ] Utilizadores só acedem a dados da sua organização.
- [ ] Campos: código, designação, tipo, NUIT, email, telefone, endereço.

### Tarefas Técnicas
1. Criar entidade `Organizacao` e seu CRUD.
2. Adicionar `OrganizationId` como claim do JWT.
3. Implementar filtro automático por organização nos repositórios.
4. Criar interface web para gestão de organizações.
5. Criar testes de integração.

**Estimativa:** 5 pontos  
**Responsável:** Backend + Frontend

---

## US-006: Gerir divisões administrativas

**Como** gestor do plano,  
**quero** criar e editar divisões administrativas (províncias, cidades, distritos, bairros),  
**para que** a estrutura territorial de Moçambique esteja representada no sistema.

### Critérios de Aceitação
- [ ] CRUD de divisões administrativas via API.
- [ ] Suporte a hierarquia pai/filho.
- [ ] Campos: código, nome, tipo, zona urbana/rural, entidade responsável, código INE.
- [ ] É possível visualizar o caminho hierárquico completo de uma divisão.
- [ ] Validação: código único e tipo válido.

### Tarefas Técnicas
1. Criar entidade `DivisaoAdministrativa` e DTOs.
2. Implementar endpoints RESTful.
3. Criar view recursiva `vw_divisao_hierarquia`.
4. Criar interface web em árvore para navegação.
5. Aplicar seeds de Moçambique (províncias e principais distritos).

**Estimativa:** 8 pontos  
**Responsável:** Backend + Frontend

---

## US-007: Importar seeds de Moçambique

**Como** administrador,  
**quero** carregar os dados base de Moçambique (províncias, cidades e distritos),  
**para que** o sistema já tenha a estrutura territorial inicial disponível.

### Critérios de Aceitação
- [ ] Script `seeds_mocambique.sql` executa sem erros.
- [ ] Todas as 11 províncias/cidade estão inseridas.
- [ ] Principais distritos/cidades de cada província estão inseridos.
- [ ] A contagem por tipo é exibida corretamente no final do script.

### Tarefas Técnicas
1. Revisar e validar o script `seeds_mocambique.sql`.
2. Garantir que os códigos são únicos.
3. Executar o script no ambiente de desenvolvimento.
4. Criar teste de verificação da contagem de divisões.
5. Documentar como executar os seeds.

**Estimativa:** 3 pontos  
**Responsável:** DBA / Backend

---

## US-008: Configurar logging e monitoramento base

**Como** equipa de operações,  
**quero** ter logs estruturados das operações críticas,  
**para que** seja possível auditar e diagnosticar problemas.

### Critérios de Aceitação
- [ ] Logs estruturados com Serilog em JSON.
- [ ] Logs incluem request path, status code, tempo de execução e erros.
- [ ] Tabela `audit.log` registra criação/alteração/exclusão de entidades principais.
- [ ] Logs acessíveis localmente e no container.

### Tarefas Técnicas
1. Configurar Serilog no `Program.cs`.
2. Adicionar middleware de logging de requests.
3. Verificar triggers de auditoria no schema.
4. Criar endpoint simples para consulta de logs de auditoria.
5. Documentar estratégia de logging.

**Estimativa:** 3 pontos  
**Responsável:** Backend / DevOps

---

## Resumo da Sprint 1

| User Story | Pontos | Responsável | Prioridade |
|------------|--------|-------------|------------|
| US-001: Ambiente Docker | 5 | DevOps | Alta |
| US-002: Base de dados PostGIS | 8 | Backend/DBA | Alta |
| US-003: Autenticação JWT | 8 | Backend | Alta |
| US-004: Perfis e permissões | 5 | Backend | Alta |
| US-005: Organizações | 5 | Backend + Frontend | Alta |
| US-006: Divisões administrativas | 8 | Backend + Frontend | Alta |
| US-007: Seeds de Moçambique | 3 | DBA | Média |
| US-008: Logging e auditoria | 3 | Backend/DevOps | Média |
| **Total** | **45 pontos** | | |

## Definição de Pronto (DoD)

Para cada user story estar concluída:

1. Código implementado e revisado (code review).
2. Testes unitários/integração passando.
3. Documentação técnica atualizada.
4. Funcionalidade testada no ambiente de desenvolvimento.
5. Sem bugs críticos ou bloqueadores.
6. Merge realizado na branch principal.

## Riscos da Sprint

| Risco | Mitigação |
|-------|-----------|
| Configuração complexa do PostGIS | Usar imagem oficial `postgis/postgis` e testar localmente primeiro |
| Problemas de CORS entre frontend e API | Configurar CORS explicitamente no backend |
| Seeds com códigos duplicados | Validar unicidade antes de executar o script |
| Dificuldade em mapear geometrias com EF Core | Usar NetTopologySuite e criar testes de integração |
