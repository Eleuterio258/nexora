# WaterDoor
### Plataforma de Gestão de Distribuição e Entregas — Descrição Completa do Produto

---

## 1. O que é o WaterDoor

O **WaterDoor** é uma plataforma digital completa para **empresas de distribuição e entrega de produtos de reabastecimento recorrente** — água engarrafada, garrafões, gás doméstico e afins — que substitui o controlo manual em papel e Excel por um sistema em tempo real, pensado para a realidade operacional de Moçambique, incluindo zonas com conectividade instável.

É composto por três frentes integradas:

- **App mobile** para gestão, operação de balcão e entregadores em rota;
- **Dashboard web** para administração, relatórios e gestão de topo;
- **Backend multi-tenant** que serve como fonte única de verdade para todas as empresas clientes.

Foi desenhado para **crescer com o negócio do cliente**: começa numa única filial e escala para múltiplas filiais, múltiplas equipas e, no limite, para servir várias empresas distintas na mesma plataforma (modelo multi-empresa / multi-tenant, com isolamento total de dados entre empresas).

---

## 2. O problema que resolve

Empresas de distribuição enfrentam hoje, tipicamente:

- Pedidos e entregas geridos por telefone e papel, sem histórico central;
- Falta de visibilidade sobre onde estão os motoristas e o estado das entregas;
- Dificuldade em controlar stock de garrafões/produtos entre armazém e filiais;
- Recibos e facturação manuais, sujeitos a erro e sem rastreabilidade;
- Nenhuma forma simples de medir desempenho de motoristas ou de filiais;
- Perda de operação quando a internet falha em campo;
- Dificuldade em cobrar garrafões/vasilhames não devolvidos pelos clientes.

**O WaterDoor resolve todos estes pontos com uma única plataforma**, usada por toda a equipa — desde a gestão de topo até ao motorista em rota.

---

## 3. Como está organizado

O sistema segue a estrutura real de uma empresa de distribuição, com um perfil de acesso próprio para cada função, cada um vendo apenas o que precisa ver:

| Perfil | Quem é | O que faz no sistema |
|---|---|---|
| **Super Admin** | Equipa da plataforma (E258TECH) | Gere todas as empresas clientes, planos de subscrição, utilizadores globais e saúde do sistema |
| **Admin da Empresa** (Tenant Admin) | Dono/gestor da empresa | Visão global do negócio, gere filiais, frota, preços, planos e configurações da empresa; consulta relatórios consolidados de todas as filiais |
| **Gestor de Filial** (Branch Admin) | Responsável por uma filial/armazém | Administra dados, equipa, stock, preços locais e desempenho da sua filial |
| **Operador** | Rececionista/despacho na filial | Regista pedidos, gere clientes, atribui rotas a entregadores, controla stock e faz fecho de caixa do turno |
| **Entregador** | Motorista | Recebe rota, navega até ao cliente, confirma entregas, recolhe assinatura e reporta incidências |
| **Cliente** *(opcional)* | Cliente final | Faz pedidos, acompanha entrega em curso, consulta histórico e assina digitalmente na receção |

Esta separação simplifica a experiência de cada utilizador e protege informação sensível do negócio — o motorista não acede a relatórios financeiros, o operador não configura planos de subscrição, etc.

---

## 4. Principais funcionalidades

### 📊 Painéis de Gestão (Dashboards)
Cada perfil tem o seu próprio painel com indicadores relevantes em tempo real: vendas do dia, pedidos pendentes, galões em rua, stock disponível, desempenho de motoristas e actividade recente da empresa.

### 🧾 Gestão de Pedidos
Criação de pedido completo ou pedido rápido, filtros por estado (pendente, em rota, entregue, cancelado), atribuição de entregadores, confirmação e cancelamento, impressão de recibo — tudo a partir de um único ecrã.

### 👥 Gestão de Clientes
Registo de clientes com segmentação (activos, inactivos, devedores, comercial/residencial), histórico de pedidos e consumo, ticket médio, e atalho para criar pedido rápido a partir da ficha do cliente.

### 🍶 Controlo de Galões e Vasilhames
Controlo de garrafões não devolvidos por cliente, valor em risco, marcação de devolução e cobrança do valor do vasilhame — uma dor específica do sector que folhas de Excel não resolvem bem.

### 🚚 Gestão de Entregas e Frota
Atribuição de rotas a entregadores, cálculo de carga e alerta de sobrecarga do veículo, gestão de frota (viaturas atribuídas a filiais e a entregadores) e mapa de entregas em tempo real.

### 📍 Rastreamento em Tempo Real (GPS)
A gestão acompanha, no mapa, a localização de cada motorista e o progresso das entregas em curso; o entregador tem navegação guiada até ao cliente.

### 📦 Controlo de Stock
Stock por filial e por produto (ex.: garrafões 20L/10L, botijas de gás), entrada e ajuste de inventário, transferência de stock entre filiais, alertas de reposição e agenda de reabastecimento.

### 💳 Facturação, Recibos e Pagamentos
Emissão de recibo/factura com impressão via Bluetooth directamente no terreno (suporte a impressoras térmicas ESC/POS, rolo 58/80mm e A4), preços por filial ou globais, fecho de caixa por turno, relatórios de devedores e pagamento de planos de subscrição via M-Pesa.

### 📴 Funciona Offline
As operações de campo — registo de entregas, actualização de estado, emissão de recibos — continuam a funcionar sem internet e sincronizam automaticamente quando a ligação é restabelecida. Essencial para zonas de cobertura instável, que são a norma e não a excepção em muitas áreas de operação.

### 🔔 Notificações
Alertas em tempo real (push e, por empresa, via WhatsApp) para novos pedidos, entregas atribuídas, stock baixo, clientes que se tornaram devedores e outras situações que exigem acção imediata.

### 📈 Relatórios
Relatórios de vendas e receita, controlo de galões, desempenho de entregadores, clientes devedores e movimentação de stock — com filtros por período, exportação e agendamento de envio automático por e-mail.

### 🏢 Multi-Filial e Multi-Empresa
Uma empresa pode gerir múltiplas filiais a partir de uma única conta, cada uma com a sua equipa, stock e desempenho próprios. A plataforma suporta também várias empresas clientes em simultâneo, cada uma com os seus dados totalmente isolados e o seu próprio plano de subscrição.

---

## 5. Benefícios para o negócio

- **Visibilidade total** da operação, do armazém à porta do cliente;
- **Menos perdas** de stock, de vasilhames e menos erros de cobrança;
- **Motoristas mais eficientes**, com rotas e navegação guiada;
- **Decisões mais rápidas**, apoiadas em dados reais e não em estimativas;
- **Operação contínua**, mesmo com internet instável no terreno;
- **Escalável**: cresce de uma filial para uma rede de filiais sem trocar de sistema;
- **Imagem profissional** perante clientes, com recibos e atendimento padronizados.

---

## 6. Segurança e Confiabilidade

- Autenticação individual por utilizador (JWT), com permissões específicas por perfil e expiração de sessão;
- Isolamento estrito de dados entre empresas (multi-tenant) e entre filiais da mesma empresa;
- Passwords protegidas com encriptação (bcrypt);
- Comunicação cifrada (HTTPS/TLS) em todas as ligações à plataforma;
- Registo de auditoria das acções relevantes da equipa de gestão;
- Sincronização automática e segura entre o que acontece em campo e o sistema central;
- Backup automático da base de dados.

---

## 7. Modelo comercial

O WaterDoor funciona por subscrição (SaaS), com planos comerciais que podem ser atribuídos por empresa e activados/renovados directamente na plataforma, incluindo pagamento por M-Pesa. Cada empresa cliente opera de forma totalmente independente, sem qualquer visibilidade sobre dados de outras empresas na mesma plataforma.

---

## 8. Próximos passos para adopção

1. Validação da lista de filiais, equipas e produtos a configurar;
2. Configuração inicial da conta da empresa e das filiais;
3. Formação rápida das equipas por perfil (Admin, Gestor, Operador, Entregador);
4. Acompanhamento nas primeiras semanas de uso em produção.

---

*WaterDoor — Gestão de Distribuição e Entregas com Eficiência*

**E258TECH**
Maputo — Moçambique
info@e258tech.tech | +258 87 075 5700
