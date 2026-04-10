# Requisitos — Modulo Sistema e Configuracao

## Requisitos Funcionais

### RF01 — Configuracoes Globais e por Tenant
O sistema deve suportar configuracoes de escopo global (afectam todo o sistema), por tenant e por utilizador.

### RF02 — Gestao de Moedas
O sistema deve manter um catalogo de moedas activas com codigo, nome e simbolo.

### RF03 — Taxas de Cambio
O sistema deve registar taxas de cambio entre moedas por data, permitindo conversao de valores historicos.

### RF04 — Paises e Cidades
O sistema deve manter tabelas de referencia de paises e cidades para uso em moradas de todos os modulos.

### RF05 — Idiomas Suportados
O sistema deve manter o catalogo de idiomas disponiveis para a interface do utilizador.

### RF06 — Templates de Email
O sistema deve gerir templates de email por codigo e por tenant, com assunto e corpo parametrizavel.

### RF07 — Templates de SMS
O sistema deve gerir templates de SMS por codigo e por tenant, com corpo parametrizavel.

### RF08 — Logs do Sistema
O sistema deve registar logs de nivel (info, warning, error) por modulo, para monitorizacao e diagnostico.

### RF09 — Integracoes Externas
O sistema deve gerir as configuracoes de integracoes com servicos externos (pagamentos, email, SMS) por tenant.

### RF10 — Logs de API
O sistema deve registar cada chamada de API com metodo, rota, status code e duracao em milissegundos.

---

## Requisitos Nao Funcionais

### RNF01 — Cache de Configuracoes
Configuracoes globais e por tenant devem ser cacheadas, com invalidacao automatica ao actualizar.

### RNF02 — Imutabilidade de Referencias
Tabelas de referencia (paises, idiomas, moedas) nao devem permitir eliminacao de registos em uso.

### RNF03 — Seguranca de Configuracoes de Integracao
Credenciais de integracoes externas (API keys, tokens) devem ser armazenadas encriptadas no campo configuracao JSONB.

### RNF04 — Retencao de Logs
Logs do sistema devem ser retidos por no minimo 30 dias. Logs de API por no minimo 7 dias.

### RNF05 — Disponibilidade
Este modulo deve estar operacional antes de qualquer outro modulo funcional, pois fornece dados de referencia globais.
