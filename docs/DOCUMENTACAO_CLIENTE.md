# Nexora ERP — Visão Geral de Funcionalidades

## O que é o Nexora ERP

O Nexora ERP é uma plataforma de gestão empresarial multi-empresa (SaaS), pensada para o
contexto moçambicano, que reúne num único sistema tudo o que uma organização precisa para
gerir clientes, vendas, stock, finanças, recursos humanos e — no caso de instituições de
ensino — toda a gestão académica.

Cada organização (tenant) tem o seu próprio espaço isolado dentro da plataforma: os dados
de uma empresa nunca são visíveis a outra, e cada uma pode activar apenas os módulos que
contratou.

---

## Módulos disponíveis

### Comercial e Vendas
- **Gestão de Clientes** — ficha completa de clientes, histórico de interacções.
- **CRM** — funil de vendas, oportunidades, leads.
- **Ponto de Venda (POS)** — vendas ao balcão, emissão de recibos.
- **Faturação** — emissão de facturas, notas de crédito, gestão de documentos fiscais.
- **Assinaturas** — gestão de clientes com planos/subscrições recorrentes.

### Operacional
- **Gestão de Produtos** — catálogo de produtos e serviços.
- **Gestão de Stock** — controlo de inventário e armazém.
- **Compras** — encomendas e relação com fornecedores.
- **Logística** — acompanhamento de entregas e distribuição.
- **Gestão de Tarefas** — organização de trabalho em equipa (estilo quadro Trello).

### Financeiro
- **Contabilidade** — registo e organização contabilística.
- **Tesouraria** — controlo de caixa e movimentos financeiros.
- **Centros de Custo** — imputação de custos por departamento/projecto.
- **Multi-Moeda** — operação em várias moedas.
- **Impostos** — configuração e cálculo de impostos aplicáveis.

### Recursos Humanos e Recrutamento
- **Recursos Humanos** — ficha de funcionários, estrutura hierárquica, histórico.
- **Recrutamento** — publicação de vagas, gestão do funil de candidaturas, entrevistas,
  contratação — com um **portal próprio para candidatos** (ver secção de Portais) e
  **mensagens em tempo real** entre recrutador e candidato.
- **Self-Service do Colaborador** — pedidos de férias e consulta de dados pessoais,
  sem depender do departamento de RH para tarefas simples.
- **Assinatura Digital** — validação e assinatura digital de documentos.

### Gestão Escolar
Módulo dedicado a instituições de ensino, com gestão académica completa (turmas,
disciplinas, horários, avaliações, calendário escolar, incidentes e mérito dos alunos) e
**três portais dedicados**:
- **Portal do Aluno**
- **Portal do Professor**
- **Portal do Encarregado de Educação**

### Plataforma e Administração
- **Notificações** — avisos automáticos por email/push consoante a acção (ex.: nova
  candidatura, mudança de estado de um processo).
- **Auditoria** — registo de quem fez o quê e quando, para efeitos de rastreabilidade.
- **Segurança** — políticas de acesso e protecção de conta.
- **Configurações do Sistema** — parametrização geral da plataforma por organização.
- **Administração da Plataforma (Superadmin)** — gestão de todas as organizações
  clientes, activação de módulos e planos contratados.

---

## Portais dedicados

Além do painel administrativo principal, a plataforma disponibiliza portais próprios,
mais simples e focados, para quem não precisa de acesso ao ERP completo:

| Portal | Para quem |
|---|---|
| Portal do Candidato | Pessoas a candidatar-se a vagas de emprego |
| Portal do Aluno | Alunos de instituições de ensino clientes |
| Portal do Professor | Corpo docente |
| Portal do Encarregado de Educação | Pais/encarregados dos alunos |

Cada portal tem o seu próprio login e mostra apenas a informação relevante para esse
perfil.

---

## Comunicação em tempo real

As conversas entre recrutador e candidato (no módulo de Recrutamento) actualizam-se
instantaneamente nos dois lados — quer o recrutador esteja a responder pelo painel web,
quer o candidato esteja a usar a aplicação móvel, a mensagem aparece de imediato, sem
necessidade de recarregar a página ou a app.

---

## Segurança e controlo de acesso

- **Isolamento total entre organizações** — os dados de cada cliente ficam
  completamente separados dos de outros clientes na mesma plataforma.
- **Permissões por cargo** — cada utilizador só vê e faz o que o seu cargo permite
  (ex.: um recrutador não acede a dados de contabilidade).
- **Registo de auditoria** — todas as acções relevantes ficam registadas, com
  autor e data/hora.
- **Sessões autenticadas com expiração automática** — reduz o risco de acessos
  indevidos em caso de sessão esquecida aberta.
- **Activação de módulos por plano contratado** — cada organização só tem acesso
  aos módulos incluídos no seu plano.

---

## Aplicações disponíveis

- **Painel Web** — gestão completa, para administradores e equipas operacionais.
- **Aplicação Móvel de Recrutamento** — para candidatos pesquisarem vagas,
  candidatarem-se e acompanharem o processo em tempo real.
- **Aplicação de Gestão Escolar** — acesso móvel para a comunidade escolar.
