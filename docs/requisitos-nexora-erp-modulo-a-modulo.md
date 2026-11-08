# Nexora ERP — Requisitos por módulo
## Documento de Requisitos de Negócio (BRD) — catálogo modular

Versão 0.2 | 15 de outubro de 2026 | E258TECH

33 módulos | 207 requisitos funcionais | Regras transversais, requisitos não funcionais, estado de implementação e rastreabilidade de defeitos

Estado: proposta para validação funcional. Complementa o BRD geral do Nexora ERP. Os requisitos descrevem comportamento pretendido; a coluna "Estado" descreve o que a análise do código encontrou, **não** uma homologação.

### Histórico de versões

| Versão | Data | Alteração |
|---|---|---|
| 0.1 | 14/10/2026 | Catálogo inicial: 157 requisitos em 33 módulos, sem estado de implementação. |
| 0.2 | 15/10/2026 | Estado por requisito; evidência do backend por módulo (rotas, testes, permissões); 50 requisitos novos, sobretudo para funcionalidades já expostas no router e não catalogadas, e alguns para lacunas reveladas pelos defeitos (ex.: RF-M01-07, RF-M13-06, RF-M28-05); 6 achados novos (N-01 a N-06); secções de processos automáticos, interfaces externas, requisitos não funcionais, matriz de rastreabilidade e resumo por módulo. |

## 1. Como utilizar este catálogo

Cada módulo tem objetivo, intervenientes, dependências, evidência observada no backend, requisitos com estado e critérios de aceitação. Os identificadores RF-Mxx-nn permitem associar tarefas, testes e decisões a um requisito. Os requisitos acrescentados na versão 0.2 continuam a numeração de cada módulo e estão assinalados com "(v0.2)".

P1: obrigatório quando o módulo faz parte da fase aprovada. P2: evolução importante, sujeita à prioridade de negócio. A prioridade não significa que todos os 33 módulos devem ser entregues simultaneamente. A entrada em produção depende da homologação dos requisitos incluídos e da resolução dos defeitos que os bloqueiam.

**Base de levantamento.** Pastas `backend/internal/modules`, `backend/internal/router/router.go`, `backend/internal/background`, `backend/internal/shared/adapters` e a baseline `backend/migrations/20260724080001_baseline_schema.up.sql`; [análise do backend de 14/10](analise-backend-2026-10-14.md) (achados AI-01 a AI-12); [análise aprofundada de 14/10](analise-profunda-backend-modulos-2026-10-14.md) (AP-01 a AP-20); [continuação de 15/10](analise-backend-continuacao-2026-10-15.md) (AP-21 a AP-24); verificação complementar desta versão (N-01 a N-06, secção 36); [BRD geral](brd-nexora-erp.md). Não foram realizadas entrevistas, alterações de código, ligações à base remota nem testes funcionais. Não houve commits no backend depois das análises de 14–15/10; os achados AP citados foram reconfirmados por leitura do código actual.

### Estados de requisito

| Estado | Significado |
|---|---|
| **Proposta** | Não foi identificada implementação exposta. |
| **Parcial** | Há implementação exposta no router; falta demonstrar pelo menos um critério de aceitação ou a composição do processo. |
| **Risco** | Há implementação, mas um defeito de concorrência, configuração ou validação pode violar o critério em condições plausíveis. |
| **Bloqueado** | Um defeito identificado contradiz o critério diretamente ou impede a operação no esquema versionado. |
| **Verificado** | Critérios demonstrados tecnicamente com PostgreSQL real e cenários negativos. Nenhum requisito tem ainda este estado. |
| **Homologado** | Aceite pelo responsável funcional. Nenhum requisito tem ainda este estado. |

"Parcial" não é uma percentagem e não significa que o requisito esteja quase concluído. Um handler cuja query não corresponde à migração não é "implementado"; uma função chamada indiretamente por um serviço não é "inexistente".

### Regras transversais obrigatórias

RT-01 — Toda consulta, alteração, exportação, notificação e descarga de ficheiro deve respeitar a organização e o perfil autorizado. Um ID válido não concede acesso. Referências recebidas no pedido (plano, empresa, centro, cliente, participante, utilizador destino) são validadas no contexto da organização antes de gravar. *Violações conhecidas: AP-01, AP-12, AP-13, AI-04, AI-05, N-01.*

RT-02 — Operações com vários efeitos obrigatórios só confirmam sucesso depois de todos serem persistidos. Uma falha deve preservar a coerência do processo. Efeitos assíncronos usam outbox persistida com estado, repetição e reconciliação. *Violações conhecidas: AP-02, AP-17, AI-03, N-04.*

RT-03 — Eventos repetidos não duplicam efeitos. Correções, cancelamentos e estornos exigem ação explícita, motivo e autorização. Saldos e limites são validados sob bloqueio ou atualização condicional. *Violações conhecidas: AP-04, AP-05, AP-24, AI-10, N-02, N-04.*

RT-04 — Dados pessoais, segredos e evidências devem ter acesso e retenção definidos. Logs e URLs não devem divulgar tokens ou credenciais. *Violações conhecidas: AI-01, AI-12 (token do chat na query string).*

RT-05 — Alterações críticas devem registar ator, organização, instante, ação, referência e resultado. A política de retenção é aprovada por negócio e operação. Uma auditoria obrigatória que falha não pode ser silenciosamente ignorada.

RT-06 — Regras fiscais, salariais, académicas e contratuais precisam de aprovação dos responsáveis competentes. Este documento não fixa taxas legais nem atesta conformidade.

RT-07 (v0.2) — Estados de negócio usam um vocabulário único por entidade, igual no esquema, nos handlers e nos jobs. Um valor fora do vocabulário é rejeitado e nunca é aceite do cliente quando a transição exige fluxo próprio. *Violações conhecidas: AP-06, AP-19, AP-21, AP-22.*

RT-08 (v0.2) — Erros de base de dados (Begin, Query, Scan, Exec, Commit) nunca produzem resposta de sucesso nem resultado vazio aparente. *Violações conhecidas: AP-18, AI-03, AI-04, M11 (listagem de marcas), M29 (reordenação), N-01 (atividade).*

Cada módulo deve ser homologado com utilizador autorizado, utilizador sem permissão e utilizador de outra organização, além dos cenários próprios abaixo. A administração global tem regras especiais documentadas no módulo Superadmin.

### Leitura das fichas de módulo

"Evidência" indica rotas registadas no router (contagem exata a partir de `router.go`, incluindo rotas públicas e de integração do módulo), ficheiros Go de produção e de teste dentro da pasta do módulo e os códigos RBAC verificados no router (`modulo.acao`). Ficheiros de teste contam ficheiros, não casos nem cobertura.

## 2. M01 — Autenticação e autorização

Origem: auth. Objetivo: controlar identidade, sessões e acesso. Intervenientes: utilizadores, administrador da organização e administração da plataforma. Dependências: empresas, segurança, utilizadores e memberships.

Evidência: 52 rotas (`/api/auth`, `/api/authcode`, `/oauth/authorize|token|jwks`, `/api/v1/users`); 23 ficheiros Go, 6 de teste. Permissões: `autorizacao.gerir_utilizadores`, `autorizacao.gerir_perfis`, `auth.pin_admin`. Tokens HS256 e RS256, sessões persistidas, memberships e verificação do host do tenant.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M01-01 / P1 | Autenticar por credenciais e métodos adicionais habilitados, incluindo PIN/TOTP quando aplicáveis. | Credenciais válidas de conta ativa permitem entrada; inválidas, bloqueadas ou excessivas são rejeitadas conforme política. | Risco — AI-08 |
| RF-M01-02 / P1 | Criar, renovar, listar e revogar sessões. | Uma sessão revogada não permite novas operações; renovação respeita validade e identidade da sessão. | Parcial — AI-12 (WebSocket não revalida revogação) |
| RF-M01-03 / P1 | Recuperar e alterar senha com prova válida e uso único. | Dois pedidos concorrentes não consomem o mesmo token; falha de persistência não devolve sucesso; hashes inválidos não são gravados. | Bloqueado — AI-03 |
| RF-M01-04 / P1 | Gerir contas, cargos, permissões diretas e memberships. | Acesso deriva da atribuição válida; a retirada de permissão impede a ação correspondente. | Bloqueado — AP-01 |
| RF-M01-05 / P1 | Selecionar organização e papel entre vínculos ativos. | O contexto selecionado controla todos os recursos acessíveis; outro vínculo não autoriza operações no contexto errado. | Bloqueado — AP-01; `RequireAuth` não exige membership ativa |
| RF-M01-06 / P1 | Disponibilizar autorização OAuth aos clientes registados e exigir reautenticação em ações sensíveis. | Cliente não autorizado, prova expirada ou fluxo inválido não recebe acesso; operação sensível exige prova recente. | Parcial |
| RF-M01-07 / P1 (v0.2) | Limitar tentativas de login, PIN, TOTP, recuperação de senha e OAuth por conta e por origem, com estado partilhado entre réplicas. | Após o limite aprovado, novas tentativas recebem atraso/bloqueio temporário; o bloqueio de uma conta não pode ser provocado indefinidamente por terceiros. | Proposta — AI-08 (sem limite na aplicação) |
| RF-M01-08 / P2 (v0.2) | Verificar email e consultar histórico de login e sessões ativas. | Link de verificação é de uso único; histórico mostra apenas eventos do próprio utilizador ou do âmbito autorizado. | Parcial |
| RF-M01-09 / P2 (v0.2) | Expor API de gestão de utilizadores à aplicação PayCore (`/api/v1/users`). | Cliente PayCore só gere utilizadores da organização autorizada; operações deixam auditoria. | Parcial |

Regras: limitar tentativas por conta e origem; diferenciar administração de conta de preferências pessoais. Permissões diretas devem ter semântica explícita por membership/tenant (AP-01). Decisões pendentes: política de senha (incluindo limite de 72 bytes do bcrypt), tempos de sessão, métodos obrigatórios e clientes autorizados.

## 3. M02 — Utilizadores

Origem: utilizadores. Objetivo: gerir a experiência pessoal e recursos associados à conta. Intervenientes: utilizador e administrador autorizado. Dependências: auth, notificações e armazenamento.

Evidência: 25 rotas (`/api/utilizadores/perfis`, `/api/utilizadores/{userId}/…`); 11 ficheiros Go, 0 de teste. Permissões: `perfil.ver_perfil`, `perfil.editar_perfil`. A maioria dos handlers compara o utilizador autenticado com `{userId}`; as exceções estão em N-01. A tabela `user_agenda`, ausente da baseline, foi reposta no commit 6a2d5b64.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M02-01 / P1 | Consultar e atualizar perfil, avatar e preferências permitidas. | Alterações afetam a própria conta; ficheiros inválidos são rejeitados; campos protegidos não são alterados. | Parcial — N-01 (avatar de terceiros legível) |
| RF-M02-02 / P1 | Consultar dispositivos e tokens e revogar os recursos próprios autorizados. | Uma revogação impede o uso futuro do recurso; tokens e dispositivos de outra conta não são expostos. | Parcial — remover dispositivo não demonstra revogar sessões |
| RF-M02-03 / P2 | Gerir agenda e consultar atividade pessoal. | Um item guarda data e referência corretas e só é visível no âmbito autorizado. | Risco — N-01 (atividade forjável) |
| RF-M02-04 / P1 | Consultar notificações pessoais e marcar leitura. | Marcar uma ou todas como lidas só altera as notificações do próprio utilizador. | Parcial |
| RF-M02-05 / P1 (v0.2) | Criar notificações e registos de atividade pessoais apenas por processos internos autorizados. | Um utilizador não cria notificação nem atividade em nome de outra conta, sobretudo de outra organização; a criação não é exposta como ação comum de perfil. | Bloqueado — N-01 |
| RF-M02-06 / P2 (v0.2) | Gerir definições pessoais e consultar o registo de segurança da conta. | Definições e eventos de segurança pertencem ao próprio utilizador; administrador só consulta com permissão e finalidade. | Parcial |

Regras: criação de identidade e atribuição de cargos pertencem a Auth. Notificações transacionais são geradas por M30 ou por serviços internos, não por pedido HTTP de perfil. Decisões pendentes: campos editáveis, formatos/tamanho de avatar, retenção de atividade e se o avatar é público entre colegas da mesma organização.

## 4. M03 — Empresas

Origem: empresas. Objetivo: manter dados institucionais e estrutura organizacional. Intervenientes: administrador da organização e direção. Dependências: auth, configuração e armazenamento.

Evidência: 25 rotas (`/api/companies`); 5 ficheiros Go, 1 de teste (`cross_tenant_test.go`). Permissões: `empresa.ver_empresa`, `empresa.editar_empresa`, `empresa.gerir_filiais`, `empresa.gerir_licencas`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M03-01 / P1 | Consultar e atualizar identificação, contactos e dados institucionais. | Campos obrigatórios e identificação aprovados são validados; só o perfil autorizado altera dados. | Parcial |
| RF-M03-02 / P1 | Gerir filiais e unidades vinculadas à organização. | Uma unidade pertence à organização correta e é selecionável apenas nos processos autorizados. | Parcial |
| RF-M03-03 / P2 | Gerir licenças e documentação institucional. | Documento ou licença é associado à empresa correta e consultado apenas por perfis permitidos. | Parcial |
| RF-M03-04 / P1 | Impedir exclusão que quebre referências operacionais. | Uma empresa/unidade em uso é preservada ou desativada segundo a política, sem perder histórico. | Parcial — não há rota de exclusão; desativação a especificar |
| RF-M03-05 / P1 (v0.2) | Gerir informação fiscal, contas bancárias, contactos, endereços e definições da empresa. | Dados fiscais e bancários usados em documentos correspondem à empresa emitente; alteração é auditada. | Parcial |
| RF-M03-06 / P1 (v0.2) | Associar e remover utilizadores da empresa. | A associação é coerente com a membership em M01; remover o utilizador da empresa retira o acesso correspondente. | Parcial — relação com memberships a definir |

Decisões pendentes: estrutura de filiais, campos legais obrigatórios, ciclo de desativação e diferença entre "utilizador da empresa" e membership. O cadastro de tenant da plataforma pertence a Superadmin.

## 5. M04 — Administração global

Origem: superadmin. Objetivo: administrar a plataforma e as organizações clientes. Intervenientes: administração global autorizada. Dependências: auth, segurança, assinaturas e configuração.

Evidência: 36 rotas (`/api/superadmin`, excluindo as 2 de monitorização); 11 ficheiros Go, 0 de teste no módulo (o middleware `superadmin_security.go` tem testes). Proteção por `RequireSuperadmin`, allowlist de IP e reautenticação nos grupos sensíveis; allowlist vazia permite acesso por decisão do código.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M04-01 / P1 | Criar, atualizar, suspender, inativar e reativar organizações. | O estado da organização é aplicado ao acesso conforme política, preservando dados e histórico. | Parcial — aplicação da suspensão no middleware por testar |
| RF-M04-02 / P1 | Gerir catálogo de módulos, planos, funcionalidades e dependências. | Uma alteração não deixa módulos obrigatoriamente dependentes numa combinação inválida. | Parcial |
| RF-M04-03 / P1 | Controlar operações privilegiadas por reautenticação e origem autorizada. | Utilizador comum, prova desatualizada ou origem não permitida não executa a operação. | Risco — AI-07; allowlist vazia permite |
| RF-M04-04 / P1 | Consultar indicadores globais e executar provisionamento com auditoria. | Cada ação identifica a organização alvo e deixa evidência; acessos de suporte têm finalidade autorizada. | Parcial |
| RF-M04-05 / P1 (v0.2) | Ativar, desativar e repor funcionalidades (feature flags) por organização. | A funcionalidade desativada é recusada por `RequireFeature` em todas as rotas que a usam; repor volta ao valor do plano. | Parcial |
| RF-M04-06 / P2 (v0.2) | Provisionar cargos padrão e o primeiro colaborador de uma organização. | Reexecutar o provisionamento não duplica cargos; o número de colaborador segue a sequência da organização. | Parcial |
| RF-M04-07 / P1 (v0.2) | Gerir configurações globais da plataforma e consultar utilizadores globais. | Só a administração global altera; cada alteração identifica valor anterior, novo valor e ator. | Parcial |

Regras: acesso global não elimina finalidade e auditoria. Exclusão de tenant (`DELETE /superadmin/tenants/{id}` existe) exige procedimento aprovado e análise de retenção antes de ser disponibilizada em produção. Decisões pendentes: privilégios, comportamento com allowlist vazia e política de suspensão/eliminação.

## 6. M05 — Configuração do sistema

Origem: sistema-configuracao. Objetivo: parametrizar o funcionamento de cada organização. Intervenientes: administrador e responsáveis funcionais. Dependências: empresas, auth e módulos afetados.

Evidência: 26 rotas (`/api/system`); 4 ficheiros Go, 0 de teste. Permissões: `sistema-configuracao.ver_configuracoes`, `editar_configuracoes`, `gerir_templates`. Expõe também `/system/currencies` e `/system/exchange-rates`, sobrepostos a M21.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M05-01 / P1 | Gerir parâmetros, branding e definições de documentos. | A configuração válida aplica-se apenas à organização e ao documento/processo indicado. | Parcial |
| RF-M05-02 / P1 | Configurar métodos e políticas de assiduidade. | Métodos desativados não podem ser usados; parâmetros inválidos são rejeitados antes da gravação. | Parcial |
| RF-M05-03 / P2 | Manter catálogos de países, cidades, idiomas e referências de moeda. | Relações são consistentes; alterações respeitam o âmbito global ou organizacional definido. | Parcial — sobreposição com M21 |
| RF-M05-04 / P1 | Gerir integrações, templates de email/SMS e consultar logs técnicos e de API autorizados. | Dados sensíveis permanecem protegidos; configuração incorreta produz erro claro e não ativa integração inválida. | Parcial |

Regras: separar catálogo global de parâmetros de tenant; definir qual cadastro de moeda e câmbio é a fonte de verdade (M05 ou M21) e retirar o outro. Decisões pendentes: propriedade de cada parâmetro, níveis de alteração e propagação/cache nos consumidores.

## 7. M06 — Segurança

Origem: seguranca. Objetivo: manter políticas e controlos adicionais de proteção. Intervenientes: responsável de segurança e administrador. Dependências: auth, auditoria e assinatura digital.

Evidência: 7 rotas (`/api/seguranca`); 3 ficheiros Go, 0 de teste. Permissões: `seguranca.ver_seguranca`, `gerir_politicas`, `gerir_allowlist`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M06-01 / P1 | Gerir políticas de segurança aplicáveis à organização. | A política tem identificação, vigência e histórico; utilizador sem permissão não a altera. | Parcial |
| RF-M06-02 / P1 | Consultar estado de inscrição MFA de forma autorizada. | O gestor conhece o estado necessário sem receber o segredo do fator. | Parcial — consulta não prova obrigatoriedade no login |
| RF-M06-03 / P1 | Gerir listas de IPs/origens autorizadas. | Inclusão/remoção produz o efeito previsto e não aceita headers não confiáveis como prova de origem. | Risco — AI-07 |
| RF-M06-04 / P2 | Encaminhar políticas para assinatura quando exigido. | A evidência corresponde à versão da política aprovada e ao signatário correto. | Parcial |

Decisões pendentes: obrigatoriedade de MFA, política de origens, proxies confiáveis e responsáveis por aceitação das políticas.

## 8. M07 — Auditoria

Origem: auditoria. Objetivo: permitir investigação e comprovação das operações. Intervenientes: auditor, direção e responsável autorizado. Dependências: todos os módulos e assinatura digital.

Evidência: 9 rotas (`/api/audit-logs`, `/api/audit-events`, `/api/hardware/audit-logs`); 4 ficheiros Go, 0 de teste. Permissões: `auditoria.ver_logs`, `auditoria.gerir_logs`. O middleware `AuditModule` regista pedidos por módulo; eventos protegidos têm verificação de integridade.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M07-01 / P1 | Registar e consultar logs/eventos de operações críticas. | Ator, organização, instante, ação e referência permitem reconstruir o caso homologado. | Risco — auditoria pós-commit com resultado ignorado em vários processos |
| RF-M07-02 / P1 | Filtrar e obter detalhes dos registos autorizados. | Filtros devolvem resultados coerentes e não expõem eventos de outra organização. | Parcial |
| RF-M07-03 / P1 | Verificar integridade dos eventos protegidos. | Alteração indevida de evidência protegida é detetada no cenário de homologação. | Parcial |
| RF-M07-04 / P2 | Exportar resultados e enviar documentação de auditoria para assinatura. | Exportação respeita filtros/permissões e não inclui segredos; assinatura liga-se ao documento exportado. | Parcial |

Decisões pendentes: lista de ações críticas, operações que devem falhar quando a auditoria obrigatória não grava, retenção, acesso e formato de evidência. Logs operacionais e eventos protegidos não são equivalentes; integridade dos eventos existentes não prova completude dos esperados.

## 9. M08 — Monitorização

Origem: monitoring. Objetivo: dar visibilidade ao estado das integrações monitorizadas. Intervenientes: operação e suporte autorizado. Dependências: FaceClock, configuração e infraestrutura.

Evidência: 2 rotas (`/api/superadmin/faceclock/metrics|audit-logs`), proxy HMAC para o FaceClock; 1 ficheiro Go, 0 de teste. Sem permissão RBAC própria: acesso pelo grupo superadmin. `/health` devolve estado estático (AI-12).

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M08-01 / P1 | Consultar o estado das integrações biométricas monitorizadas. | O estado apresentado corresponde à resposta recente da dependência, com instante de consulta. | Parcial |
| RF-M08-02 / P1 | Distinguir indisponibilidade de ausência de configuração. | Timeout, erro e integração não configurada produzem estados distintos e compreensíveis. | Parcial |
| RF-M08-03 / P1 | Restringir diagnósticos a perfis operacionais autorizados. | Utilizador comum não recebe informação sensível de infraestrutura ou credenciais. | Parcial |
| RF-M08-04 / P2 | Definir alertas e prontidão para dependências essenciais. | Falha simulada gera aviso e indica o processo afetado; objetivo e destinatário são previamente aprovados. | Proposta |
| RF-M08-05 / P1 (v0.2) | Separar verificação de vida (liveness) de prontidão (readiness) da API e do worker. | Readiness falha quando PostgreSQL, armazenamento ou dependência obrigatória não respondem dentro do prazo; liveness não depende delas. | Proposta — AI-12 |

Decisões pendentes: periodicidade, dependências essenciais, contactos de incidente e se a monitorização deve deixar de estar restrita ao superadmin.

## 10. M09 — Gestão de clientes

Origem: gestao-clientes. Objetivo: manter cadastro comercial e condições dos clientes. Intervenientes: comercial, financeiro e administrador. Dependências: pessoas, CRM e faturação.

Evidência: 41 rotas (`/api/clientes`); 4 ficheiros Go, 0 de teste. Permissões: `clientes.ver_clientes`, `gerir_clientes`, `eliminar_clientes`, `gerir_credito`, `gerir_grupos`. O router usa os handlers "Seguro" de `clientes_api_ext.go`; métodos antigos em `cliente_data.go` não servem rotas mas devem ser removidos.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M09-01 / P1 | Criar, consultar, atualizar e desativar clientes. | Cadastro validado fica na organização correta; desativação preserva documentos anteriores. | Parcial |
| RF-M09-02 / P1 | Gerir grupos, contactos, endereços e informação complementar. | Cliente recebe as classificações corretas sem duplicação indevida de relações. | Parcial |
| RF-M09-03 / P1 | Gerir condições e limites de crédito autorizados. | Valor e vigência são rastreáveis; utilização em venda respeita a política aprovada. | Parcial |
| RF-M09-04 / P2 | Disponibilizar dados comerciais por interfaces autorizadas. | Dados e histórico devolvidos correspondem ao cliente autorizado e não expõem documentos externos. | Parcial |
| RF-M09-05 / P1 (v0.2) | Bloquear, desbloquear e reativar clientes, consultar saldo e registar pagamentos do cliente. | Cliente bloqueado não é usado em novas vendas a crédito; pagamento atualiza o saldo uma única vez e liga-se ao documento quando indicado. | Parcial |
| RF-M09-06 / P2 (v0.2) | Gerir descontos, etiquetas, notas e documentos do cliente. | Desconto tem vigência e é aplicado apenas ao cliente correto; documentos são acessíveis só a perfis autorizados. | Parcial |
| RF-M09-07 / P2 (v0.2) | Produzir relatórios de top clientes, saldos devedores, crédito utilizado e clientes sem atividade. | Valores conciliam com documentos e pagamentos do período e não incluem outra organização. | Parcial |

Decisões pendentes: identificadores únicos (a baseline usa `UNIQUE NULLS NOT DISTINCT` em NUIT/código, o que impede dois clientes sem NUIT — confirmar se é intencional), condições de crédito, obrigatoriedade de contactos e relação cliente/pessoa.

## 11. M10 — CRM

Origem: crm. Objetivo: acompanhar aquisição de clientes e oportunidades comerciais. Intervenientes: comercial e gestor de vendas. Dependências: clientes, utilizadores e tarefas/notificações quando aplicáveis.

Evidência: 20 rotas (`/api/crm`); 4 ficheiros Go, 0 de teste. Permissões: `crm.ver_leads`, `gerir_leads`, `eliminar_leads`, `mover_leads`, `converter_leads`, `ver_oportunidades`, `gerir_oportunidades`, `eliminar_oportunidades`, `ver_atividades`, `gerir_atividades`. Funcionalidades `crm.leads`, `crm.oportunidades`, `crm.atividades`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M10-01 / P1 | Gerir leads e responsáveis comerciais. | Lead tem dados mínimos, responsável e estado; apenas perfis autorizados o consultam/alteram. | Parcial — validar responsável no tenant |
| RF-M10-02 / P1 | Acompanhar oportunidades por etapas aprovadas. | Mudança de etapa conserva referência e histórico e respeita transições acordadas. | Parcial |
| RF-M10-03 / P1 | Registar atividades e seguimento comercial. | Atividade fica associada ao lead/oportunidade correto e apresenta data e interveniente. | Parcial |
| RF-M10-04 / P2 | Converter leads e encaminhar resultados comerciais para cadastro/processos seguintes. | Não são criados clientes ou relações duplicadas no cenário aprovado de encaminhamento. | Parcial — processo de conversão por confirmar |

Decisões pendentes: etapas do funil, critérios de ganho/perda e regras de encaminhamento. Automação entre etapas deve ser homologada.

## 12. M11 — Produtos

Origem: gestao-produtos. Objetivo: definir os artigos comercializados e controlados. Intervenientes: gestor de catálogo e operação. Dependências: stock, impostos e faturação/POS.

Evidência: 53 rotas (`/api/produtos`); 3 ficheiros Go, 0 de teste. Permissões: usa os códigos do módulo `stock` (`stock.gerir_produtos`, `gerir_categorias`, `eliminar_produtos`, `ver_stock`) — ver N-06.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M11-01 / P1 | Gerir produtos com códigos, descrição, unidades e estado. | Código segue a unicidade aprovada; artigo inativo não é usado em novas operações proibidas. | Parcial |
| RF-M11-02 / P1 | Gerir categorias, marcas, variantes e atributos suportados. | Variante pertence ao produto correto e distingue os artigos nos processos de venda e stock. | Bloqueado — AP-08 (marcas) |
| RF-M11-03 / P1 | Definir preços e referências tributárias aplicáveis. | Venda usa o preço/regra autorizados, mantendo os valores do documento emitido. | Parcial |
| RF-M11-04 / P2 | Disponibilizar catálogo complementar, etiquetas e anexos autorizados. | Dados publicados e ficheiros correspondem ao artigo selecionado e ao âmbito de acesso aprovado. | Parcial |
| RF-M11-05 / P2 (v0.2) | Produzir relatórios de catálogo e desempenho de produtos. | Relatório concilia com documentos de venda/stock do período e da organização. | Parcial |

Regras: erros de Query/Scan não podem resultar em lista vazia ou sucesso aparente (RT-08). Decisões pendentes: unidades, identificadores, variantes, preços por canal, categorias tributárias e se o catálogo deve ter permissões próprias separadas de stock.

## 13. M12 — Stock

Origem: gestao-stock. Objetivo: controlar existências e movimentos de materiais. Intervenientes: armazém, compras e operação. Dependências: produtos, empresas, compras e vendas.

Evidência: 56 rotas (`/api/stock`); 3 ficheiros Go, 0 de teste. Permissões: códigos `stock.*`; funcionalidade `stock`. `stock_ext.go` valida produto/armazém/variante do tenant com `INSERT … SELECT`; a baseline protege posições com variantes nulas. O job diário `checkStockAlerts` gera alertas.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M12-01 / P1 | Gerir armazéns e localizações e consultar existências por artigo/variante. | Quantidade apresentada corresponde aos movimentos aceites do armazém autorizado. | Parcial |
| RF-M12-02 / P1 | Registar entradas, saídas e ajustes com referência e motivo. | O movimento atualiza a existência uma única vez e conserva origem, ator e motivo aplicáveis. | Risco — AP-04 (entradas via Compras) |
| RF-M12-03 / P1 | Executar transferências entre armazéns autorizados (criar, confirmar, receber, cancelar). | Saída e entrada são coerentes; falha não deixa apenas metade da transferência persistida. | Parcial |
| RF-M12-04 / P1 | Controlar inventários e divergências. | Contagem aprovada produz ajuste rastreável e respeita a política de stock negativo. | Parcial |
| RF-M12-05 / P2 | Alertar reposição e apresentar análise de movimentos. | Artigos no limiar acordado são identificados sem misturar organizações ou unidades; alerta pode ser resolvido ou ignorado com registo. | Parcial — alerta gerado não prova envio de notificação |
| RF-M12-06 / P1 (v0.2) | Reservar, libertar e consumir stock para documentos de venda. | Reserva reduz o disponível sem reduzir o físico; consumir e libertar são mutuamente exclusivos e não excedem a quantidade reservada. | Parcial |
| RF-M12-07 / P1 (v0.2) | Rastrear lotes com validade e números de série com estado. | Lote/série pertence ao artigo e armazém corretos; lotes a expirar são listados segundo o prazo aprovado. | Parcial |
| RF-M12-08 / P2 (v0.2) | Valorizar o stock por armazém e período. | Valor reproduz o método de valorização aprovado nos casos homologados. | Parcial — método por definir |

Decisões pendentes: stock negativo, método de valorização, mínimos, aprovação de ajuste e obrigatoriedade de lote/série por categoria.

## 14. M13 — Compras

Origem: compras. Objetivo: controlar abastecimento e obrigações com fornecedores. Intervenientes: requisitante, aprovador, compras, armazém e financeiro. Dependências: produtos, stock, aprovações, contabilidade e tesouraria.

Evidência: 19 rotas (`/api/compras`); 5 ficheiros Go, 1 de teste. Permissões: `compras.ver_compras`, `criar_pedidos`, `aprovar_pedidos`, `receber_mercadoria`, `faturar_compras`, `gerir_pagamentos`, `gerir_devolucoes`. Funcionalidades `compras`, `compras.aprovacoes`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M13-01 / P1 | Criar requisições e ordens de compra com itens e referências. | Dados obrigatórios e relações são válidos; itens externos à organização são rejeitados. | Risco — AP-18, AP-19 |
| RF-M13-02 / P1 | Aplicar aprovação quando exigida e associar evidência de assinatura. | Ordem sujeita a decisão não avança sem autorização; assinatura refere a versão correta. | Bloqueado — AP-19 (estado aceite do JSON) |
| RF-M13-03 / P1 | Registar receções totais/parciais e divergências. | Quantidade aceite atualiza o stock correto; excedentes seguem a tolerância aprovada. | Bloqueado — AP-04 |
| RF-M13-04 / P1 | Registar faturas e pagamentos associados à compra. | Documento, obrigação e pagamento conciliam sem duplicar efeitos nos módulos integrados. | Bloqueado — AP-03, AP-04, AP-17 |
| RF-M13-05 / P1 | Executar devoluções de compra. | Quantidade devolvida não excede a elegível e os efeitos de stock/financeiros ficam associados à origem. | Risco — AP-04 |
| RF-M13-06 / P1 (v0.2) | Separar a edição de linhas da fatura de fornecedor da sua emissão. | Fatura em rascunho aceita várias linhas; a emissão valida o documento completo, fecha totais e só então aplica efeitos; após emissão novas linhas são rejeitadas. | Bloqueado — AP-03 |

Decisões pendentes: fornecedores, tolerâncias, limites de aprovação, receções parciais e tratamento de adiantamentos.

## 15. M14 — Logística

Origem: logistica. Objetivo: acompanhar recursos e execução de entregas. Intervenientes: gestor logístico, motorista e operação. Dependências: empresas, clientes e referências de envio.

Evidência: 11 rotas (`/api/delivery-drivers|vehicles|routes|tracking|logs`, `/api/shipments`); 2 ficheiros Go, 0 de teste. Permissões: `logistica.ver_logistica`, `gerir_entregas`; funcionalidade `logistica`. `CriarEnvio` valida as referências pelo tenant.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M14-01 / P1 | Registar motoristas e viaturas da organização. | Os recursos são identificados e selecionados apenas no âmbito autorizado. | Parcial |
| RF-M14-02 / P1 | Gerir rotas e envios com origem, destino e referência. | Um envio válido está associado aos recursos e referências corretos. | Parcial |
| RF-M14-03 / P1 | Registar tracking e ocorrências de entrega por códigos de evento fechados. | Eventos apresentam sequência temporal e identificação do envio sem alterar outros envios; o estado segue a matriz de transições, não o texto livre. | Bloqueado — AP-16 |
| RF-M14-04 / P2 | Consultar estado e logs de entrega. | O gestor identifica entregas pendentes/concluídas segundo os estados homologados. | Bloqueado — AP-16 |

Decisões pendentes: estados de envio, prova de entrega e responsabilidade dos recursos. Manutenção de frota e localização contínua não estão incluídas.

## 16. M15 — Faturação

Origem: modulo-faturacao. Objetivo: emitir documentos comerciais rastreáveis. Intervenientes: comercial, financeiro e administrador. Dependências: clientes, produtos, impostos, moedas, contabilidade e assinatura digital.

Evidência: 38 rotas (`/api/faturacao`: orçamentos, encomendas, faturas, recibos, notas de crédito, séries); 8 ficheiros Go, 2 de teste (isolamento entre tenants). Permissões: `faturacao.ver_documentos`, `emitir_orcamentos`, `emitir_encomendas`, `emitir_faturas`, `emitir_notas_credito`, `cancelar_documentos`, `configurar_series`. Funcionalidades `vendas.orcamentos`, `vendas.encomendas`, `vendas.fatura_direta`, `vendas.devolucoes`. Numeração com bloqueio da série; a fatura fiscal separa adição de linhas (rascunho, `FOR UPDATE`) de emissão.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M15-01 / P1 | Gerir documentos e respetivas linhas segundo tipos habilitados. | Cliente, moeda, artigo, quantidade, preço, desconto e imposto respeitam as regras do documento. | Parcial |
| RF-M15-02 / P1 | Aplicar numeração por série e apurar totais de forma consistente. | Casos aprovados reproduzem os totais e não geram numeração duplicada sob concorrência. | Parcial |
| RF-M15-03 / P1 | Confirmar e cancelar documentos com controlo de estado. | Estado inválido impede a ação; cancelamento preserva referência e não elimina histórico. | Parcial |
| RF-M15-04 / P1 | Produzir PDF e disponibilizar consulta/descarga autorizada. | Documento apresentado corresponde aos dados persistidos e não é acessível a outra organização. | Parcial |
| RF-M15-05 / P1 | Integrar efeitos contabilísticos e de cobrança configurados. | A operação gera apenas os efeitos obrigatórios e não confirma sucesso parcial. | Parcial — padrão AP-17 a verificar no adaptador de faturação |
| RF-M15-06 / P2 | Encaminhar documentos para assinatura quando aplicável. | A versão assinada é identificável e não é alterada silenciosamente depois da assinatura. | Parcial |
| RF-M15-07 / P1 (v0.2) | Gerir orçamentos: criar, editar linhas, enviar, aprovar e rejeitar. | Só orçamento em estado editável aceita linhas; aprovação/rejeição são finais e registadas. | Parcial |
| RF-M15-08 / P1 (v0.2) | Gerir encomendas de cliente: criar, confirmar e cancelar. | Encomenda confirmada pode originar fatura/reserva segundo regra aprovada; cancelada não. | Parcial |
| RF-M15-09 / P1 (v0.2) | Emitir notas de crédito ligadas à fatura de origem, com linhas, PDF, email e cancelamento. | Total creditado não excede o elegível da fatura; a nota referencia a origem e atualiza o saldo. | Parcial |
| RF-M15-10 / P1 (v0.2) | Registar recibos limitados ao saldo em aberto de faturas emitidas. | Recibo é rejeitado para fatura em rascunho/cancelada, para valor acima do saldo ou método de pagamento de outra organização; o estado da fatura passa a parcialmente paga/paga; reenvio não duplica. | Bloqueado — N-02 |
| RF-M15-11 / P1 (v0.2) | Configurar, ativar e desativar séries documentais por tipo. | Emissão sem série ativa é recusada com mensagem clara; desativar não altera documentos emitidos. | Parcial |
| RF-M15-12 / P2 (v0.2) | Enviar faturas e notas de crédito por email. | O envio usa M30, fica registado e não altera o documento; falha do fornecedor é visível. | Parcial |

Decisões pendentes: tipos documentais, séries, regras de emissão, cancelamento, efeitos de stock e regras de recibo (adiantamentos, pagamentos em excesso). Validação fiscal compete ao responsável financeiro.

## 17. M16 — POS

Origem: pos. Objetivo: executar vendas e caixa com controlo do operador. Intervenientes: operador, supervisor e financeiro. Dependências: auth, produtos, stock, faturação, pagamentos e auditoria.

Evidência: 51 rotas (`/api/pos`, `/api/v1/transactions`); 13 ficheiros Go, 1 de teste. Permissões: `pos.operar_pos`, `registar_venda`, `abrir_sessao`, `movimentar_caixa`, `supervisionar_pos`, `gerir_terminais`, `gerir_catalogo`, `gerir_descontos`, `configurar`, `relatorios`; a API PayCore usa `faturacao.ver_documentos` e `faturacao.cancelar_documentos`. Venda, fatura e estorno parcial na mesma transação, com `FOR UPDATE` em venda/itens e idempotência por `client_reference`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M16-01 / P1 | Identificar terminal e operador e controlar abertura de caixa. | Venda exige contexto válido; abertura respeita as restrições acordadas de caixa/terminal. | Parcial |
| RF-M16-02 / P1 | Criar vendas com artigos, descontos, impostos e referência do cliente. | Totais conciliam; artigo/stock/contexto inválido não produz venda parcial. | Parcial — valores em `float64` (RNF-05) |
| RF-M16-03 / P1 | Iniciar e consultar pagamentos móveis e receber confirmação autenticada. | Origem inválida não confirma pagamento; repetição e eventos tardios não duplicam nem fazem regredir estado final. | Bloqueado — AI-02, AI-10 |
| RF-M16-04 / P1 | Aplicar autorização de supervisor a ações restritas. | Operador sem autorização não executa desconto/estorno protegido. | Parcial |
| RF-M16-05 / P1 | Executar cancelamentos e estornos totais/parciais. | Valores e quantidades respeitam o limite elegível e atualizam corretamente as referências associadas. | Parcial |
| RF-M16-06 / P1 | Emitir recibos e fechar caixa com apuramento. | O fecho apresenta meios de pagamento, valores esperados, declarados e diferenças homologadas. | Parcial |
| RF-M16-07 / P1 (v0.2) | Registar movimentos de caixa que não são vendas (reforço, sangria) na sessão aberta. | Movimento exige sessão aberta, motivo e operador; entra no valor esperado do fecho. | Parcial |
| RF-M16-08 / P1 (v0.2) | Gerir catálogo do POS, descontos e configuração por organização. | Só artigos do catálogo ativo são vendáveis no terminal; desconto respeita vigência e limite de supervisor. | Parcial |
| RF-M16-09 / P1 (v0.2) | Sincronizar dados para operação offline e aceitar vendas reenviadas com idempotência. | Download só contém dados da organização e terminal; venda reenviada com o mesmo `client_reference` devolve a original sem duplicar. | Parcial |
| RF-M16-10 / P1 (v0.2) | Validar licença da aplicação POS e autenticar terminal e operador (login, PIN, refresh). | Licença inválida ou expirada impede a operação; PIN de operador sujeito a RF-M01-07. | Risco — AI-08 |
| RF-M16-11 / P2 (v0.2) | Produzir relatórios de vendas, top produtos, cancelamentos, fecho de caixa e terminais. | Valores conciliam com vendas, estornos e sessões do período. | Parcial |
| RF-M16-12 / P2 (v0.2) | Expor à aplicação PayCore consulta, cancelamento e estorno de transações (`/api/v1/transactions`). | Cancelamento/estorno seguem as mesmas regras de limite e autorização de RF-M16-05. | Parcial |

Decisões pendentes: modos de operação, limites de supervisor, divergências de caixa, meios de pagamento e se a API PayCore deve ter permissões próprias. Licença da aplicação deve respeitar a oferta aprovada.

## 18. M17 — Financeiro

Origem: financeiro. Objetivo: acompanhar obrigações e fluxo de caixa. Intervenientes: financeiro e direção. Dependências: clientes, compras, faturação e tesouraria.

Evidência: 11 rotas (`/api/financeiro`); 2 ficheiros Go, 0 de teste. Permissões: `financeiro.ver_financeiro`, `gerir_categorias`, `gerir_contas_receber`, `gerir_contas_pagar`. Consultas com `jsonb_agg` sem paginação.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M17-01 / P1 | Gerir categorias financeiras e métodos de pagamento. | Categoria/método válido é usado nas obrigações da organização e não cria relação externa inválida. | Parcial |
| RF-M17-02 / P1 | Registar e consultar contas a receber e a pagar. | Valor, contraparte, referência, vencimento e saldo são coerentes com a obrigação. | Parcial; Bloqueado na integração escolar — AP-10 |
| RF-M17-03 / P1 | Registar liquidações totais/parciais. | Pagamento atualiza apenas a obrigação correta e não excede o permitido sem procedimento aprovado. | Bloqueado — AP-02 |
| RF-M17-04 / P2 | Consultar fluxo de caixa e vencimentos. | Os valores do período conciliam com as operações incluídas e distinguem previsão de realização. | Parcial — origem de `cash_flow_entries` por confirmar |

Decisões pendentes: integração entre obrigação e movimento bancário, pagamentos em excesso, critérios de projeção e paginação das consultas.

## 19. M18 — Tesouraria

Origem: tesouraria. Objetivo: gerir saldos, movimentos e reconciliação. Intervenientes: tesoureiro e responsável financeiro. Dependências: financeiro, pagamentos, contabilidade e assinatura digital.

Evidência: 10 rotas (`/api/tesouraria`); 3 ficheiros Go, 0 de teste. Permissões: `tesouraria.ver_tesouraria`, `gerir_contas`, `gerir_movimentos`, `gerir_reconciliacao`. `CriarMovimento` atualiza saldo na mesma transação e exige `RowsAffected==1`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M18-01 / P1 | Gerir contas bancárias e caixas com moeda e saldo inicial. | Conta/caixa fica no tenant correto e os dados obrigatórios são validados. | Parcial |
| RF-M18-02 / P1 | Registar recebimentos e pagamentos associados a origem ativa. | Movimento e saldo são persistidos conjuntamente; origem inativa ou externa é rejeitada. | Parcial — AP-17 e N-04 afetam movimentos vindos de outros módulos |
| RF-M18-03 / P1 | Criar, consultar e fechar reconciliações por período. | Diferença entre extrato e sistema corresponde aos movimentos e saldo inicial homologados. | Parcial |
| RF-M18-04 / P2 | Associar evidência e assinatura à reconciliação. | O documento assinado corresponde ao período e aos valores aprovados no fecho. | Parcial |

Decisões pendentes: saldos negativos, períodos de fecho, importação de extratos, movimentos retroativos e autorização para reabertura/correção.

## 20. M19 — Contabilidade

Origem: contabilidade. Objetivo: organizar registos contabilísticos e fecho. Intervenientes: contabilista e responsável financeiro. Dependências: faturação, compras, tesouraria, impostos, centros de custo e assinatura digital.

Evidência: 71 rotas (`/api/contabilidade`); 16 ficheiros Go, 0 de teste. Permissões: `contabilidade.ver_contabilidade`, `gerir_plano_contas`, `gerir_lancamentos`, `estornar_lancamentos`, `gerir_periodos`, `fechar_periodo`, `reabrir_periodo`, `fechar_ano_fiscal`, `gerir_ativos_fixos`, `gerir_orcamentos`, `ver_relatorios`; funcionalidade `contabilidade`. `journal_entries.go` valida débito XOR crédito, equilíbrio e contas do tenant e bloqueia a sequência. Inclui `taxes`, `tax-groups` e `tax-transactions`, sobrepostos a M20.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M19-01 / P1 | Gerir plano de contas, tipos, diários e configurações contabilísticas. | Contas válidas são usadas conforme o plano aprovado; referências em uso não são quebradas. | Parcial |
| RF-M19-02 / P1 | Criar e consultar lançamentos com origem e linhas. | Débitos e créditos equilibram segundo precisão acordada; documento de origem é rastreável. | Parcial |
| RF-M19-03 / P1 | Gerir anos e períodos fiscais e respetivos estados. | Período fechado impede registo não autorizado; reabertura exige permissão e evidência. | Parcial |
| RF-M19-04 / P1 | Integrar operações de outros módulos sem duplicar lançamentos. | Repetir o evento não gera segundo lançamento; erro não deixa lançamento incompleto. | Risco — AP-17, N-04 |
| RF-M19-05 / P2 | Gerir ativos e processar amortizações segundo política aprovada. | Cálculos homologados reproduzem montantes, períodos e referências, incluindo cancelamento autorizado. | Parcial |
| RF-M19-06 / P1 | Produzir balancete, balanço, demonstração de resultados, razão geral e outros relatórios suportados. | Relatório concilia com lançamentos válidos do período e exclui dados de outra organização. | Parcial |
| RF-M19-07 / P1 (v0.2) | Estornar lançamentos publicados por lançamento inverso. | O original não é alterado; o estorno referencia-o, exige permissão e motivo, e só é possível uma vez. | Parcial |
| RF-M19-08 / P2 (v0.2) | Gerir orçamentos contabilísticos e consultar execução orçamental. | Execução concilia com lançamentos do período; regra de convivência com M22 está definida. | Parcial — sobreposição com M22 |

Decisões pendentes: plano de contas, relatórios exigidos, métodos de amortização, procedimentos de fecho e qual módulo é dono de impostos e orçamentos. A aceitação dos exemplos contabilísticos pertence ao especialista funcional.

## 21. M20 — Impostos

Origem: impostos. Objetivo: manter configurações, retenções e documentação tributária. Intervenientes: responsável fiscal e financeiro. Dependências: empresas, faturação, compras, contabilidade e armazenamento.

Evidência: 18 rotas (`/api/impostos`); 3 ficheiros Go, 0 de teste. Permissões: `impostos.ver_impostos`, `gerir_impostos`. A baseline tem triggers de imutabilidade em declarações e linhas.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M20-01 / P1 | Gerir regimes e isenções com âmbito e vigência. | A regra válida é aplicada ao caso correto; regra expirada não se aplica indevidamente. | Parcial — entidade da isenção (cliente/fornecedor/produto/categoria) não validada no tenant |
| RF-M20-02 / P1 | Registar retenções e consultar transações relacionadas. | Montante e referência conciliam com a operação e exemplos aprovados. | Parcial |
| RF-M20-03 / P1 | Preparar e registar estado de declarações tributárias. | Linhas e totais correspondem ao período; alteração de estado respeita a autorização. | Parcial |
| RF-M20-04 / P2 | Guardar e consultar certificados e anexos. | Documento fica associado à entidade correta e acessível apenas ao perfil permitido. | Parcial |

Regras: registar uma declaração como submetida não prova transmissão eletrónica à autoridade fiscal. Decisões pendentes: taxas, formulários, certificados, eventual integração oficial e fronteira com os impostos de M19.

## 22. M21 — Multi-moeda

Origem: multi-moeda. Objetivo: controlar moedas habilitadas e conversões. Intervenientes: financeiro e administrador. Dependências: configuração, faturação, compras e tesouraria.

Evidência: 8 rotas (`/api/multi-moeda`); 2 ficheiros Go, 0 de teste. Permissões: `multi-moeda.ver_moedas`, `gerir_moedas`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M21-01 / P1 | Manter catálogo de moedas e moedas habilitadas por organização, com exatamente uma moeda base. | Moeda não habilitada não é usada nos processos que exigem habilitação; a troca de base é atómica. | Bloqueado — AP-15 |
| RF-M21-02 / P1 | Registar taxas de câmbio com referência temporal. | Conversão utiliza a taxa vigente na data acordada; taxa futura não é usada; ausência de taxa não gera valor inventado. | Bloqueado — AP-14 |
| RF-M21-03 / P1 | Converter montantes com precisão e arredondamento aprovados. | Casos de moeda de origem/destino reproduzem os valores homologados, incluindo moedas sem casas decimais. | Bloqueado — AP-14; zero decimais tratado como omisso |
| RF-M21-04 / P1 | Preservar a referência de conversão dos documentos emitidos. | Nova taxa não altera silenciosamente os montantes históricos de um documento confirmado. | Parcial — verificar nos consumidores |

Decisões pendentes: moeda base, origem das taxas, precisão, autorização para atualização histórica e retirada do cadastro duplicado em M05.

## 23. M22 — Centros de custo

Origem: centros-custo. Objetivo: atribuir custos e acompanhar orçamento. Intervenientes: financeiro e responsáveis de área. Dependências: contabilidade e operações que aceitam alocação.

Evidência: 13 rotas (`/api/centros-custo`); 4 ficheiros Go, 0 de teste. Permissões: `centros-custo.ver_centros`, `gerir_centros`, `eliminar_centros`; funcionalidade `cont.centros_custo`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M22-01 / P1 | Gerir centros de custo com código, hierarquia, gestor e estado. | Código segue a unicidade aprovada; pai e gestor pertencem à organização; desativação preserva alocações anteriores. | Parcial — `parent_id`/`gestor_user_id` não validados |
| RF-M22-02 / P1 | Registar alocações a centros autorizados. | Alocação referencia a origem correta e a soma das proporções da mesma origem não excede 100%. | Bloqueado — AP-13 |
| RF-M22-03 / P2 | Gerir orçamentos por centro e período. | Valores guardados correspondem ao período aprovado e não se sobrepõem indevidamente. | Bloqueado — AP-13 |
| RF-M22-04 / P2 | Comparar orçado e realizado. | Realizado concilia com as alocações incluídas, explicita a data económica e a moeda e permite explicar a diferença. | Parcial |

Decisões pendentes: dimensões por obra/unidade, bases de rateio, política orçamental e relação com os orçamentos de M19. Um centro por obra não equivale a gestão completa de empreitadas.

## 24. M23 — Pessoas

Origem: pessoas. Objetivo: representar identidade e relações usadas pelos processos. Intervenientes: administrador, RH e gestão escolar. Dependências: modelo partilhado de pessoas (`internal/shared/pessoas`), auth e módulos consumidores.

Evidência: 1 rota (`GET /api/pessoas/{id}/relacoes`), protegida por `autorizacao.gerir_utilizadores`; 2 ficheiros Go, 0 de teste. A criação de identidade é feita pelos consumidores (RH, recrutamento, escolar, auth).

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M23-01 / P1 | Associar a identidade da pessoa aos papéis usados na organização. | Relações entre conta, colaborador ou aluno referenciam a pessoa correta no cenário homologado. | Parcial — depende dos consumidores |
| RF-M23-02 / P1 | Consultar relações de responsabilidade e dependência nas duas direções. | Consulta de encarregado/aluno apresenta relações ativas corretas e nenhuma de outra organização. | Parcial |
| RF-M23-03 / P1 | Respeitar vigência, tipo, responsabilidade legal e relação principal. | Relação terminada não é apresentada como ativa nem concede acesso que dependia da sua vigência. | Parcial |
| RF-M23-04 / P2 | Definir tratamento de duplicados e atualização de relações. | Correção autorizada preserva histórico e não atribui permissões por mera semelhança de nome/contacto. | Proposta |

Âmbito observado: o módulo só consulta relações. Gestão completa de relações e fusão de duplicados são propostas a especificar. Decisão pendente: permissão própria para consulta de relações, em vez de `gerir_utilizadores`.

## 25. M24 — Recursos humanos

Origem: recursos-humanos. Objetivo: gerir colaboradores e processos laborais. Intervenientes: RH, gestores, aprovadores e financeiro. Dependências: pessoas, auth, empresas, self-service, hardware e contabilidade quando configurada.

Evidência: 167 rotas (`/api/rh`, `/api/pedido-ferias`); 52 ficheiros Go, 6 de teste. Permissões: `recursos-humanos.*` (13 códigos, incluindo `processar_salarios`, `aprovar_ausencias`, `ver_processos_disciplinares`), `assiduidade.*` (7 códigos), `pedido-ferias.ver_pedidos|submeter_pedido`; funcionalidade `rh.assiduidade`. Jobs diários de ausências e de recálculo de resultados de assiduidade.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M24-01 / P1 | Gerir colaboradores, identificação, unidades orgânicas, cargos, contactos de emergência e desligamento. | Cadastro e vínculos pertencem à organização correta e campos protegidos só são alterados por RH autorizado. | Parcial |
| RF-M24-02 / P1 | Gerir contratos, anexos e documentos do colaborador. | Ficheiro e contrato são associados ao colaborador certo e permanecem inacessíveis a outros perfis. | Parcial |
| RF-M24-03 / P1 | Configurar horários, regras, tipos de evento e catálogos de assiduidade. | Apuramento usa a regra vigente e âmbito aplicável, sem presumir associações não modeladas. | Parcial |
| RF-M24-04 / P1 | Consultar eventos, presenças, resultados e relatórios de assiduidade. | Resultados conciliam com eventos e correções aprovados nos períodos homologados. | Parcial |
| RF-M24-05 / P1 | Registar ponto administrativo e aprovar correções/justificações. | Gestor autorizado atua no colaborador correto com motivo e histórico; o colaborador não usa a ação administrativa. | Parcial |
| RF-M24-06 / P1 | Gerir férias, licenças e pedidos com decisão autorizada. | Aprovação/rejeição é rastreável e o saldo/estado aplicável reflete a decisão segundo política. | Risco — AP-05 |
| RF-M24-07 / P1 | Gerir componentes, benefícios, escalões de IRPS e processamento salarial. | Casos aprovados reproduzem valores, deduções e recibos; reprocessamento não duplica efeitos confirmados. | Parcial |
| RF-M24-08 / P2 | Gerir formação (com certificados), avaliação por critérios e processos disciplinares. | Registos pertencem ao colaborador autorizado, com período, intervenientes e acesso adequado. | Parcial |
| RF-M24-09 / P1 | Controlar consentimento e enrolment/re-enrolment biométrico (facial e impressão digital). | Ação requer funcionário elegível, consentimento e método ativo; falha externa não apresenta enrolment concluído. | Parcial |
| RF-M24-10 / P1 (v0.2) | Registar adiantamentos e empréstimos ao colaborador e descontá-los no processamento salarial. | Valor descontado não excede o saldo em dívida; cancelamento só antes do desconto e com registo. | Parcial |
| RF-M24-11 / P1 (v0.2) | Pagar a folha processada uma única vez, com lançamento contabilístico e movimento de tesouraria, e exportar o ficheiro bancário. | Dois pedidos de pagamento concorrentes produzem um único lançamento e um único movimento; conta/caixa de pagamento pertence à organização; recibos passam a pagos. | Risco — N-04 |
| RF-M24-12 / P1 (v0.2) | Gerir identificadores de marcação do colaborador (etiquetas NFC, QR) e métodos de marcação. | Um identificador pertence a um só colaborador ativo da organização; remoção impede marcações futuras. | Parcial |
| RF-M24-13 / P1 (v0.2) | Gerir saldos de ausência e recalcular resultados de assiduidade de um colaborador ou dia. | Recálculo é idempotente e reproduz o resultado do job diário para a mesma data. | Parcial |
| RF-M24-14 / P2 (v0.2) | Consultar e registar o histórico salarial do colaborador. | Alteração salarial tem data de efeito, motivo e autor; não altera folhas já processadas. | Parcial |

Decisões pendentes: regras laborais, exemplos salariais, feriados, turnos, retenção e tolerâncias. Associações de equipa/turno/contrato não disponíveis no modelo de regras não devem ser simuladas como resolvidas. `rh.presencas` continua ativo em paralelo com `eventos_assiduidade` por decisão deliberada; definir a data de retirada.

## 26. M25 — Recrutamento

Origem: recrutamento. Objetivo: acompanhar vagas e candidaturas até à contratação. Intervenientes: candidato, recrutador e RH. Dependências: pessoas, auth, notificações, RH e armazenamento.

Evidência: 63 rotas (`/api/recrutamento`, `/api/public/recrutamento`, aliases públicos `/vagas` e `/candidaturas`, tempo real em `/socket.io`); 17 ficheiros Go, 0 de teste. Permissões: `recrutamento.ver_vagas`, `gerir_vagas`, `ver_candidaturas`, `gerir_candidaturas`, `configurar_recrutamento`. `ContratarCandidato` bloqueia a candidatura com `FOR UPDATE` e valida estado e consentimento.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M25-01 / P1 | Gerir vagas, campos personalizados e publicação autorizada. | Candidato vê apenas vagas publicadas e campos válidos da organização correspondente. | Parcial |
| RF-M25-02 / P1 | Receber candidatura e CV e permitir acesso ao portal do candidato. | Documentos e estado só são consultados pelo candidato correto ou recrutador autorizado. | Parcial |
| RF-M25-03 / P1 | Acompanhar etapas, mensagens e notificações da candidatura. | Cada atualização fica no processo certo; comunicações não misturam organizações/candidatos. | Parcial |
| RF-M25-04 / P1 | Encaminhar contratação para RH. | A pessoa e o vínculo criados correspondem ao candidato selecionado; reenvio não cria colaborador duplicado. | Parcial — ficheiros copiados fora da transação |
| RF-M25-05 / P2 | Consultar dashboard e enviar documentos para assinatura. | Indicadores conciliam com candidaturas filtradas e assinatura refere o documento aprovado. | Parcial |
| RF-M25-06 / P2 (v0.2) | Permitir ao candidato gerir perfil, experiências e formações, consultar candidaturas por código e receber notificações push. | Dados pertencem ao candidato autenticado; consulta por código não expõe dados além do estado acordado. | Parcial |
| RF-M25-07 / P2 (v0.2) | Receber pedidos de contacto públicos e configurar notificações do recrutamento. | Formulário público tem proteção contra abuso; pedido chega à organização correta. | Parcial — limite de abuso por definir |

Decisões pendentes: etapas, campos obrigatórios, consentimento, retenção de CV, critérios de contratação e retirada dos aliases públicos duplicados.

## 27. M26 — Self-service

Origem: self-service. Objetivo: permitir ao colaborador executar e acompanhar processos pessoais. Intervenientes: colaborador e gestores nos fluxos de aprovação. Dependências: auth, RH, notificações, FaceClock e WebSocket.

Evidência: 34 rotas (`/api/self-service`, `/ws/chat`); 12 ficheiros Go, 2 de teste. Permissões: `assiduidade.*`, `chat.ver_conversas|enviar_mensagem`, recibos via `recursos-humanos.ver_recibos`. Lote offline com validação temporal, elegibilidade e idempotência (alteração local por confirmar: `ponto_lote.go` e migração `20260926120000_marcacoes_offline_sincronizadas` ainda não estão em commit).

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M26-01 / P1 | Consultar perfil, documentos e recibos próprios; atualizar campos permitidos e alterar senha. | Recursos pertencem ao colaborador autenticado; troca de ID não divulga dados de terceiros. | Parcial |
| RF-M26-02 / P1 | Marcar ponto com método habilitado e prova aplicável. | Identidade, permissão e prova são validadas antes da gravação do evento. | Parcial |
| RF-M26-03 / P1 | Sincronizar marcações offline elegíveis com idempotência. | Cada item retorna registado, duplicado ou rejeitado; reenvios aceites não duplicam eventos. | Parcial |
| RF-M26-04 / P1 | Consultar assiduidade e apresentar justificações/correções, com cancelamento de pedido pendente. | Pedido é associado ao próprio evento/período e não altera resultados aprovados sem decisão autorizada. | Parcial |
| RF-M26-05 / P1 | Ler comunicados e notificações pessoais. | Leitura só atualiza os registos do destinatário autorizado. | Parcial |
| RF-M26-06 / P1 | Usar chat com participantes e presença no âmbito autorizado. | Participantes de outra empresa não obtêm acesso indevido; presença é filtrada; concorrência não termina o serviço; reenvio não altera mensagem de outro autor. | Bloqueado — AI-04, AI-05, AI-06, AI-11 |
| RF-M26-07 / P1 (v0.2) | Executar prova de vida facial (desafio e verificação) antes da marcação facial. | Desafio é de uso único e expira; verificação falhada ou reutilizada não grava marcação. | Parcial — critérios de aceitação técnicos por homologar |

Limites documentados do offline: PIN e impressão digital, até 100 itens, até 72 horas no passado e cinco minutos de tolerância futura. Facial não é prometido offline. Biometria local do telemóvel não equivale à prova verificada pelo servidor. Mudanças e uso dos métodos requerem aprovação de RH. As rotas biométricas existem em duplicado (`/biometric/…` e `/biometria/facial/…`); definir a canónica e a data de retirada da outra.

## 28. M27 — Gestão escolar

Origem: gestao-escolar. Objetivo: gerir operação académica e cobranças das instituições de ensino. Intervenientes: administração escolar, professores, alunos, encarregados e financeiro. Dependências: pessoas, auth, pagamentos, notificações e assinatura digital.

Evidência: 212 rotas (`/api/escolar`, `/api/portal/aluno|professor|encarregado`); 57 ficheiros Go, 6 de teste. Permissões: `gestao-escolar.*` (13 códigos, incluindo `gerir_matriculas`, `lancar_notas`, `gerir_propinas`, `portal_aluno`). Jobs `generateMonthlyFees` e `notifCobrancasVencidas`; o commit 1aa032cd deixou de faturar propinas quando o plano é ambíguo.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M27-01 / P1 | Gerir estrutura académica: anos, períodos, níveis, ciclos, cursos, classes, disciplinas e turmas. | Relações e períodos são válidos e pertencem à instituição correta. | Parcial |
| RF-M27-02 / P1 | Gerir alunos, professores e matrículas. | Matrícula vincula aluno à estrutura correta e segue regras aprovadas de inscrição/estado e capacidade. | Bloqueado — AP-09 |
| RF-M27-03 / P1 | Registar presenças, notas e resultados autorizados. | Professor atua nas atribuições permitidas; cálculo e publicação reproduzem exemplos académicos homologados. | Bloqueado — AP-09 (notas do portal do professor) |
| RF-M27-04 / P1 | Gerir horários, tempos letivos e calendário escolar. | Horários e datas correspondem às turmas/disciplinas selecionadas, com validação dos conflitos acordados. | Parcial |
| RF-M27-05 / P1 | Gerar propinas e associar cobranças/pagamentos ao aluno. | Obrigação e saldo conciliam; callback inválido ou repetido não cria pagamento indevido; desconto aprovado é aplicado. | Bloqueado — AP-06, AP-10, AP-11, AP-17, AP-20, AI-02 |
| RF-M27-06 / P1 | Disponibilizar portais por aluno, professor e encarregado. | Cada perfil vê apenas dados associados às suas relações e atribuições ativas. | Parcial |
| RF-M27-07 / P2 | Gerir ocorrências, méritos, sanções, comunicação e anexos escolares. | Caso e documentos têm acesso restrito aos intervenientes autorizados e histórico de alterações. | Parcial |
| RF-M27-08 / P2 | Gerir operações de biblioteca suportadas. | Operação identifica recurso, aluno e estado segundo regras aprovadas, sem misturar instituições. | Parcial |
| RF-M27-09 / P1 (v0.2) | Emitir cobranças com referência bancária, dividi-las em parcelas, aplicar bolsas e cancelar cobranças. | Soma das parcelas é igual à cobrança; bolsa respeita a vigência e o limite aprovado; existe um único comportamento de emissão. | Risco — N-03 |
| RF-M27-10 / P1 (v0.2) | Convidar, ativar, desativar e repor senha de acesso ao portal por aluno ou turma. | Convite chega apenas a alunos ativos da turma; repor senha invalida a anterior. | Parcial |
| RF-M27-11 / P2 (v0.2) | Produzir boletins, relatórios académicos e dashboard escolar. | Boletim reproduz notas publicadas do período; dashboard não inclui outra instituição. | Parcial |
| RF-M27-12 / P2 (v0.2) | Gerir papéis de aluno e de professor (delegado, diretor de turma) e permissões por cargo escolar. | Papel tem vigência e turma; permissões derivadas cessam quando o papel termina. | Parcial |

Decisões pendentes: modelo académico, escala de notas, publicação, calendário, propinas, permissões dos encarregados e comportamento de emissão de cobrança (ver N-03). O módulo só é obrigatório em fases destinadas a instituições de ensino.

## 29. M28 — Aprovações

Origem: aprovacoes. Objetivo: controlar decisões formais em processos. Intervenientes: requerente, aprovador e administrador. Dependências: auth, cargos, compras, RH, escolar e assinatura digital.

Evidência: 10 rotas (`/api/aprovacoes`); 5 ficheiros Go, 0 de teste. Os fluxos exigem `compras.aprovar_pedidos` e a funcionalidade `compras.aprovacoes`, embora sirvam também RH e escolar; os pedidos só exigem autenticação (N-05).

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M28-01 / P1 | Gerir fluxos com etapas e responsáveis autorizados. | Configuração válida identifica quem decide e impede etapas sem responsável elegível. | Parcial — N-05 (permissão de compras) |
| RF-M28-02 / P1 | Consultar pedidos e pendências aplicáveis ao cargo. | Aprovador só recebe pedidos para os quais tem responsabilidade válida; requerente vê os seus. | Risco — N-05 |
| RF-M28-03 / P1 | Aprovar, rejeitar ou cancelar pedido conforme estado. | Duas decisões concorrentes não produzem estados incompatíveis; motivo e ator ficam registados; o efeito na entidade de origem corresponde à decisão. | Bloqueado — AP-05, AP-06, AP-20 |
| RF-M28-04 / P2 | Encaminhar pedido aprovado para assinatura. | Documento e versão correspondem ao pedido; envio não substitui a decisão exigida. | Parcial |
| RF-M28-05 / P1 (v0.2) | Congelar a versão do fluxo aplicada a cada pedido aberto. | Alterar ou eliminar um fluxo não muda os níveis nem os aprovadores de pedidos já abertos. | Proposta |

Decisões pendentes: limites de valor, delegação, substituições, ordem de decisão, possibilidade de autoaprovação e permissão própria do módulo.

## 30. M29 — Tarefas

Origem: tarefas. Objetivo: organizar trabalho em quadros, listas e cartões. Intervenientes: equipas e gestores. Dependências: auth e utilizadores.

Evidência: 16 rotas (`/api/tarefas`); 4 ficheiros Go, 0 de teste. Permissões: `tarefas.ver_quadros`, `gerir_quadros`, `gerir_listas`, `gerir_cartoes`, `mover_cartoes`, `eliminar_cartoes`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M29-01 / P1 | Criar, consultar, atualizar e arquivar quadros. | Quadro respeita o âmbito autorizado e arquivamento preserva informação necessária. | Parcial |
| RF-M29-02 / P1 | Criar e reordenar listas de um quadro. | Ordem guardada coincide com a solicitada sem afetar listas de outros quadros; lote com lista inválida é rejeitado por inteiro. | Risco — reordenação ignora erros e não restringe ao quadro |
| RF-M29-03 / P1 | Criar, atualizar e mover cartões entre listas autorizadas. | Cartão conserva identidade e dados; destino inválido ou externo é rejeitado. | Parcial — posição `MAX+1` sem reserva |
| RF-M29-04 / P2 | Concluir e consultar o estado das tarefas. | Estado permite identificar trabalho concluído e pendente segundo critérios acordados. | Parcial |

Decisões pendentes: participantes do quadro, atribuições, prazos e retenção de itens eliminados/arquivados.

## 31. M30 — Notificações

Origem: notifications. Objetivo: gerir envio e acompanhamento de comunicação transacional. Intervenientes: administrador, operação e destinatários. Dependências: jobs, serviços de email (AWS SES), SMS, push (Firebase) e módulos emissores.

Evidência: 10 rotas (`/api/notificacoes`); 2 ficheiros Go, 0 de teste no módulo (o dispatcher em `background` tem testes). Permissões: `notificacoes.ver_notificacoes`, `gerir_notificacoes`. Despacho com reserva atómica `FOR UPDATE SKIP LOCKED`, recuperação de reservas expiradas e backoff exponencial; outbox transacional introduzida no commit eb75ebba.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M30-01 / P1 | Gerir canais e templates da organização. | Canal/template validado usa o âmbito e conteúdo autorizados, com proteção das credenciais. | Bloqueado — AP-07 |
| RF-M30-02 / P1 | Enfileirar e despachar mensagens associadas ao processo. | A mensagem não é perdida entre confirmação do processo e despacho nos cenários transacionais incluídos. | Risco — AI-09 (worker separado não arranca) |
| RF-M30-03 / P1 | Consultar estados e reprocessar falhas autorizadas. | Operação identifica resultado e motivo; reprocessamento respeita a política de repetição e destinatário. | Parcial |
| RF-M30-04 / P2 | Enviar push em massa aos destinatários selecionados. | Seleção não inclui contas de outra organização nem dispositivos fora do público aprovado. | Parcial |
| RF-M30-05 / P1 (v0.2) | Notificar automaticamente cobranças vencidas e outros eventos agendados aprovados. | Cada cobrança vencida gera no máximo uma notificação por período acordado; destinatário pertence à organização. | Parcial |

Regras: enfileirado, tentado, aceite pelo fornecedor e entregue são estados distintos; falha do fornecedor deve ser visível. Decisões pendentes: canais ativos, número de tentativas, consentimento e níveis de confirmação de entrega.

## 32. M31 — Assinatura digital

Origem: assinatura-digital. Objetivo: executar assinatura e conservar evidência documental. Intervenientes: emissor, signatário e verificador autorizado. Dependências: armazenamento (MinIO), notificações, autenticação, provedor/certificados de assinatura e TSA.

Evidência: 26 rotas (`/api/assinatura-digital`, `/api/public/assinatura-digital`, `/assinar/{token}`, `/verificar-assinatura`); 16 ficheiros Go, 16 de teste. Permissões: `assinatura-digital.ver_documentos`, `gerir_documentos`, `assinar_documentos`. FKs compostas com tenant e evidências imutáveis. A suite do fork `third_party/digitorus-pdfsign` falha (SubFilter `ETSI.CAdES.detached` e ficheiros abertos no Windows).

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M31-01 / P1 | Criar documentos, versões e lista de signatários. | Documento e ficheiros são válidos e associados à organização; alterações seguem o estado permitido. | Parcial |
| RF-M31-02 / P1 | Enviar convites e validar identidade/prova de assinatura. | Convite expirado ou prova inválida não permite assinar; código de uso único não é reutilizado. | Parcial |
| RF-M31-03 / P1 | Assinar, recusar e cancelar com transições controladas. | Falha do provedor não apresenta assinatura concluída; ações concorrentes preservam estado consistente. | Parcial |
| RF-M31-04 / P1 | Conservar original, versões e evidências protegidas. | Conteúdo protegido não é substituído ou eliminado por uma operação comum. | Parcial |
| RF-M31-05 / P1 | Disponibilizar validação e verificação autorizada. | Resultado corresponde ao documento e inclui informação suficiente sobre a verificação efetuada. | Parcial |
| RF-M31-06 / P1 | Receber eventos do provedor com origem validada e deduplicação. | Callback inválido ou repetido não produz efeito indevido nem segunda assinatura. | Parcial |

Decisões pendentes: nível de assinatura, certificados, provedor, validade jurídica e exposição da página de verificação. Atualizar os testes do fork PDF antes da homologação; não se assume conformidade jurídica a partir do formato do ficheiro.

## 33. M32 — Assinaturas comerciais

Origem: assinaturas. Objetivo: gerir planos de subscrição e respetivo ciclo comercial. Intervenientes: administração comercial, cliente e financeiro. Dependências: planos da plataforma, organizações e faturação.

Evidência: 9 rotas (`/api/assinaturas`); 2 ficheiros Go, 0 de teste. Permissões: `assinaturas.ver_assinaturas`, `gerir_assinaturas`. Renovação automática no job diário `processSubscriptionRenewals`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M32-01 / P1 | Consultar e gerir planos de subscrição autorizados. | Condições e estado são visíveis ao público permitido e coerentes com o catálogo aprovado. | Parcial |
| RF-M32-02 / P1 | Criar subscrição vinculada ao cliente/organização. | Subscrição usa plano e empresa válidos da organização e não duplica um vínculo incompatível. | Bloqueado — AP-12 |
| RF-M32-03 / P1 | Renovar e cancelar subscrição conforme regras comerciais. | Vigência e estado refletem a ação; corpo inválido é rejeitado; cancelamento preserva histórico e impede nova cobrança. | Bloqueado — `RenovarAssinatura` ignora erro do JSON; AP-24 |
| RF-M32-04 / P2 | Consultar faturas e utilização associadas. | Registos pertencem à subscrição correta e conciliam com o período e condições aprovadas. | Parcial |
| RF-M32-05 / P1 (v0.2) | Renovar automaticamente subscrições ativas vencidas, por periodicidade (mensal, trimestral, anual). | Cada subscrição elegível gera exatamente uma fatura por período e avança a data na mesma transação; suspensas e canceladas são excluídas, mesmo se canceladas durante a execução. | Bloqueado — AP-21, AP-22, AP-23, AP-24 |

Regras: este módulo trata subscrições, não assinatura de documentos. Decisões pendentes: cobrança recorrente, carência, cancelamento, limites de utilização, política de aniversário em fim de mês e relação entre planos globais (M04) e comerciais.

## 34. M33 — Hardware

Origem: hardware. Objetivo: integrar dispositivos físicos e eventos autorizados. Intervenientes: administrador de dispositivos, operação e RH. Dependências: auth de dispositivo, MQTT, RH e serviço de processamento.

Evidência: 34 rotas (`/api/hardware`, `/api/v1/fingerprint`); 13 ficheiros Go, 2 de teste. Permissões: `hardware.ver_dispositivos`, `gerir_dispositivos`, `ver_eventos`, `gerir_eventos`; terminais autenticam com `device_auth`. `processor.go` grava `event_hash` com `ON CONFLICT`, distingue falha permanente de transitória; job `retryHardwareEvents`.

| ID / prioridade | Requisito | Critério de aceitação | Estado |
|---|---|---|---|
| RF-M33-01 / P1 | Registar dispositivos e associar identidade/credenciais à organização. | Dispositivo só opera no âmbito atribuído; credencial revogada deixa de permitir eventos. | Parcial |
| RF-M33-02 / P1 | Receber eventos de dispositivo por canais autorizados (HTTP individual, lote, MQTT). | Identidade, integridade e validade são verificadas; evento de origem inválida é rejeitado. | Parcial |
| RF-M33-03 / P1 | Processar eventos e integrar efeitos em assiduidade. | Evento aceite é associado ao colaborador/contexto correto e reenvio não duplica marcação. | Parcial — efeito derivado exatamente uma vez por demonstrar |
| RF-M33-04 / P1 | Acompanhar estado operacional e recuperar eventos pendentes. | Falha deixa resultado identificável e a recuperação mantém a coerência dos eventos. | Parcial |
| RF-M33-05 / P2 | Configurar equipamentos e integrações biométricas suportadas (genérico, ZKTeco, impressão digital). | Equipamento elegível usa configuração autorizada e não recebe identidades de outra organização. | Parcial |
| RF-M33-06 / P1 (v0.2) | Validar no terminal QR, NFC e geofence e registar/revogar consentimento biométrico pelo dispositivo. | QR expirado ou de outra organização é rejeitado; NFC só identifica colaborador ativo; consentimento revogado impede enrolment. | Parcial |
| RF-M33-07 / P1 (v0.2) | Fornecer ao terminal a configuração de assiduidade e a lista de colaboradores elegíveis. | Lista contém apenas colaboradores ativos da organização do dispositivo e os dados mínimos necessários. | Parcial |

Regras: terminais físicos usam autenticação de dispositivo; a app do colaborador usa JWT e o fluxo Self-service. Não colocar credencial administrativa de dispositivo na app. Decisões pendentes: equipamentos suportados, canais ativos, rotação de chaves e política de replay.

## 35. Processos automáticos e interfaces externas (v0.2)

### 35.1 Jobs em segundo plano

Os jobs correm na API (`StartJobs`) ou no worker separado (`cmd/worker`). AI-09: na definição Compose lida, o worker não recebe os segredos que valida e falha antes de iniciar. Cada job deve correr de forma segura em mais de uma instância e deixar resultado observável.

| Job | Módulo | Periodicidade | Requisitos | Estado / defeito |
|---|---|---|---|---|
| `dispatchNotifications`, `recoverExpiredNotificationLeases` | M30 | Intervalo | RF-M30-02/03 | Parcial — SKIP LOCKED e testes; AI-09 |
| `notifCobrancasVencidas` | M27/M30 | Diário | RF-M30-05 | Parcial |
| `generateMonthlyFees`, `logAmbiguousFeePlans` | M27 | Diário | RF-M27-05 | Parcial — commit 1aa032cd |
| `processSubscriptionRenewals` | M32 | Diário | RF-M32-05 | Bloqueado — AP-21 a AP-24 |
| `processDailyAbsences` | M24 | Diário | RF-M24-13 | Parcial |
| `recalcularResultadosAssiduidade` | M24 | Diário | RF-M24-13 | Parcial |
| `checkStockAlerts` | M12 | Diário | RF-M12-05 | Parcial |
| `reconcilePaymentIntents` | M16/M27 | Intervalo | RF-M16-03 | Risco — AI-10 |
| `retryHardwareEvents` | M33 | Intervalo | RF-M33-04 | Parcial |
| `cleanExpiredSessions` | M01 | Diário | RF-M01-02 | Parcial |

### 35.2 Interfaces públicas e de integração

| Interface | Autenticação | Requisitos | Observação |
|---|---|---|---|
| `POST /api/pos/pagamentos/webhook`, `POST /api/escolar/payments/callback` | HMAC só se o segredo estiver configurado | RF-M16-03, RF-M27-05 | AI-02, AI-10 |
| `/api/assinatura-digital/webhooks` | Provedor | RF-M31-06 | Validar origem e deduplicação |
| `/oauth/authorize`, `/oauth/token`, `/oauth/jwks` | OAuth | RF-M01-06 | — |
| `/api/v1/users`, `/api/v1/transactions` | JWT (PayCore) | RF-M01-09, RF-M16-12 | Permissões emprestadas de faturação |
| `/api/hardware/*`, `/api/v1/fingerprint/*` | Credencial de dispositivo | RF-M33-01 a 07 | MQTT opcional |
| `/api/public/recrutamento/*`, `/vagas`, `/candidaturas` | Público / sessão de candidato | RF-M25-01/02/06/07 | Aliases duplicados |
| `/assinar/{token}`, `/verificar-assinatura`, `/api/public/assinatura-digital` | Token de convite / público | RF-M31-02/05 | — |
| `/ws/chat`, `/socket.io/*` | Token na query (chat) | RF-M26-06, RF-M25-03 | AI-04 a AI-06, AI-11, AI-12 |
| `/health` | Público | RF-M08-05 | Estado estático |

## 36. Achados complementares desta versão (v0.2)

Verificação estática feita sobre o código atual, com o mesmo método das análises de 14–15/10. Não foram executados testes nem ligações à base de dados.

| ID | Gravidade | Problema | Evidência | Requisitos |
|---|---|---|---|---|
| N-01 | Alta | `POST /api/utilizadores/{userId}/notifications` e `/activity` não comparam `{userId}` com o utilizador autenticado. Quem tem `perfil.editar_perfil` cria notificações (também empurradas por WebSocket) e atividade em nome de qualquer conta, incluindo de outra organização. `RegistarActividade` ignora o erro do INSERT e grava `r.RemoteAddr`. `ObterAvatar` devolve o avatar de qualquer utilizador. | `utilizadores/handlers/notificacoes.go:61`, `actividade.go:59`, `avatar.go:16`; router `/api/utilizadores/{userId}` | RF-M02-01, RF-M02-03, RF-M02-05; RT-01, RT-08 |
| N-02 | Alta | `CriarRecibo` só confirma que a fatura existe no tenant: aceita fatura em rascunho ou cancelada, valor acima do saldo, `payment_method_id` sem validação de tenant e reenvio sem idempotência; incrementa `valor_pago` sem bloqueio nem atualização do estado (`parcialmente_paga`/`paga`). A baseline não tem CHECK `valor_pago <= total`, pelo que `saldo_pendente` pode ficar negativo. | `modulo-faturacao/handlers/faturacao.go:718-765`; baseline `faturacao.invoices` | RF-M15-10, RF-M15-05; RT-03 |
| N-03 | Média | `POST /api/escolar/student-invoices/{id}/emit` está registado duas vezes com handlers diferentes (`EmitirCobrancaAluno` e `EmitirCobrancaComReferencia`). No chi prevalece o último registo, pelo que o primeiro handler fica inalcançável e o comportamento de emissão depende da ordem no router. Confirmar com teste de rota. | `router.go:1130` e `:1217` | RF-M27-09 |
| N-04 | Alta (concorrência) | `PagarFolhaPagamento` lê o estado da folha sem `FOR UPDATE` e o UPDATE final não exige `estado='processada'`. Dois pedidos concorrentes podem criar dois lançamentos contabilísticos e dois movimentos de tesouraria; o segundo sobrescreve `journal_entry_id`. O erro de decodificação do corpo é ignorado. | `recursos-humanos/handlers/processamento_salarial.go:1101-1170` | RF-M24-11, RF-M19-04, RF-M18-02; RT-02, RT-03 |
| N-05 | Média | Os pedidos de aprovação só exigem autenticação: `ObterRequest` devolve qualquer pedido do tenant e as suas decisões a qualquer utilizador autenticado. Os fluxos exigem `compras.aprovar_pedidos` e a funcionalidade `compras.aprovacoes`, embora sirvam RH e escolar. `atualizarEstadoEntidade` ignora erros e atualiza a entidade de origem só por ID. | `aprovacoes/handlers/requests.go:133`, `:321`; `router.go:874` | RF-M28-01, RF-M28-02, RF-M28-03 |
| N-06 | Baixa (governação) | O catálogo de permissões não acompanha os módulos: Produtos usa códigos de `stock`; Pessoas exige `autorizacao.gerir_utilizadores`; Aprovações usa `compras`; a API PayCore usa `faturacao`; Monitorização não tem código próprio. Retirar permissão de um módulo afeta outro sem intenção explícita. | Extração de `RequirePermission` em `router.go` | RF-M01-04, RF-M11-*, RF-M23-*, RF-M28-*, RF-M16-12 |

## 37. Requisitos não funcionais derivados da análise (v0.2)

Complementam as metas de desempenho, recuperação e disponibilidade do BRD geral. São condição de entrada em produção para os módulos afetados.

| ID / prioridade | Requisito | Critério de aceitação | Origem |
|---|---|---|---|
| RNF-01 / P1 | Instalação e atualização reprodutíveis da base de dados. | Base vazia e cópia de versão anterior chegam ao mesmo esquema pelo caminho documentado; migrações sem `down` têm política de reversão escrita. | Análise aprofundada §4 (V-01, V-02) |
| RNF-02 / P1 | Nenhum segredo no código ou em fallback de configuração. | API e worker recusam arrancar em produção sem `DATABASE_URL`, segredos JWT, de webhook e de integração; ligações remotas usam TLS validado. | AI-01, AI-02, AI-09 |
| RNF-03 / P1 | Isolamento entre organizações verificado por testes. | Cada módulo incluído tem teste com dois tenants para leitura, escrita e referências recebidas; avaliar RLS ou FKs compostas como defesa adicional. | RT-01; ausência de RLS nas migrações |
| RNF-04 / P1 | Contratos SQL verificados contra PostgreSQL real. | Os testes dos fluxos críticos correm com `TEST_DATABASE_URL` numa base criada pelas migrações; mocks não substituem esta verificação. | AP-02, AP-07 a AP-11, AP-21/22 |
| RNF-05 / P1 | Precisão monetária exata. | Cálculos de POS, tesouraria, gateway e faturação usam decimal ou unidades mínimas; arredondamento por moeda está definido e testado. | Análise inicial (`float64`) |
| RNF-06 / P1 | Limites de pedido. | Todos os endpoints JSON aplicam tamanho máximo de corpo, profundidade e tamanho de coleções; uploads têm limite e tipos permitidos. | Análise inicial (420 `json.NewDecoder`, 5 `MaxBytesReader`) |
| RNF-07 / P1 | Limitação de taxa partilhada e baseada em origem confiável. | Rate limit funciona com várias réplicas, liberta memória de IPs inativos e usa IP só de proxies confiáveis. | AI-07, AI-08, AI-12 |
| RNF-08 / P1 | Concorrência verificada. | Hub WebSocket, saldos, decisões e sequências passam `go test -race` e testes com duas ligações reais e barreiras. | AI-06, AP-04, AP-05, N-04 |
| RNF-09 / P1 | Arranque e paragem controlados. | Ping inicial com prazo; readiness separada de liveness; shutdown aguarda jobs e regista erro. | AI-12 |
| RNF-10 / P2 | Imagem de produção endurecida. | Container corre sem privilégios; `.dockerignore` exclui backups, executáveis e uploads do contexto de build. | AI-12 (`Dockerfile`; `backend/` contém backup SQL e `.exe`) |
| RNF-11 / P2 | Manutenção do router. | Registo de rotas por módulo, sem rotas duplicadas, com teste que falha perante duplicação ou rota sem permissão. | Router com 3 147 linhas; N-03 |
| RNF-12 / P1 | Testes por módulo incluído numa fase. | Nenhum módulo de uma fase entra em produção sem testes próprios dos cenários P1; hoje 23 módulos não têm ficheiros de teste. | Inventário de testes |

## 38. Matriz de rastreabilidade de defeitos

Liga cada achado das análises aos requisitos que bloqueia ou põe em risco. "AI" refere a análise inicial de 14/10 (problemas 1 a 12, pela ordem do documento).

| Achado | Gravidade | Resumo | Requisitos afetados |
|---|---|---|---|
| AI-01 | Alta | Credenciais PostgreSQL no fallback de configuração | RNF-02; RT-04 |
| AI-02 | Alta | Callbacks financeiros sem HMAC quando o segredo está vazio | RF-M16-03, RF-M27-05 |
| AI-03 | Alta | Reposição/alteração de senha ignoram erros; token não é de uso único | RF-M01-03 |
| AI-04 | Alta | Participantes de chat não validados contra o tenant | RF-M26-06; RT-01 |
| AI-05 | Média | Presença online partilhada entre tenants | RF-M26-06 |
| AI-06 | Alta | Concorrência no hub WebSocket pode terminar o processo | RF-M26-06; RNF-08 |
| AI-07 | Alta (infra) | IP de origem baseado em headers sem fronteira de confiança | RF-M04-03, RF-M06-03; RNF-07 |
| AI-08 | Alta | Login/PIN/TOTP sem limitação de tentativas | RF-M01-01, RF-M01-07, RF-M16-10 |
| AI-09 | Alta (operação) | Worker separado não recebe os segredos exigidos | RF-M30-02; RNF-02 |
| AI-10 | Alta | Callback pode fazer regredir pagamento confirmado | RF-M16-03 |
| AI-11 | Média | Reenvio de mensagem altera texto de outro participante | RF-M26-06 |
| AI-12 | Média | Limitações operacionais (rate limit em memória, Origin livre, token na query, health estático, shutdown, Dockerfile) | RF-M01-02, RF-M08-05; RNF-07, RNF-09, RNF-10 |
| AP-01 | Alta | Permissões diretas sem contexto de tenant | RF-M01-04, RF-M01-05 |
| AP-02 | Alta | Pagamentos financeiros escrevem coluna gerada e estado inválido | RF-M17-03 |
| AP-03 | Alta | Fatura de fornecedor emitida na primeira linha | RF-M13-04, RF-M13-06 |
| AP-04 | Alta | Corrida na validação de receções, devoluções e alocações | RF-M13-03/04/05, RF-M12-02 |
| AP-05 | Alta | Decisões de aprovação concorrentes | RF-M28-03, RF-M24-06 |
| AP-06 | Alta | Aprovação de desconto escolar executa ramo de rejeição | RF-M27-05, RF-M28-03 |
| AP-07 | Alta | Canal de notificação sem `codigo` obrigatório | RF-M30-01 |
| AP-08 | Média | Marcas usam coluna inexistente | RF-M11-02 |
| AP-09 | Alta | Matrículas e notas do professor usam colunas inexistentes | RF-M27-02, RF-M27-03 |
| AP-10 | Alta | Integração escolar → financeiro incompatível com o esquema | RF-M17-02/03, RF-M27-05 |
| AP-11 | Alta | Recibo escolar sem `product_id`; repetição tratada como erro | RF-M15-04, RF-M27-05 |
| AP-12 | Alta | Subscrição aceita plano/empresa de outro tenant | RF-M32-02 |
| AP-13 | Alta | Alocações e orçamentos aceitam centro de outro tenant | RF-M22-02, RF-M22-03 |
| AP-14 | Média | Conversão usa taxa futura | RF-M21-02, RF-M21-03 |
| AP-15 | Média | Mais de uma (ou nenhuma) moeda base | RF-M21-01 |
| AP-16 | Média | Estado logístico decidido por texto livre | RF-M14-03, RF-M14-04 |
| AP-17 | Alta | Efeitos financeiros/contabilísticos de melhor esforço | RF-M13-04, RF-M19-04, RF-M27-05, RF-M18-02 |
| AP-18 | Média | Erros de `Begin` ignorados em compras | RF-M13-01/03/04/05 |
| AP-19 | Alta | Estado de compra aceite do cliente na criação | RF-M13-01, RF-M13-02 |
| AP-20 | Alta | Erro ao consultar fluxo de desconto aplica-o diretamente | RF-M27-05, RF-M28-03 |
| AP-21 | Alta | Job de renovação filtra estado inexistente | RF-M32-05 |
| AP-22 | Alta | Fatura de renovação com estado inválido | RF-M32-05 |
| AP-23 | Média | Plano trimestral renovado como mensal | RF-M32-05 |
| AP-24 | Alta | Subscrição cancelada pode ser faturada | RF-M32-03, RF-M32-05 |
| N-01 | Alta | Notificações/atividade criadas para qualquer utilizador | RF-M02-01/03/05 |
| N-02 | Alta | Recibo manual sem validação de estado, saldo e idempotência | RF-M15-10, RF-M15-05 |
| N-03 | Média | Rota de emissão de cobrança escolar duplicada | RF-M27-09; RNF-11 |
| N-04 | Alta | Pagamento de folha salarial sem bloqueio | RF-M24-11, RF-M19-04, RF-M18-02 |
| N-05 | Média | Pedidos de aprovação sem permissão; fluxos com permissão de compras | RF-M28-01/02/03 |
| N-06 | Baixa | Catálogo de permissões desalinhado dos módulos | RF-M01-04, RF-M11, RF-M23, RF-M28, RF-M16-12 |

## 39. Resumo do estado por módulo (v0.2)

Contagem dos estados atribuídos nas fichas acima. "Bloq." inclui requisitos com qualquer componente bloqueado. Nenhum requisito está verificado ou homologado.

| Módulo | Rotas | Testes | RF | Bloq. | Risco | Parcial | Proposta | Prioridade de correção |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| M01 Auth | 52 | 6 | 9 | 3 | 1 | 4 | 1 | AI-03, AP-01, AI-08 |
| M02 Utilizadores | 25 | 0 | 6 | 1 | 1 | 4 | 0 | N-01 |
| M03 Empresas | 25 | 1 | 6 | 0 | 0 | 6 | 0 | — |
| M04 Superadmin | 36 | 0 | 7 | 0 | 1 | 6 | 0 | AI-07 |
| M05 Configuração | 26 | 0 | 4 | 0 | 0 | 4 | 0 | Sobreposição com M21 |
| M06 Segurança | 7 | 0 | 4 | 0 | 1 | 3 | 0 | AI-07 |
| M07 Auditoria | 9 | 0 | 4 | 0 | 1 | 3 | 0 | Auditoria pós-commit |
| M08 Monitorização | 2 | 0 | 5 | 0 | 0 | 3 | 2 | Readiness |
| M09 Clientes | 41 | 0 | 7 | 0 | 0 | 7 | 0 | — |
| M10 CRM | 20 | 0 | 4 | 0 | 0 | 4 | 0 | — |
| M11 Produtos | 53 | 0 | 5 | 1 | 0 | 4 | 0 | AP-08 |
| M12 Stock | 56 | 0 | 8 | 0 | 1 | 7 | 0 | AP-04 (via compras) |
| M13 Compras | 19 | 1 | 6 | 4 | 2 | 0 | 0 | AP-03, AP-04, AP-17, AP-19 |
| M14 Logística | 11 | 0 | 4 | 2 | 0 | 2 | 0 | AP-16 |
| M15 Faturação | 38 | 2 | 12 | 1 | 0 | 11 | 0 | N-02 |
| M16 POS | 51 | 1 | 12 | 1 | 1 | 10 | 0 | AI-02, AI-10 |
| M17 Financeiro | 11 | 0 | 4 | 2 | 0 | 2 | 0 | AP-02, AP-10 |
| M18 Tesouraria | 10 | 0 | 4 | 0 | 0 | 4 | 0 | AP-17, N-04 |
| M19 Contabilidade | 71 | 0 | 8 | 0 | 1 | 7 | 0 | AP-17, N-04 |
| M20 Impostos | 18 | 0 | 4 | 0 | 0 | 4 | 0 | — |
| M21 Multi-moeda | 8 | 0 | 4 | 3 | 0 | 1 | 0 | AP-14, AP-15 |
| M22 Centros de custo | 13 | 0 | 4 | 2 | 0 | 2 | 0 | AP-13 |
| M23 Pessoas | 1 | 0 | 4 | 0 | 0 | 3 | 1 | — |
| M24 RH | 167 | 6 | 14 | 0 | 2 | 12 | 0 | AP-05, N-04 |
| M25 Recrutamento | 63 | 0 | 7 | 0 | 0 | 7 | 0 | — |
| M26 Self-service | 34 | 2 | 7 | 1 | 0 | 6 | 0 | AI-04, AI-05, AI-06, AI-11 |
| M27 Escolar | 212 | 6 | 12 | 3 | 1 | 8 | 0 | AP-06, AP-09, AP-10, AP-11, AP-20, N-03 |
| M28 Aprovações | 10 | 0 | 5 | 1 | 1 | 2 | 1 | AP-05, AP-06, N-05 |
| M29 Tarefas | 16 | 0 | 4 | 0 | 1 | 3 | 0 | — |
| M30 Notificações | 10 | 0 | 5 | 1 | 1 | 3 | 0 | AP-07, AI-09 |
| M31 Assinatura digital | 26 | 16 | 6 | 0 | 0 | 6 | 0 | Testes do fork PDF |
| M32 Assinaturas comerciais | 9 | 0 | 5 | 3 | 0 | 2 | 0 | AP-12, AP-21 a AP-24 |
| M33 Hardware | 34 | 2 | 7 | 0 | 0 | 7 | 0 | — |
| **Total** | **1 184** | **43** | **207** | **29** | **16** | **157** | **5** | |

O total de rotas exclui `/health`. "Testes" conta ficheiros `_test.go` dentro da pasta do módulo; testes noutros pacotes (middleware, background, router) não estão incluídos.

## 40. Homologação e aprovação por módulo

Os fluxos entre módulos e os cenários de autorização, repetição, concorrência e falha estão detalhados no [plano de homologação dos requisitos integrados](homologacao-requisitos-nexora-erp.md) e nos cenários V-01 a V-13 da [análise aprofundada](analise-profunda-backend-modulos-2026-10-14.md). O plano complementa os critérios deste catálogo e mantém a distinção entre comportamento proposto e resultado efetivamente testado.

Cada requisito deve gerar pelo menos um cenário positivo e um negativo relevantes; testes de isolamento, autorização, repetição e falha são acrescentados conforme o efeito do requisito. Um requisito "Bloqueado" só pode entrar numa fase depois de o defeito estar corrigido e retestado. Cenários adicionais introduzidos nesta versão:

| Cenário | Preparação | Resultado exigido |
|---|---|---|
| V-14 — Notificação cruzada (N-01) | Utilizador do tenant A envia notificação para um utilizador do tenant B. | Rejeição 403; nenhuma linha criada e nada enviado por WebSocket. |
| V-15 — Recibo além do saldo (N-02) | Fatura emitida de 100; recibos de 60 e 60; recibo para fatura em rascunho e cancelada. | Segundo recibo de 60 é rejeitado; estado passa a parcialmente paga e depois paga com 40; rascunho e cancelada rejeitados. |
| V-16 — Pagamento de folha concorrente (N-04) | Dois pedidos de pagamento da mesma folha com barreira. | Um único lançamento, um único movimento de tesouraria, folha paga uma vez. |
| V-17 — Emissão de cobrança escolar (N-03) | Emitir cobrança com e sem referência bancária. | Comportamento único e documentado; teste de rota falha se houver registo duplicado. |
| V-18 — Pedido de aprovação alheio (N-05) | Utilizador sem relação com o pedido consulta-o por ID. | Rejeição ou dados mínimos segundo política aprovada. |
| V-19 — Renovação de subscrições (AP-21 a 24) | Subscrições mensal, trimestral e anual vencidas; uma cancelada durante a execução. | Uma fatura por subscrição elegível e período; trimestral avança três meses; cancelada não é faturada. |

Para cada módulo incluído numa fase, preencher: responsável funcional, requisitos aceites, dependências, configuração, dados de teste, evidências, defeitos abertos e decisão. Até esse registo existir, o estado é proposta pendente de validação.

| Campo da ficha de homologação | Informação a registar |
|---|---|
| Módulo e fase | Código M01 a M33 e fase aprovada |
| Responsável | Nome do responsável funcional e representante de qualidade |
| Âmbito aceite | IDs de requisitos incluídos e exclusões justificadas |
| Estado técnico | Estado de cada requisito (secção 1) e achados abertos (secção 38) |
| Dados e regras | Exemplos homologados, parâmetros e massa de teste |
| Evidência | Resultado por cenário, ambiente e referência aos testes |
| Defeitos | Impacto, responsável e resolução/reteste |
| Decisão | Aprovado, reprovado ou aceite com desvios documentados |
| Data | Data da decisão e versão do produto/documento |

### Ordem recomendada de correção

1. **Reprodutibilidade e segredos:** RNF-01, RNF-02, RNF-04; corrigir os contratos SQL AP-02, AP-07 a AP-11, AP-21, AP-22.
2. **Autorização e isolamento:** AP-01, AP-12, AP-13, AI-04, AI-05, N-01, N-05, AI-02, AI-03, AI-08.
3. **Integridade de processo:** AP-03, AP-06, AP-17, AP-19, AP-20, N-02, N-03.
4. **Concorrência:** AP-04, AP-05, AP-24, N-04, AI-06, AI-10.
5. **Regras e operação:** AP-14, AP-15, AP-16, AP-18, AP-23, AI-09, AI-12, N-06, RNF-05 a RNF-12.

Metas de desempenho, recuperação, disponibilidade e privacidade permanecem as propostas do BRD geral e devem ser ratificadas antes da entrega. Este catálogo não constitui compromisso de datas, orçamento ou ativação simultânea de todos os módulos.
