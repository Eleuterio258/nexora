# Requisitos — Modulo Logistica

## Requisitos Funcionais

### RF01 — Gestao de Motoristas
O sistema deve permitir registar motoristas com nome, telefone e numero de carta de conducao.

### RF02 — Gestao de Viaturas
O sistema deve permitir registar viaturas com matricula, descricao e capacidade de carga.

### RF03 — Rotas de Entrega
O sistema deve suportar a definicao de rotas de entrega com origem e destino.

### RF04 — Estados de Envio
O sistema deve gerir estados de envio configurados por tenant (ex: aguarda recolha, em transito, entregue, devolvido).

### RF05 — Criacao de Envios
O sistema deve permitir criar envios associados a guias de remessa do modulo de faturacao, com atribuicao de rota, motorista e viatura.

### RF06 — Itens do Envio
O sistema deve registar os produtos e quantidades incluidos em cada envio.

### RF07 — Rastreio em Tempo Real
O sistema deve suportar o registo de coordenadas GPS por envio ao longo da rota, com timestamp e descricao de estado.

### RF08 — Log de Eventos de Envio
O sistema deve registar todos os eventos de um envio (criacao, inicio de rota, entrega, devolucao) com descricao e data.

---

## Requisitos Nao Funcionais

### RNF01 — Numero Unico de Envio
O numero de envio deve ser unico por tenant e gerado automaticamente de forma sequencial.

### RNF02 — Rastreio GPS Opcional
O registo de coordenadas GPS e opcional e nao deve bloquear o fluxo de entrega caso o dispositivo nao tenha GPS.

### RNF03 — Desempenho de Rastreio
A consulta do estado actual de um envio deve responder em menos de 300ms.

### RNF04 — Auditoria
Criacao de envios e alteracoes de estado devem gerar registos no modulo de auditoria.

### RNF05 — Integridade com Faturacao
Nao deve ser possivel criar um envio referenciando uma guia de remessa ja associada a outro envio activo.
