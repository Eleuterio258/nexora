# ERP Mobile — Prioridade dos Módulos

## 1. Objectivo

Definir a ordem de implementação dos módulos do ERP Mobile, com base em **valor de negócio**, **frequência de uso em contexto móvel**, **complexidade técnica** e **dependências** no backend Nexora ERP.

---

## 2. Critérios de priorização

| Critério | Peso | Descrição |
|---|---|---|
| **Valor de negócio** | 30% | Quanto o módulo aumenta a produtividade ou resolve uma dor real fora do escritório. |
| **Frequência mobile** | 25% | Quantas vezes o utilizador precisa desta funcionalidade no telemóvel. |
| **Facilidade de implementação** | 20% | Quão simples é reaproveitar endpoints existentes e criar telas mobile. |
| **Base de utilizadores afectada** | 15% | Quantos utilizadores (gestores, colaboradores) se beneficiam. |
| **Dependências** | 10% | Quanto depende de outros módulos ou de funcionalidades ainda não existentes. |

---

## 3. Matriz de prioridade

| # | Módulo | Valor negócio | Freq. mobile | Facilidade | Base users | Dependências | Score | Prioridade |
|---|--------|:-----------:|:------------:|:----------:|:----------:|:------------:|:-----:|:----------:|
| 1 | **Aprovações** | 10 | 10 | 9 | 8 | 3 | **9,15** | 🔴 Alta |
| 2 | **Notificações Push** | 9 | 10 | 8 | 10 | 5 | **8,95** | 🔴 Alta |
| 3 | **Tarefas** | 9 | 9 | 9 | 9 | 4 | **8,90** | 🔴 Alta |
| 4 | **RH Self-service** | 9 | 8 | 7 | 10 | 5 | **8,45** | 🔴 Alta |
| 5 | **Dashboard** | 8 | 10 | 8 | 10 | 6 | **8,60** | 🟡 Média-Alta |
| 6 | **CRM** | 7 | 7 | 7 | 6 | 5 | **6,95** | 🟡 Média |
| 7 | **Compras** | 6 | 6 | 6 | 5 | 6 | **5,95** | 🟡 Média |
| 8 | **Stock** | 5 | 5 | 6 | 4 | 5 | **5,20** | 🟢 Baixa |
| 9 | **Faturação** | 5 | 4 | 5 | 4 | 7 | **4,85** | 🟢 Baixa |
| 10 | **Contabilidade** | 3 | 2 | 4 | 3 | 6 | **3,35** | ⚪ Muito baixa |

> **Nota:** Score calculado com os pesos definidos. Escala de 0 a 10 por critério.

---

## 4. Descrição por módulo

### 4.1 Aprovações — Prioridade 🔴 Alta

**Porquê primeiro:**
- Gestores frequentemente precisam de aprovar férias, despesas, requisições fora do horário/escritório.
- Alto impacto imediato na produtividade.
- Endpoints já existem em `/api/aprovacoes`.

**Funcionalidades MVP:**
- Listar pedidos pendentes.
- Aprovar/rejeitar com comentário.
- Filtros por tipo (férias, despesas, requisições).

**Complexidade:** Baixa. Reaproveita `aprovacoes.go`.

---

### 4.2 Notificações Push — Prioridade 🔴 Alta

**Porquê primeiro:**
- Habilita todo o valor de aprovações, tarefas e RH.
- Sem push, o utilizador não sabe que precisa abrir o app.
- Backend já tem Firebase (`internal/push`).

**Funcionalidades MVP:**
- Registar token FCM por dispositivo.
- Enviar push para novas aprovações pendentes.
- Enviar push para tarefas atribuídas.
- Deep link para abrir o ecrã correcto.

**Complexidade:** Média. Generalizar endpoint existente de candidatos.

---

### 4.3 Tarefas — Prioridade 🔴 Alta

**Porquê primeiro:**
- Uso frequente em movimento.
- Simples de implementar.
- Utilizado por gestores e equipas.

**Funcionalidades MVP:**
- Listar minhas tarefas (pendentes, em curso, concluídas).
- Actualizar estado.
- Adicionar comentário rápido.

**Complexidade:** Baixa. Reaproveita `/api/tarefas`.

---

### 4.4 RH Self-service — Prioridade 🔴 Alta

**Porquê primeiro:**
- Todos os colaboradores se beneficiam.
- Consulta de presenças, recibos, pedidos de férias são casos de uso naturais no telemóvel.
- Integra com FaceClock para registo de ponto.

**Funcionalidades MVP:**
- Consultar presenças do mês.
- Pedir férias.
- Consultar recibos (PDF).
- Justificar atrasos/faltas.

**Complexidade:** Média. Reaproveita `/api/self-service` e `/api/rh`.

---

### 4.5 Dashboard — Prioridade 🟡 Média-Alta

**Porquê:**
- É a primeira tela do app.
- Agrega dados de outros módulos (tarefas, aprovações, notificações).
- Dá visibilidade imediata do que precisa de atenção.

**Funcionalidades MVP:**
- Resumo de aprovações pendentes.
- Resumo de tarefas pendentes.
- Notificações não lidas.
- Atalhos rápidos.

**Complexidade:** Média. Requer endpoint agregado novo (`/api/v1/mobile/dashboard`).

---

### 4.6 CRM — Prioridade 🟡 Média

**Porquê:**
- Útil para comerciais e gestores acompanharem leads/oportunidades.
- Menos frequente que aprovações/tarefas para a maioria dos utilizadores.

**Funcionalidades MVP:**
- Listar leads/oportunidades.
- Visualizar detalhes.
- Registar actividade (chamada, reunião).

**Complexidade:** Média. Reaproveita `/api/crm`.

---

### 4.7 Compras — Prioridade 🟡 Média

**Porquê:**
- Aprovações de requisições são um sub-conjunto de "Aprovações".
- Criar requisições no mobile tem valor, mas é menos frequente.

**Funcionalidades MVP:**
- Listar requisições.
- Aprovar/rejeitar requisições.
- Criar requisição simples.

**Complexidade:** Média. Reaproveita `/api/compras`.

---

### 4.8 Stock — Prioridade 🟢 Baixa

**Porquê:**
- Útil para armazenistas/lojas.
- Menos relevante para utilizadores de escritório.

**Funcionalidades MVP:**
- Consulta de stock por artigo.
- Registo rápido de contagem/inventário.

**Complexidade:** Média. Reaproveita `/api/stock`.

---

### 4.9 Faturação — Prioridade 🟢 Baixa

**Porquê:**
- Criar facturas no telemóvel é possível, mas raramente é necessário.
- Consulta de facturas já pode ser coberta por dashboards/relatórios.

**Funcionalidades MVP:**
- Listar facturas.
- Consultar estado de pagamento.

**Complexidade:** Média/Alta. Reaproveita `/api/faturacao`.

---

### 4.10 Contabilidade — Prioridade ⚪ Muito baixa

**Porquê:**
- Relatórios contabilísticos exigem ecrãs grandes e detalhe.
- Pouco uso em contexto móvel.

**Funcionalidades futuras (não MVP):**
- Dashboard financeiro resumido.
- Alertas de fechos de período.

**Complexidade:** Alta. Melhor manter no web.

---

## 5. Roadmap sugerido

### Trimestre 1 — Fundação + Alto valor

| Semana | Entregável |
|---|---|
| 1-2 | Auth mobile, escopo `mobile_erp`, registo de dispositivos, push token. |
| 3-4 | Dashboard mobile. |
| 5-7 | Módulo de aprovações. |
| 8-10 | Módulo de tarefas. |
| 11-12 | Notificações push para aprovações e tarefas. |

### Trimestre 2 — RH + CRM

| Semana | Entregável |
|---|---|
| 13-15 | RH self-service: presenças e pedido de férias. |
| 16-18 | Recibos e justificações. |
| 19-21 | Integração com FaceClock para registo de ponto no mobile. |
| 22-24 | CRM básico (leads, oportunidades, actividades). |

### Trimestre 3 — Operações + Refinamento

| Semana | Entregável |
|---|---|
| 25-27 | Compras (requisições e aprovações). |
| 28-30 | Stock básico. |
| 31-33 | Faturação (consulta). |
| 34-36 | Testes, hardening, monitoramento, publicação. |

---

## 6. Recomendação de MVP

O **MVP mínimo viável** do ERP Mobile deve incluir:

1. **Login mobile** com escopo `mobile_erp`.
2. **Dashboard** com resumo de aprovações, tarefas e notificações.
3. **Aprovações** — listar e aprovar/rejeitar.
4. **Tarefas** — listar e actualizar estado.
5. **Notificações push** para aprovações e tarefas.
6. **Perfil do utilizador** e logout.

Com estes 6 itens, o app já entrega valor mensurável a gestores e colaboradores, com esforço controlado.

---

## 7. Conclusão

> **Aprovações, notificações push, tarefas e RH self-service são os módulos de maior prioridade** para o ERP Mobile. Estes módulos têm alto valor de negócio, alta frequência de uso no telemóvel e são tecnicamente acessíveis com o backend actual.
>
> **Contabilidade e faturação devem ficar para fases posteriores**, por serem menos naturais no mobile e mais complexas.
>
> O roadmap sugerido permite ter um **MVP funcional em 12 semanas** e uma suite completa em 36 semanas.
