# Nexora ERP — Análise aprofundada do backend e dos requisitos

Data: 14/10/2026. Âmbito: os 33 módulos do backend Go e o catálogo de 157 requisitos. Documento técnico de avaliação; não constitui homologação de negócio ou auditoria do ambiente de produção.

## 1. Conclusão principal

O principal problema não é a ausência de módulos: é a diferença entre os contratos que o código assume e os que as migrações, autorizações e processos realmente garantem. Há implementação substancial, sobretudo em assinatura digital, RH, processamento de dispositivos e serviços escolares, mas o catálogo de requisitos não pode ser considerado entregue apenas pela existência de handlers.

Esta revisão encontrou incompatibilidades determinísticas com o esquema versionado em pagamentos financeiros, canais de notificação, marcas, matrículas e notas. Encontrou também perda de contexto de tenant nas permissões diretas, emissão prematura de fatura de compra, condições de corrida e efeitos financeiros executados depois de confirmar o processo de origem. As falhas prioritárias atravessam vários módulos.

A recomendação é estabilizar identidade e contratos SQL, depois homologar processos completos com PostgreSQL isolado, concorrência e falhas injetadas. Dividir o router ou acrescentar novas funcionalidades antes desses passos não resolve os problemas de integridade identificados.

## 2. Método, evidência e limites

Foram inventariados os 437 ficheiros Go próprios, excluindo o fork em third_party, e pesquisados os 33 módulos. A leitura aprofundada concentrou-se em handlers, middlewares, serviços, adaptadores e migrações dos fluxos com maior impacto. Foram confrontadas rotas com os métodos encontrados, para distinguir código de produção exposto de métodos antigos que já não são registados.

Também foi criado um verificador lexical, docs/tools/audit_backend_contracts.py, que compara INSERTs com a baseline e algumas alterações de coluna das migrações ativas. O resultado, docs/audit-backend-contracts.json, contém inventário por ficheiro/módulo e 15 candidatos de divergência. Esses candidatos não são 15 defeitos confirmados: SQL dinâmico, alterações não reconhecidas e rotas indiretas exigem análise humana. Por exemplo, campos adicionados pela estabilização da assinatura digital não devem ser classificados como ausentes apenas por um parser simplificado.

Categorias de evidência utilizadas:

- **Código:** o comportamento ou a ausência de proteção está diretamente visível no fluxo lido.
- **Esquema versionado:** existe uma incompatibilidade entre código e migrações consultadas. O impacto depende de o banco executar esse esquema; alterações manuais em produção não foram verificadas.
- **Concorrência:** existe uma sequência plausível de execução que viola a regra; não foi reproduzida sob carga nesta revisão.
- **Pendente:** não há evidência suficiente para declarar o requisito entregue ou ausente.

Não foram efetuadas chamadas à base remota, migrações, alterações funcionais, entrevistas ou testes em equipamentos reais. Não se calcula percentagem de conclusão dos 157 requisitos. A cobertura quantitativa de testes também não foi medida.

Os resultados anteriores de go test ./... e go vet ./... continuam registados na análise inicial: o módulo principal passou, os testes PostgreSQL foram ignorados por falta de TEST_DATABASE_URL e a suite própria do fork PDF falhou. Esses comandos não foram repetidos nesta revisão documental. Novas verificações efetuadas: inventário, comparação lexical SQL/código, procura nas migrações ativas e confirmação das rotas relevantes.

## 3. Novos problemas prioritários

Os IDs AP identificam os achados desta revisão. A gravidade refere-se ao impacto do processo, não a uma classificação CVSS. “Alta” não significa que a falha já tenha sido explorada.

| ID | Gravidade | Problema | Requisitos diretamente afetados |
|---|---|---|---|
| AP-01 | Alta | Permissões diretas lidas, eliminadas e atribuídas sem contexto de tenant. | RF-M01-04, RF-M01-05; RT-01 |
| AP-02 | Alta | Pagamentos financeiros escrevem coluna calculada e estado não aceite. | RF-M17-03; RT-02 |
| AP-03 | Alta | A primeira linha da fatura de compra emite o documento e bloqueia a segunda. | RF-M13-04 |
| AP-04 | Alta | Receções, devoluções e alocações de pagamentos de compra validam saldo antes de o bloquear. | RF-M13-03, RF-M13-04, RF-M13-05; RT-02 |
| AP-05 | Alta | Decisões de aprovação leem estado antes da transação e atualizam sem condição de estado/nível. | RF-M28-03; RF-M24-06 |
| AP-06 | Alta | Aprovação de desconto escolar passa “aprovada”, mas o ramo escolar espera “aprovado”. | RF-M27-05, RF-M28-03 |
| AP-07 | Alta | Criar canal de notificações omite codigo, obrigatório no esquema. | RF-M30-01 |
| AP-08 | Média | Marca de produto usa descricao, ausente no esquema consultado. | RF-M11-02 |
| AP-09 | Alta | Matrículas e notas de professor usam colunas que a baseline não contém. | RF-M27-02, RF-M27-03 |
| AP-10 | Alta | Integração escolar financeira omite cliente e tenta escrever campos incompatíveis. | RF-M17-02, RF-M17-03, RF-M27-05 |
| AP-11 | Alta | Recibo escolar omite product_id obrigatório; repetição do recibo trata conflito como erro. | RF-M15-04, RF-M27-05; RT-03 |
| AP-12 | Alta | Subscrição permite referenciar plano/empresa de outro tenant. | RF-M32-02; RT-01 |
| AP-13 | Alta | Alocações e orçamentos aceitam centros de custo sem validar o tenant da referência. | RF-M22-02, RF-M22-03; RT-01 |
| AP-14 | Média | Conversão escolhe a taxa mais recente mesmo quando tem vigência futura. | RF-M21-02, RF-M21-03 |
| AP-15 | Média | Habilitação de moedas não assegura uma única moeda base. | RF-M21-01 |
| AP-16 | Média | Tracking muda estado pela ocorrência de fragmentos de texto livre. | RF-M14-03, RF-M14-04 |
| AP-17 | Alta | Efeitos financeiros/contabilísticos configurados podem falhar depois de o processo ser aceite. | RF-M13-04, RF-M19-04, RF-M27-05; RT-02 |
| AP-18 | Média | Erros ao abrir transações de compras são ignorados antes de usar tx. | RF-M13-03, RF-M13-04, RF-M13-05 |
| AP-19 | Alta, dependente da política | Estado aprovado/emitido de compras pode ser indicado na criação sem passar pelo fluxo. | RF-M13-02, RF-M28-03 |
| AP-20 | Alta, dependente da configuração | Erro ao consultar necessidade de aprovação de desconto faz o fluxo seguir para aplicação direta. | RF-M27-05, RF-M28-03 |

### AP-01 — A autorização direta não acompanha a membership

Evidência: backend/internal/modules/auth/models/rbac.go:163; backend/internal/modules/auth/handlers/permissoes.go:85 e :92. A baseline inclui tenant_id em auth.permissoes_diretas (:654), mas a leitura filtra apenas user_id, o DELETE elimina as permissões desse utilizador em todos os contextos e o INSERT nem preenche tenant_id.

Pré-condição: um utilizador possui memberships em duas organizações. A permissão direta atribuída por A entra no conjunto de permissões quando o mesmo utilizador opera em B. Um administrador de A também pode substituir as permissões que deveriam pertencer a B. A validação “o utilizador pertence ao meu tenant” não resolve o âmbito das linhas posteriores.

Correção: definir semântica explícita para permissões por membership ou tenant; filtrar leitura/escrita/eliminação pelo contexto; rever unicidade e migrar permissões legadas. Permissões globais, se necessárias, devem ter regra própria. Teste decisivo: conceder uma ação apenas em A, trocar para B e demonstrar rejeição; a alteração em A deve preservar as atribuições de B.

### AP-02 — Pagamentos do Financeiro não respeitam o esquema

Evidência: financeiro/handlers/financeiro.go:190 e :286; baseline :2468, :2473, :2511 e :2516. Ambos os UPDATEs atribuem valor_pendente, definido como GENERATED ALWAYS, e usam status='pago'; o CHECK permite liquidada, mas não pago.

Resultado esperado com o esquema versionado: a operação falha e a transação não confirma o pagamento. Não se deve concluir que há pagamento órfão nesse esquema, pois a falha anterior impede o commit.

Há uma fragilidade adicional latente: o pagamento é inserido antes de validar/bloquear a obrigação, e o UPDATE não verifica RowsAffected. Se os problemas de esquema forem corrigidos sem corrigir o fluxo, um ID inexistente ou de outra empresa poderá deixar um pagamento sem obrigação atualizada. O valor também não é limitado ao saldo e não há chave de idempotência de negócio.

Correção: deixar a coluna gerada ao banco, normalizar o estado liquidada, resolver a obrigação no tenant sob bloqueio ou UPDATE condicional, validar saldo e verificar a linha afetada. Testar liquidação parcial/total, conta inexistente, conta de outro tenant, excesso e reenvio.

### AP-03 — Fatura de fornecedor torna-se imutável antes de receber todas as linhas

Evidência: compras/handlers/financeiro.go:42. A inserção de item exige i.status='rascunho'. Na mesma chamada, o UPDATE em :71 muda a fatura para emitida e a contabilidade é iniciada em :91. A rota de adição está registada no router :862.

Cenário: criar fatura em rascunho → adicionar artigo A → estado passa a emitida → adicionar artigo B → a seleção não encontra fatura elegível. A API lida adiciona uma linha por chamada; não foi identificado nesse handler um lote que permita construir o documento completo antes da emissão.

Correção: separar “editar linhas” de “emitir”. A emissão valida documento completo, fecha totais e aplica efeitos obrigatórios. Teste: criar três linhas, verificar totais, emitir e rejeitar novas linhas após emissão.

### AP-04 — A existência de transação não elimina a corrida na validação

Evidência: compras/handlers/operacoes.go:63 e :155; compras/handlers/financeiro.go:133. As condições received_quantity + quantidade <= quantity, returned_quantity + quantidade <= quantity_received e valor_alocado + valor <= valor são avaliadas na seleção de inserção, antes dos UPDATEs posteriores. Não há bloqueio explícito da linha que controla esses limites na leitura identificada.

Interleaving: duas transações veem 0 recebido de 10; cada uma aceita 7; os UPDATEs incrementam e podem resultar em 14. O bloqueio posterior do UPDATE serializa a escrita, mas não repete a condição validada pela seleção anterior. Os CHECKs de quantidade identificados na baseline exigem não negatividade, não o limite acumulado.

Correção: bloquear as linhas de controlo antes da validação ou reservar quantidade/valor por UPDATE condicional com RETURNING, na mesma transação. Estabelecer ordem de bloqueios para reduzir deadlocks. Testes com duas ligações reais e barreira de sincronização são necessários; chamadas sequenciais não demonstram correção desta corrida.

### AP-05 — A mesma aprovação pode receber decisões incompatíveis

Evidência: aprovacoes/handlers/requests.go:175. O SELECT do pedido pendente ocorre antes de Begin; os UPDATEs em :246 e :253 usam apenas o ID. Duas pessoas elegíveis podem ler o mesmo nível e decidir antes de qualquer uma atualizar o estado. Não foi encontrada proteção de unicidade por pedido/nível que imponha uma decisão única nas migrações pesquisadas.

Consequências possíveis: decisões duplicadas, última escrita a sobrepor uma decisão diferente e efeitos de ausência/saldo aplicados mais de uma vez. Isto depende de concorrência e do fluxo configurado; não foi reproduzido nesta revisão.

Correção: bloquear pedido dentro da transação, validar nível e membership ativa, restringir a transição ao estado/nível esperado e proteger a decisão com a unicidade apropriada. Testar aprovação versus rejeição e aprovação versus cancelamento em paralelo.

### AP-06 — Aprovação de desconto executa o ramo de rejeição

Evidência: aprovacoes/handlers/requests.go:250 passa aprovada; :360 compara aprovado. O fluxo escolar é real: gestao-escolar/handlers/fees.go:93 cria o pedido para gestao_escolar.school_fees.

Resultado da sequência lida: pedido torna-se aprovado, mas a função não entra no ramo que aplica o desconto; entra no else que limpa desconto_pendente e desconto_pendente_motivo. Não é apenas uma diferença visual no texto do estado: altera o resultado económico.

Correção: usar vocabulário único/tipado e uma transição de entidade que devolva erro e valide tenant/linha afetada. Teste: desconto sujeito a aprovação, decisão final favorável, pedido aprovado e desconto efetivamente aplicado; rejeição não aplica desconto.

### AP-07 a AP-11 — Desvios de SQL que os mocks não detetam

| Fluxo | Código versus esquema | Efeito e observação |
|---|---|---|
| Canal de notificação | notifications/handlers/notificacoes.go:47 omite codigo; baseline :4174 exige-o sem default. | CriarCanal está registado no router :2701 e falha nesse esquema. |
| Marcas | gestao-produtos/handlers/produtos.go:85 e :116 usam descricao; product_brands não tem esse campo. | A criação está registada em :673. A listagem também ignora erro de Query e usa rows, podendo provocar panic recuperado pelo HTTP. |
| Matrículas | gestao-escolar/repositories/enrollment.go:24 e SELECTs usam tipo; a tabela não tem tipo. | CriarMatriculaV2 está registado em :1102 e usa o serviço/repositório; a existência de validação de capacidade não resolve o contrato SQL. |
| Notas do professor | portal_professor.go:581 usa class_id e conflito (class_id,student_id,grade_item_id); school_grades não tem class_id. | A rota está registada em :1296. Os erros de Exec são ignorados no laço; Commit sinaliza a transação abortada, mas não explica a falha inicial. |
| Escolar → Financeiro | shared/adapters/financial.go:34 e repositories/fee.go:231 omitem customer_id obrigatório. | Quando a integração está habilitada, há ainda escrita na coluna calculada e estado pago. |
| Recibo escolar | shared/adapters/invoicing.go:76 omite product_id, obrigatório em faturacao.invoice_items. | Integração configurada não produz a linha segundo esse esquema. DO NOTHING RETURNING seguido de retorno no erro pgx.ErrNoRows também impede o tratamento posterior invoiceID==0 de reconhecer repetição. |

As migrações ativas foram pesquisadas para alterações destes campos. Não foi encontrada correção que resolva estas incompatibilidades específicas. Deve-se confirmar o esquema efetivo num ambiente isolado; um banco ajustado manualmente não elimina a lacuna de reprodutibilidade do repositório.

Um achado lexical foi deliberadamente separado: cliente_data.go:255 usa limite em vez de limite_credito e ignora o erro, mas o router atual usa DefinirLimiteCredito/ObterLimiteCreditoSeguro de clientes_api_ext.go. Não é correto usar o método antigo para declarar que a rota atual de crédito está quebrada. Esse código deve ser removido ou corrigido para evitar reintrodução.

### AP-12 e AP-13 — Filtrar a entidade principal não valida as referências

Em assinaturas/handlers/assinaturas.go:118, tenant_id vem da sessão, mas plan_id e company_id são aceites sem resolver o proprietário. A FK de plano da baseline :8729 aponta apenas ao ID. O JOIN de ListarAssinaturas também liga o plano apenas por ID. Um plano de outro tenant pode ser associado e o seu nome aparecer na resposta do tenant criador.

Em centros-custo/handlers/allocations.go:113 e budgets.go:83, cost_center_id é usado diretamente. As FKs em :8771/:8773 só asseguram que o centro existe, não que pertence ao tenant da alocação/orçamento. A correção deve também rever parent_id e gestor_user_id na criação/atualização de centros, não apenas estes dois endpoints.

Correção: validar referência ativa no contexto correto com INSERT SELECT ou FKs compostas onde adequado. Testes: usar plano, empresa e centro de custo de outro tenant; rejeitar sem criar qualquer linha. Para catálogos deliberadamente globais, explicitar a exceção.

### AP-14 e AP-15 — Câmbio e moeda base sem invariantes suficientes

Evidência: multi-moeda/handlers/multi_moeda.go:158 ordena por effective_date DESC, sem exigir effective_date <= data de conversão. Se existe taxa futura, ela vence a taxa atual. A API também não recebe uma data explícita para conversão histórica.

AdicionarMoedaTenant (:104) altera is_base apenas na moeda escolhida; não desmarca a anterior. A baseline tem unicidade de tenant/currency, mas não um índice parcial que limite is_base=true a uma linha por tenant. Duas moedas podem ser marcadas base. Também é possível desmarcar a única base pelo mesmo endpoint; RemoverMoedaTenant proteger a base não resolve esse caso.

Correção: definir data e precisão de conversão, escolher taxa elegível e proteger a troca da moeda base de forma transacional com restrição de unicidade apropriada. Validar zero casas decimais: CriarMoeda trata Decimals==0 como default 2, não permitindo distinguir uma moeda sem decimais de um campo omitido.

### AP-16 — Texto livre não é um evento logístico validado

Evidência: logistica/handlers/logistica.go:213. Qualquer texto contendo entreg muda o envio para entregue; “não entregue” satisfaz a condição. Um evento posterior com transit/sai pode devolver um envio entregue a em_transito.

Correção: códigos fechados de evento e matriz de transições. A descrição humana permanece livre, mas não controla o estado. Testar “não entregue”, tentativa falhada, repetição e evento tardio de saída após entrega.

### AP-17 — Integração contabilística/financeira é de melhor esforço

Em compras/handlers/financeiro.go:91, PostPurchaseInvoiceJournalEntry é chamado depois do commit. O adaptador purchase_accounting.go:47 devolve void e transforma erros em log/retorno. Assim, a fatura pode estar emitida sem o lançamento configurado.

Em gestao-escolar/services/fee.go, RegisterPayment chama tesouraria, Financeiro, contabilidade e faturação; falhas dessas portas são registadas em log e a função pode continuar a devolver sucesso. O problema não é exigir todas as integrações em todos os tenants: é uma integração habilitada falhar sem estado de reconciliação visível e recuperável.

Correção: decidir que efeitos são obrigatórios na mesma transação e quais são assíncronos. Para os assíncronos, usar outbox persistida com estado, repetição, deduplicação e reconciliação. Testar cada dependência a falhar após o pagamento/fatura de origem. “Logs de aviso” não substituem um saldo conciliado ou uma pendência operacional.

### AP-18 a AP-20 — Erros e estados não devem abrir atalhos

AP-18: compras contém Begin cujo erro é descartado em compras.go:149, financeiro.go:49/:133 e operacoes.go:51/:143. Se Begin falhar, tx é usado mesmo assim, incluindo defer Rollback. Corrigir o erro antes de qualquer uso e testar indisponibilidade do banco.

AP-19: CriarRequisicaoCompra/CriarOrdemCompra aceitam status do JSON e aplicam COALESCE, em compras.go:73/:122. Um utilizador com permissão para criar pode indicar aprovada se esse valor passa o CHECK, sem executar a decisão do fluxo. A receção considera ordens aprovadas/parciais. Isto compromete o requisito quando a política exige aprovação; a rota de criação não deve confiar no estado fornecido pelo cliente.

AP-20: fees.go:84 só entra no processo de aprovação se err==nil e flow!=nil. Erro ao consultar o fluxo cai no caminho de aplicação direta. Distinguir “sem fluxo configurado” de “não foi possível determinar a autorização” e negar/adiar no segundo caso. Guardar desconto pendente e criar pedido também deve ter atomicidade e confirmar a existência da cobrança.

## 4. Instalação e migrações

As primeiras quatro migrações ativas têm versões 20260724000001 a 20260724000004. A baseline que cria o esquema tem versão 20260724080001. A primeira migração executa ALTER TABLE assinatura_digital.documentos já na linha 9.

Consequência verificável pela ordem e conteúdo: uma aplicação de todas as migrações ativas a um banco vazio, em ordem de versão, tenta alterar uma tabela que ainda não foi criada. backend/scripts/run_migrations.sh usa o diretório inteiro em migrate up e não resolve esse arranque vazio. Pode existir um procedimento de bootstrap que aplica a baseline primeiro; isso deve ser documentado e testado, não presumido.

Não se recomenda renumerar migrations já aplicadas em produção sem um plano de compatibilidade. Definir caminhos distintos para base nova e atualização existente, testar ambos e comparar o resultado. As duas migrações sem down continuam identificadas no inventário; a política de reversão deve explicitar a limitação.

## 5. Avaliação módulo a módulo

As secções seguintes cobrem todos os códigos M01 a M33 do catálogo. “Evidência” significa existência e leitura de implementação, não aceitação de todos os critérios. Ausência de achado específico não significa ausência de defeitos. O inventário de testes por módulo está no JSON de evidências; não é medida de cobertura.

### M01 — Auth

Há autenticação, OAuth, PIN/TOTP, sessões, cargos, memberships e permissões. RequireAuth consulta a sessão e estado do utilizador; RBAC organiza o acesso por membership. AP-01 quebra essa organização para permissões diretas. A consulta de membership de RequireAuth não exige m.ativo, enquanto LoadUserAccess exige; rotas que não aplicam a verificação de permissão precisam de análise de revogação do vínculo.

RF-M01-01 a 06 têm evidência parcial; RF-M01-03/04/05 têm falhas identificadas. Além de AP-01, permanecem as falhas de password e limites de autenticação da análise inicial. Homologação: dois tenants, dois vínculos, revogação individual, refresh, passo adicional e consumo concorrente de reset. Fontes: middleware/auth.go, auth/models/rbac.go e auth/handlers.

### M02 — Utilizadores

Há perfil, avatar, agenda, preferências, dispositivos, tokens e notificações pessoais. preferencias.go compara o ID do chamador com userId antes da leitura/escrita, uma proteção positiva. Perfil global e preferências pessoais não devem ser confundidos com papéis por membership.

RF-M02-01 a 04: evidência parcial. Validar ficheiros, revogação efetiva de tokens/dispositivos, estado de leitura e uso com mais de uma membership. Não foi demonstrado que apagar um registo de dispositivo revoga todas as sessões ou credenciais relacionadas. Fontes: utilizadores/handlers, especialmente preferencias.go, tokens.go e dispositivos.go.

### M03 — Empresas

Há gestão institucional e filiais, com testes específicos de acesso cruzado. A interface DB nos handlers permite testes com pgxmock. Esse controlo é uma base útil, mas não prova que todas as referências criadas em outros módulos respeitam empresas.

RF-M03-01 a 04: evidência parcial. Verificar empresa/unidade inativa em novos processos, retenção de documentos e referências que impedem exclusão. Prioridade: testar integrações que recebem company_id sem usar as validações deste módulo, como AP-12. Fontes: empresas/handlers e cross_tenant_test.go.

### M04 — Superadmin

Há provisionamento, estados de tenant, planos, módulos, funcionalidades, dependências e origens permitidas. O router aplica RequireSuperadmin, allowlist e reautenticação a grupos sensíveis. A allowlist vazia permite acesso por decisão explícita do código, pelo que é necessário acordar o comportamento operacional.

RF-M04-01 a 04: evidência parcial. Testar suspensão no middleware efetivamente usado, não apenas no cadastro; validar dependências ao mudar módulos e distinguir ações globais de ações sobre um tenant. Origem confiável e segredos de produção mantêm os riscos da análise inicial. Fontes: superadmin/handlers, router e superadmin_security.go.

### M05 — Configuração

Há branding, parâmetros, documentos, catálogos, templates, integrações e configuração de assiduidade. O módulo sobrepõe áreas de moeda e notificações; é necessário definir qual cadastro cada consumidor realmente consulta.

RF-M05-01 a 04: evidência parcial. Testar mudança de parâmetro no tenant A sem afetar B e confirmar propagação/cache nas dependências. É pendente demonstrar que uma configuração inválida é rejeitada por todos os endpoints; apenas listar/gravar chaves não valida a regra funcional. Fontes: sistema-configuracao/handlers e config/config.go.

### M06 — Segurança

Há políticas, consulta MFA, allowlist e envio de política para assinatura. O middleware específico do superadmin possui testes. O controlo de IP depende da confiança nos headers e proxy, conforme análise inicial.

RF-M06-01 a 04: evidência parcial. Consultar inscrição MFA não prova que um segundo fator é obrigatório nos logins. Homologar enforcement real de política, origem e prova adicional. Fonte: seguranca/handlers e middleware/superadmin_security.go.

### M07 — Auditoria

Há logs operacionais, eventos de auditoria protegidos, verificação de integridade, exportação e encaminhamento para assinatura. Vários processos executam auditoria depois do commit e ignoram o resultado, pelo que integridade dos eventos existentes não significa completude dos eventos esperados.

RF-M07-01/03 precisam de demonstrar simultaneamente completude e resistência a alteração. Definir operações que devem falhar ou gerar pendência quando a auditoria obrigatória não pode ser gravada. Testar exportação sem segredos e filtros de tenant. Fontes: auditoria/handlers, shared/adapters/legal_audit.go e chamadas nos handlers.

### M08 — Monitorização

O módulo é um proxy HMAC para métricas e logs do FaceClock, não uma plataforma completa de monitorização. As rotas estão no grupo superadmin/faceclock, o que reduz a exposição a utilizadores comuns. Não foi confirmado um sistema de alertas gerais nem prontidão agregada.

RF-M08-01/03: evidência parcial. RF-M08-02 precisa de exemplos reais de timeout/ausência de configuração. RF-M08-04 continua proposta de evolução. Confirmar que logs obtidos com credencial de serviço têm o âmbito autorizado. Fontes: monitoring/handlers/faceclock.go e router:3019.

### M09 — Clientes

Há cadastro, grupos, crédito, saldo, tags e interfaces complementares. O router usa handlers seguros de crédito/pagamentos em clientes_api_ext.go; alguns métodos antigos em cliente_data.go não são os que servem essas rotas.

RF-M09-01 a 04: evidência parcial. Não atribuir a falha SQL do método antigo à rota atual. Validar unicidade de NUIT/código opcionais: a baseline usa UNIQUE NULLS NOT DISTINCT, que pode limitar cadastros sem valor. Aprovar se isso é regra pretendida. Fontes: clientes_api_ext.go, clientes.go e baseline:7331/:7333.

### M10 — CRM

Há leads, oportunidades e atividades. CRUD não prova regras completas do funil, encaminhamento para cliente ou automação entre etapas. O âmbito de responsáveis e referências deve ser validado nos endpoints que os aceitam.

RF-M10-01 a 03: evidência parcial; RF-M10-04 requer confirmar o processo concreto de encaminhamento. Testar transições autorizadas, perda/ganho, duplicação e utilizadores externos ao tenant. Fontes: crm/handlers/leads.go, oportunidades.go e atividades.go.

### M11 — Produtos

Há catálogos extensos e atributos/variantes. AP-08 impede operações de marcas no esquema consultado. Alguns handlers ignoram erros de Query/Scan e podem devolver resultado vazio/sucesso aparente ou entrar em panic HTTP, mascarando falhas de esquema.

RF-M11-02 tem bloqueio identificado; RF-M11-01/03/04 são parciais. Antes de homologar venda, construir artigo, marca, categoria, unidade e variante numa base instalada pelas migrations. Fontes: produtos.go, catalogo_ext.go e baseline de produtos.

### M12 — Stock

Há posições, movimentos, reservas, localizações, lotes e inicialização segura. stock_ext.go usa INSERT SELECT para confirmar produto/armazém do tenant e a variante do produto; a baseline usa UNIQUE NULLS NOT DISTINCT nas posições, protegendo também variantes nulas.

RF-M12-01 a 05: evidência parcial. A corrida AP-04 chega ao stock através de Compras, mesmo que algumas ações de stock sejam protegidas. Testar saldo, reserva, movimento e documento de origem juntos, incluindo falha e concorrência. “Abaixo do mínimo” não prova envio automático de alerta. Fontes: stock.go, stock_ext.go e baseline:8189.

### M13 — Compras

Há requisições, ordens, receções, devoluções, faturas, pagamentos e assinatura. AP-03/04/17/18/19 revelam lacunas no ciclo completo. A gestão de estado deve ser separada da criação e da adição de linhas.

RF-M13-02 a 05 não devem ser aceites antes das correções e testes reais. Ensaiar compra com três linhas, aprovação, receção parcial, concorrência na receção, devolução e pagamento alocado. Fontes: compras/handlers/compras.go, operacoes.go, financeiro.go e adaptador contabilístico.

### M14 — Logística

Há motoristas, viaturas, rotas, envios e tracking. CriarEnvio valida várias referências pelo tenant, uma proteção positiva. AP-16 compromete a interpretação dos eventos e estados.

RF-M14-01/02: evidência parcial; RF-M14-03/04 têm falha de estado identificada. Não foram demonstrados manutenção de frota, prova formal de entrega ou tracking contínuo. Homologar códigos e transições, ocorrência negativa, evento tardio e recurso inativo. Fonte: logistica/handlers/logistica.go.

### M15 — Faturação

Há orçamentos, encomendas, séries, faturas, recibos, notas de crédito, PDF, assinatura e integração contabilística. O gerador de número usa bloqueio da série e existem testes de acesso entre tenants. AP-11 afeta a porta de recibo escolar, não prova falha de todos os recibos manuais.

RF-M15-01 a 06: evidência parcial. A criação de recibo manual soma valor_pago, mas o trecho lido não demonstra limite ao saldo ou idempotência de negócio; homologar excesso e reenvio. Rever respostas de sucesso nos endpoints que ignoram erros de alteração de estado. Fontes: modulo-faturacao/handlers/faturacao.go, fiscal.go e shared/adapters/invoicing.go.

### M16 — POS

Há terminal, operador, caixa, catálogo, pagamentos, supervisor, estornos e recibos. Os estornos lidos usam FOR UPDATE em venda/itens, melhor do que as validações de Compras que leem antes do bloqueio. Permanecem os riscos de callback opcionalmente autenticado e regressão de estado no serviço de pagamentos.

RF-M16-03 é afetado pelos achados iniciais; os restantes têm evidência parcial. Validar venda→stock→fatura→pagamento→caixa→estorno com exemplos conciliados e duas ligações concorrentes. Fonte: pos/handlers e pkg/nexorapay/service.go.

### M17 — Financeiro

Há categorias, métodos, obrigações, pagamentos e consulta de cash flow. AP-02 bloqueia a liquidação segundo a baseline. AP-10 afeta também a criação de obrigações pelo escolar. As consultas usam jsonb_agg sem paginação nos fluxos lidos.

RF-M17-02/03 têm incompatibilidades identificadas. RF-M17-04 exige confirmar quem grava cash_flow_entries; consultar a tabela não demonstra que todos os movimentos do negócio a alimentam. O teste decisivo é contra o esquema real reconstruído, não apenas mock. Fonte: financeiro/handlers/financeiro.go e shared/adapters/financial.go.

### M18 — Tesouraria

CriarMovimento usa transação, atualização do saldo e RowsAffected==1, uma proteção concreta contra conta externa/inativa. A reconciliação calcula saldo a partir do inicial e movimentos até ao fim do período. Falta homologar a política de períodos, correções e movimentos retroativos.

RF-M18-01 a 04: evidência parcial. AP-17 pode deixar a tesouraria sem movimento de um pagamento escolar apesar de a rotina local ser atómica. Testar o fluxo da origem à tesouraria, moeda, saldo inicial e restauro. Fonte: tesouraria/handlers/tesouraria.go e adaptador treasury.go.

### M19 — Contabilidade

Há plano de contas, diários, lançamentos, períodos, fecho, ativos, amortização e relatórios. journal_entries.go valida débito XOR crédito, equilíbrio e contas do tenant, e bloqueia a sequência. O módulo tem implementação significativa, mas o inventário não encontrou ficheiros de teste próprios.

RF-M19-01 a 06: evidência parcial; RF-M19-04 é afetado por AP-17 nas integrações. Testar período fechado, estorno, duas publicações concorrentes, repetição de evento e arredondamento. Separar sucesso do documento comercial de lançamento pendente. Fontes: contabilidade/handlers e shared/adapters/accounting.go.

### M20 — Impostos

Há regimes, isenções, retenções, declarações e certificados. A baseline contém triggers de imutabilidade das declarações/linhas, uma defesa concreta. CriarIsencao resolve o imposto no tenant, mas a seleção lida não resolve a entidade polimórfica customer/supplier/product/category no seu proprietário.

RF-M20-01 a 04: evidência parcial. Validar entidade, vigência e aplicação ao documento, não apenas criação da isenção. SubmeterDeclaracao deve ser interpretado conforme a implementação e contrato aprovados; não foi demonstrada transmissão à autoridade fiscal. Fontes: impostos.go, uploads.go e triggers da baseline.

### M21 — Multi-moeda

Há catálogo global, taxas por tenant, moedas habilitadas e conversão. AP-14/15 são falhas nos invariantes; a API também trata zero casas decimais como campo omitido.

RF-M21-01 a 03 requerem correção; RF-M21-04 continua pendente de verificar nos consumidores se taxa/valores históricos são conservados. Testar taxa futura, ausência de taxa, troca concorrente de base e conversão histórica. Fonte: multi_moeda.go.

### M22 — Centros de custo

Há centros, alocações, orçamento e comparação. AP-13 quebra a consistência tenant→centro. Um allocation_percent individual entre 0 e 100 não impede que várias alocações da mesma origem ultrapassem o total.

RF-M22-02/03 têm validação insuficiente identificada; RF-M22-04 requer homologar período e moeda. A consulta lida soma valores de alocações com base nas suas datas e deve explicitar qual data económica é usada. Testar distribuição total, duplicação, centro externo e múltiplas moedas. Fontes: allocations.go, budgets.go e cost_centers.go.

### M23 — Pessoas

O módulo próprio expõe principalmente consulta bidirecional das relações ativas por tenant. Identidade, vínculos e relações são também tratados por código partilhado e outros módulos. Não há evidência suficiente para dizer que existe um CRUD completo de relações ou fusão de duplicados neste módulo.

RF-M23-02: evidência parcial direta. RF-M23-01/03 dependem dos consumidores; RF-M23-04 permanece proposta/pending de especificação. Homologar fim da relação e retirada do acesso do encarregado. Fontes: pessoas/handlers/relacoes.go e internal/shared/pessoas.

### M24 — RH

Há cadastro, contratos, documentos, horários, regras, eventos, justificações, férias, salário, formação, avaliação e biometria. O serviço de assiduidade possui testes e lógica de emparelhamento. O resolvedor de regras explicita que equipa/turno/contrato não têm associação direta no modelo atual e não simula esses níveis.

RF-M24-01 a 09: evidência parcial. AP-05 pode afetar saldos de ausência através de aprovação repetida. Testar dia que cruza meia-noite, entrada duplicada, fim sem início, marcação offline tardia, férias concorrentes e salário com efeitos de tesouraria. A política biométrica precisa de aceitação funcional própria. Fontes: RH handlers, service/assiduidade e service/funcionario.

### M25 — Recrutamento

Há vagas, candidatura, CV, mensagens, portal, campos e contratação. ContratarCandidato bloqueia a candidatura com FOR UPDATE OF c, valida estado aprovado e consentimento e cria vínculos relacionados. É um exemplo positivo de decisão dentro da transação.

RF-M25-01 a 05: evidência parcial. Cópias para armazenamento não participam na transação PostgreSQL; validar compensação e ficheiros órfãos se um passo posterior falhar. Homologar duas contratações, vagas simultâneas e preservação da identidade existente. Fontes: contratar.go, candidaturas.go e candidato_portal.go. Inventário: sem testes próprios no módulo.

### M26 — Self-service

Há perfil, recibos, assiduidade, pedidos, comunicados, biometria e chat. O lote offline tem validação temporal, elegibilidade e idempotência, com testes próprios. O chat depende do hub global e conserva as falhas de isolamento/concorrência da análise inicial.

RF-M26-01 a 05: evidência parcial; RF-M26-06 não cumpre os critérios de isolamento/confiabilidade identificados. Validar mudança de utilizador com eventos pendentes, reenvio após interrupção e revisão de inferência entrada/saída tardia. Fonte: self-service/handlers e internal/ws.

### M27 — Escolar

É um dos maiores módulos, com serviços/repositórios e testes de áreas académicas. AP-06/09/10/11/17/20 afetam descontos, matrícula, notas e integração financeira. Validações de serviço não substituem o alinhamento entre repositório e esquema.

RF-M27-02/03/05 têm falhas específicas. Os restantes são parciais ou pendentes de homologação do processo. Testar aluno de outra turma, item de avaliação de outra disciplina, encarregado com relação terminada, matrícula concorrente na última vaga e pagamentos parciais em sequência. Fonte: gestao-escolar/handlers, services e repositories.

### M28 — Aprovações

Há fluxos, pedidos, pendências por cargo, decisões e assinatura. AP-05/06/20 mostram que a existência de um pedido não garante que a autorização e o efeito final são corretos. Consultas de cargo usam user_id/tenant e não necessariamente a membership selecionada ou ativa.

RF-M28-03 exige correção; RF-M28-01/02/04 são parciais. Validar fluxo alterado depois de aberto, cargo retirado e decisão concorrente. Definir se o fluxo deve ter uma versão congelada por pedido. Fontes: requests.go, flows.go e shared/adapters/approval.go.

### M29 — Tarefas

Há quadros, listas e cartões com filtros de tenant e permissões no router. CriarCartao calcula MAX(posicao)+1 sem reserva; chamadas concorrentes podem escolher a mesma posição. MoverCartao valida tenant da lista, mas não foi homologada uma regra de participação por quadro.

RF-M29-01 a 04: evidência parcial. ReordenarListas ignora erros/linhas afetadas por item e não vincula todos os IDs a um único quadro. Testar lote com lista inexistente, listas de quadros diferentes e ordenação concorrente; definir se ordenação única é exigida. Fontes: tarefas/handlers e router:3026.

### M30 — Notificações

Há canais/templates, fila, reprocessamento e push. O dispatcher usa reserva atómica com SKIP LOCKED e há testes, uma proteção concreta para múltiplos workers. AP-07 bloqueia o cadastro de canal no esquema consultado, mas não demonstra que todo envio falha: SES/SMS também usam configuração de processo.

RF-M30-01 tem bloqueio identificado; RF-M30-02 a 04 são parciais. Enfileirado, tentado, aceite pelo fornecedor e entregue não são o mesmo estado. Falha após envio mas antes de marcar entregue pode repetir mensagem; acordar a garantia possível por fornecedor. Fontes: notificacoes.go, background/jobs.go e push/push.go.

### M31 — Assinatura digital

Há documentos, signatários, convites/OTP, assinatura, versões, evidências, verificação e callbacks. FKs compostas e proteção de evidências são superiores ao padrão de referência simples encontrado em AP-12/13. O inventário de testes é mais concentrado neste módulo.

RF-M31-01 a 06: evidência parcial, sem declarar conformidade jurídica. Candidatos lexicais de campos ausentes precisam de considerar migrations de estabilização com vários ADD COLUMN; não são automaticamente defeitos. Homologar provedor real, expiração, duas assinaturas concorrentes, perda de TSA e recuperação. Fonte: assinatura-digital handlers/pki e migrations específicas.

### M32 — Assinaturas comerciais

Há planos, subscrições, renovação, cancelamento, faturas e utilização. AP-12 permite referência externa. RenovarAssinatura ignora o erro do JSON e força activa; um corpo inválido pode reativar subscrição sem alteração de datas.

RF-M32-02 tem falha de referência; RF-M32-03 precisa de validação de estado/input. RF-M32-04 consulta registos, mas não prova faturação recorrente ou medição automática completa. Testar plano externo/inativo, cancelamento, renovação com JSON inválido e efeitos da vigência na habilitação. Fonte: assinaturas/handlers/assinaturas.go.

### M33 — Hardware

Há normalização, eventos, credenciais, MQTT, retry e processamento. processor.go grava event_hash com ON CONFLICT e conserva payload normalizado, distingue falha permanente de transitória e possui testes. A rota de app por JWT pertence a Self-service, não à autenticação de device.

RF-M33-01 a 05: evidência parcial. A gravação do bruto, o efeito de assiduidade e o estado processado devem ser testados juntos sob interrupção/replay; deduplicar a inserção inicial não prova sozinho que o efeito derivado ocorre exatamente uma vez. Fonte: hardware/service/processor.go, adapters, handlers e middleware/device_auth.go.

## 6. Plano de verificação e correção

### Ordem técnica recomendada

1. **Reprodutibilidade:** definir bootstrap/upgrade e levantar um PostgreSQL descartável; comparar esquema real ao versionado. Corrigir AP-02/07/08/09/10/11 antes de avaliar sucesso funcional desses fluxos.
2. **Autorização:** resolver AP-01, referências externas AP-12/13, atalhos AP-19/20 e os problemas iniciais de chat, callbacks e passwords.
3. **Integridade de processo:** corrigir emissão prematura AP-03, decisão escolar AP-06 e efeitos pós-commit AP-17.
4. **Concorrência:** bloquear/reservar saldos e decisões AP-04/05; exercitar hub WebSocket, sequência, alocação e revogação.
5. **Regras e operação:** AP-14/15/16/18, reconciliação, worker, observabilidade e aceitação dos processos restantes.

Não há estimativa de dias ou custo nesta revisão. O resultado e dependências de cada etapa devem orientar a estimativa e a seleção dos módulos da primeira entrega.

### Cenários mínimos que acrescentam evidência real

| Cenário | Preparação | Resultado exigido |
|---|---|---|
| V-01 — Base vazia | Instalar sem backup ou ajustes manuais. | O caminho documentado cria o esquema completo e deixa a versão correta. |
| V-02 — Upgrade | Usar cópia de uma versão anterior numa base isolada. | Atualiza sem perda e produz contrato equivalente ao arranque novo. |
| V-03 — Tenant A/B | Mesmo utilizador com dois vínculos; permissões diferentes. | Permissão em A não vale em B; alterar A não apaga B. |
| V-04 — Financeiro | Obrigação de 100, pagamentos 40 e 60. | Saldo 60 e depois 0, estados válidos e registos conciliados; excesso/reenvio são controlados. |
| V-05 — Compra completa | Documento com três itens. | Edição completa antes de emitir; totais e lançamento correspondem a todos os itens. |
| V-06 — Corrida de receção | Duas sessões recebem 7 de uma ordem de 10. | Apenas uma reserva incompatível é aceite; acumulado nunca passa 10. |
| V-07 — Decisão concorrente | Aprovar/rejeitar o mesmo nível em paralelo. | Uma transição válida e um resultado explicável; saldo de férias não é duplicado. |
| V-08 — Desconto escolar | Fluxo obrigatório e decisão favorável. | Pedido aprovado e desconto aplicado; erro de consulta do fluxo não aplica direto. |
| V-09 — Integrações a falhar | Falhar contabilidade/tesouraria depois do registo de origem. | Rollback ou pendência persistida recuperável; nenhuma falha financeira apenas oculta em log. |
| V-10 — Referências externas | Plano, centro, empresa e aluno do tenant B enviados em A. | Rejeição sem criar relações cruzadas. |
| V-11 — Câmbio | Taxas de ontem e amanhã; troca de moeda base em paralelo. | Taxa elegível e exatamente uma base segundo política aprovada. |
| V-12 — Logística | Eventos “não entregue” e saída tardia depois da entrega. | Estado segue código/transição, não fragmentos do texto livre. |
| V-13 — Falha de banco | Begin/Query/Commit falham nos fluxos críticos. | Erro correto, sem sucesso fictício ou uso de tx/rows inválidos. |

Para estes cenários usar massa fictícia, nunca o DSN remoto incorporado na configuração. Os testes com mocks continuam úteis para regras e respostas, mas os cenários V-01/02/04/06/07 precisam de PostgreSQL real e ligações independentes para comprovar contratos e concorrência.

## 7. Requisitos e estado de aceitação

O catálogo de 157 requisitos continua uma proposta. Esta análise não os converte em requisitos aprovados. Onde há falha direta, foi indicado o ID afetado; nos restantes, “evidência parcial” significa que falta demonstrar pelo menos algum critério ou a composição do processo.

Cada requisito deve receber na homologação um dos estados: não iniciado, implementação parcial, implementação verificada tecnicamente, homologado pelo negócio ou bloqueado por defeito identificado. Não usar “implementado” para um handler cuja query não corresponde à migration, nem “não existe” para uma função que é chamada indiretamente por um serviço.

Entregáveis desta revisão: este relatório; inventário/candidatos em docs/audit-backend-contracts.json; verificador reproduzível em docs/tools/audit_backend_contracts.py. A análise inicial continua válida para os achados ali descritos e deve ser lida em conjunto. Nenhuma alteração funcional foi feita no backend.
