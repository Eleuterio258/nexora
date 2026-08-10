# Análise de lacunas — Frontend web `factPro/frontend` vs Backend Go `Nexora ERP`

> **Data:** 2026-08-08  
> **Escopo:** Comparar as funcionalidades expostas pelo backend Go (`D:/projecto/e-258tech/2026/factPro/backend`) com o que está integrado no frontend web PHP (`D:/projecto/e-258tech/2026/factPro/frontend`).

---

## 1. Arquitetura geral do frontend

O frontend é uma aplicação **PHP server-rendered**.

| Camada | Ficheiro / Diretório | Função |
|--------|----------------------|--------|
| Entry-point | `index.php` | Roteia `/admin`, `/nexora`, `/escola`, `/aluno`, `/portal/*`, proxies `/nexora/api/*` |
| Rotas admin | `src/Routing/AdminRoutes.php` | Mapa de páginas administrativas |
| Rotas API proxy | `src/Routing/AdminApiRoutes.php` | Ações nomeadas do proxy `/nexora/api/*` |
| Runtime API | `src/Controller/Admin/AdminApiRuntime.php` | Dispatch do proxy |
| Cliente HTTP | `src/Infrastructure/Nexora/NexoraClient.php` | JWT, refresh automático, chamadas ao backend Go |
| Sessão | `src/Infrastructure/Auth/AdminSession.php` | Sessão PHP, permissões, troca de papel |
| Views | `src/View/templates/pages/*.php` | Páginas server-rendered |
| Assets | `assets/js/script.js` | JS utilitário/toasts |

**Conclusão arquitetural:** A base de autenticação/proxy é razoável, mas as páginas consomem endpoints de forma **esparsa e incompleta**. Muitos endpoints Go documentados no router não têm correspondência nas services ou views.

---

## 2. Funcionalidades já integradas (resumo)

| Área | Grau de integração |
|------|-------------------|
| Login / sessão / permissões | Alto |
| Utilizadores / cargos / permissões | Médio-alto |
| POS básico (venda, sessão, catálogo, terminais) | Médio |
| Faturação (emissão básica) | Médio |
| Clientes / produtos / stock básico | Médio |
| Escola / self-service / tarefas | Parcial |

---

## 3. Lacunas funcionais

### 🔴 Críticas

| # | Área | Lacuna | Impacto | Endpoints backend não usos |
|---|------|--------|---------|---------------------------|
| 1 | **Dashboard** | Só mostra recrutamento; sem KPIs de vendas, POS, faturação, stock, financeiro | Admin perde visão operacional | `/api/pos/relatorios/vendas`, `/api/faturacao/invoices`, `/api/stock/reports/*` |
| 2 | **Descontos POS** | Não existe página/service para gerir descontos autónomos do PDV | Impossível criar regras de desconto no PDV | `GET/POST/PUT/DELETE /api/pos/descontos` |
| 3 | **Pagamentos móveis** | Web POS não inicia nem acompanha pagamentos M-Pesa/eMola | Caixa não pode cobrar via mobile money | `POST /api/pos/pagamentos/iniciar`, `GET /api/pos/pagamentos/{id}/status` |
| 4 | **Fecho / movimentações de caixa** | Sem tela de fecho detalhado, sangria/suprimento, relatório de fecho | Risco de conciliação manual | `/api/pos/sessoes/{id}/fecho`, `/api/pos/sessoes/{id}/movimentacoes`, `/api/pos/relatorios/fecho-caixa` |
| 5 | **Estorno parcial** | Só existe cancelamento total de venda | Devoluções parciais não são suportadas | `POST /api/pos/sales/{id}/estorno-parcial` |
| 6 | **Stock avançado** | Faltam armazéns, localizações, movimentos, transferências, lotes, seriais, alertas | Stock inoperacional para negócio real | `/api/stock/warehouses`, `/api/stock/movements`, `/api/stock/transfers`, `/api/stock/batches`, `/api/stock/serials`, `/api/stock/alerts` |
| 7 | **Licenciamento / tenants** | Não há gestão visual completa de licenças, planos e módulos | Admin não gere licenças | `/api/companies/{id}/licenses`, `/api/superadmin/plans` |

### 🟠 Altas

| # | Área | Lacuna | Endpoints não usados |
|---|------|--------|---------------------|
| 8 | Relatórios POS | Top produtos, cancelamentos, terminais não são consumidos | `GET /api/pos/relatorios/*` |
| 9 | Terminais POS | Só cria/lista; falta ativar/desativar | `POST /api/pos/terminais/{id}/activar`, `/desactivar` |
| 10 | Faturação — consulta/emitir/cancelar | Faltam GETs de listagem/detalhe, emitir fatura, enviar assinatura, cancelar encomenda | `GET /api/faturacao/quotes/{id}`, `POST /api/faturacao/invoices/{id}/emitir`, `POST /api/faturacao/orders/{id}/cancelar` |
| 11 | Clientes avançado | Faltam tags, documentos, notas, descontos, relatórios | `/api/clientes/{id}/tags`, `/documentos`, `/notas`, `/descontos`, `/reports/*` |
| 12 | Produtos avançado | Faltam imagens, códigos de barras, componentes, tags, descontos | `/api/produtos/{id}/imagens`, `/codigos-barras`, `/componentes`, `/descontos` |
| 13 | Auth avançado | Não há TOTP/PIN, forgot-password, reset, OAuth, push tokens, reauth, histórico | `/api/authcode/*`, `/api/auth/forgot-password`, `/api/auth/reset-password`, `/api/auth/reauth`, `/api/auth/historico-login` |
| 14 | Perfil / conta | Faltam preferências, notificações pessoais, dispositivos, security logs | `/api/utilizadores/{id}/preferences`, `/notifications`, `/devices`, `/security-logs` |
| 15 | Notificações | Só envia; não lista mensagens nem marca como lidas | `GET /api/notificacoes/mensagens`, `POST /api/notificacoes/mensagens/{id}/lida` |
| 16 | Segurança | Só cria política/IP; não lista nem gere logs | `GET /api/seguranca/politicas`, `/api/seguranca/ip-allowlist`, `/api/seguranca/logs` |
| 17 | Sistema / configurações | Services têm POST de criação, mas faltam GET/PUT/DELETE | `GET /api/system/settings`, `/api/system/currencies`, `/api/system/exchange-rates` |

### 🟡 Médias

| # | Área | Lacuna |
|---|------|--------|
| 18 | Compras | Faltam receção, devolução, fatura, pagamento |
| 19 | Logística | Listagens e tracking desconectados |
| 20 | Financeiro / Tesouraria | Faltam contas, caixas, movimentos, reconciliações |
| 21 | Contabilidade | Muitos endpoints expostos, pouca integração visual |
| 22 | Impostos | Faltam listar regimes, isenções, retenções, declarações |
| 23 | RH | Faltam presenças, NFC, biometria facial, processos disciplinares |
| 24 | Assinatura digital | Integração visual provavelmente incompleta |
| 25 | Hardware / fingerprint | Backend tem endpoints; frontend não integra |

### 🟢 Baixas / Melhorias

| # | Área | Lacuna |
|---|------|--------|
| 26 | WebSocket / realtime | `/ws/chat` e Socket.IO existem no backend; frontend não usa consistentemente |
| 27 | Portais (candidato/aluno/professor/encarregado) | Algumas funcionalidades podem estar desatualizadas |
| 28 | Aprovações / workflows | Service/controller existem, mas pouco visíveis no menu |

---

## 4. Exemplos concretos de endpoints disponíveis e não consumidos

### POS

```http
GET    /api/pos/sessoes
GET    /api/pos/sessoes/{id}/fecho
GET    /api/pos/sessoes/{id}/movimentacoes
POST   /api/pos/sessoes/{id}/movimentacoes
GET    /api/pos/sales/{id}/estornos
POST   /api/pos/sales/{id}/estorno-parcial
GET    /api/pos/sales/{id}/recibo
POST   /api/pos/pagamentos/iniciar
GET    /api/pos/pagamentos/{gatewayTxnId}/status
GET    /api/pos/sync/download
POST   /api/pos/login-operador
POST   /api/pos/terminais/{id}/activar
POST   /api/pos/terminais/{id}/desactivar
GET    /api/pos/descontos
POST   /api/pos/descontos
PUT    /api/pos/descontos/{id}
DELETE /api/pos/descontos/{id}
GET    /api/pos/relatorios/vendas
GET    /api/pos/relatorios/top-produtos
GET    /api/pos/relatorios/cancelamentos
GET    /api/pos/relatorios/fecho-caixa
GET    /api/pos/relatorios/terminais
```

### Stock

```http
GET /api/stock/warehouses
GET /api/stock/warehouses/{id}/locations
GET /api/stock/items
GET /api/stock/movements
GET /api/stock/adjustments
GET /api/stock/transfers
GET /api/stock/reservations
GET /api/stock/batches
GET /api/stock/serials
GET /api/stock/counts
GET /api/stock/alerts
GET /api/stock/reports/*
```

### Auth / Utilizadores

```http
POST /api/auth/forgot-password
POST /api/auth/reset-password
POST /api/auth/verify-email
POST /api/auth/push-token
POST /api/auth/reauth
GET  /api/auth/historico-login
GET  /api/auth/utilizadores/{id}
GET  /api/auth/utilizadores/{id}/permissoes
GET  /api/utilizadores/{id}/preferences
GET  /api/utilizadores/{id}/settings
GET  /api/utilizadores/{id}/notifications
GET  /api/utilizadores/{id}/devices
GET  /api/utilizadores/{id}/tokens
GET  /api/utilizadores/{id}/security-logs
```

---

## 5. Lacunas técnicas / arquiteturais

| # | Problema | Detalhe | Prioridade |
|---|----------|---------|------------|
| 1 | Loading states inexistentes | Views chamam `$app->nexora->call(...)` diretamente; sem feedback em chamadas lentas | Média |
| 2 | Tratamento de erro inconsistente | Algumas views verificam `status === 200`, outras assumem sucesso; erros 5xx podem causar tela branca | Alta |
| 3 | Proxy limitado a `basename($uri)` | `AdminApiRuntime::dispatch(basename($uri, '.php'))` só permite ações de um segmento; paths compostos como `/nexora/api/pos/terminais` não são suportados | Alta |
| 4 | Validações duplicadas | Services PHP re-validam campos que o backend já valida | Baixa |
| 5 | Sem paginação consistente | Muitas listas usam `limit=200` hardcoded | Média |
| 6 | Sem cache local | Cada renderização refaz chamadas à API | Média |
| 7 | CSRF em writes do proxy | GETs não são protegidos (aceitável); a aplicação depende do cookie de sessão PHP | Média |
| 8 | Ausência de testes automatizados | Não há testes PHP nem E2E | Média |
| 9 | Notificações push / realtime | Backend tem `push` e WS; frontend web não subscreve | Baixa |
| 10 | Códigos 402/403 de licença não tratados | Quando a licença expira, o Go devolve 402/403; frontend não mostra mensagem específica | Alta |

---

## 6. Recomendações prioritárias

1. **Dashboard operacional real** — consolidar KPIs de vendas POS, faturação, stock e financeiro.
2. **Gestão completa de caixa/sessões POS** — fecho detalhado, movimentações e relatórios.
3. **Descontos POS e pagamentos móveis** — essenciais para uso comercial do PDV.
4. **Stock avançado** — armazéns, movimentos, transferências, lotes, seriais e alertas.
5. **Melhorar o proxy API** — suportar paths compostos e normalizar tratamento de erros.
6. **Listagens e consultas (GETs)** — muitos módulos só têm criação (POST) e faltam listagem/detalhe.
7. **Tratamento de licenciamento** — mostrar mensagens claras quando a licença estiver expirada ou suspensa.

---

## 7. Notas

- O backend expõe uma API REST completa; o gap principal está na **cobertura do frontend**.
- A arquitetura PHP server-rendered dificulta experiências ricas (realtime, pagamentos móveis com polling); considere introduzir componentes JS ou migrar gradualmente para uma SPA nas áreas críticas (POS, dashboard, relatórios).
- O proxy `/nexora/api/*` deve ser evoluído para suportar paths REST compostos e não apenas ações nomeadas de um segmento.
