# 28. Plano de Migração de Dados

**Referência:** MIG-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Objectivo e escopo
Migrar organizações, estrutura, colaboradores, horários, saldos e histórico necessário sem duplicação, perda de evidência ou mistura entre tenants. Templates biométricos só são migrados com autorização específica e compatibilidade técnica comprovada.

## Fases
1. Inventariar fontes, proprietários, campos e qualidade.  
2. Definir mapeamentos, identificadores e fonte de referência.  
3. Limpar duplicados e validar amostras com RH.  
4. Executar migração de ensaio com dados tratados.  
5. Reconciliar contagens, saldos, períodos e relações.  
6. Executar migração final com janela controlada.  
7. Validar aceite e manter plano de rollback.

## Regras
Cada registo recebe tenant, origem, lote e hash. Não se fundem históricos automaticamente. Datas conservam fuso e instante. Eventos antigos não devem alterar períodos fechados sem decisão autorizada.

## Critérios de sucesso
Contagens e totais reconciliados por entidade, ausência de colisões de identificadores, amostra aprovada por RH, testes de acesso sem fuga entre tenants e capacidade de reprocessar o lote sem duplicação.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
