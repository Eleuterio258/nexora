# 25. Manual Técnico

**Referência:** MTEC-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Público e pré-requisitos
Destina-se a desenvolvimento, DevOps, suporte e integração. O leitor deve conhecer HTTP, JSON, autenticação, SQL, filas e os processos de assiduidade.

## Componentes
A solução inclui API, IAM, serviços de marcações, biometria, políticas, apuramento, workflow, fecho, relatórios, auditoria, integração, fila e observabilidade. A configuração e os contratos detalhados encontram-se nos documentos 7 a 19.

## Procedimentos técnicos
O operador deve verificar saúde da API, base de dados, filas, workers, biometria, terminais e ERP antes de alterar componentes. Toda intervenção deve possuir ticket, correlação e registo de auditoria. Dados de produção não devem ser copiados para desenvolvimento sem autorização e tratamento.

## Diagnóstico
Começar pelo `request_id` ou `correlation_id`, confirmar tenant e âmbito, consultar métricas, logs estruturados e estado da mensagem. Em eventos offline, comparar hora de origem, recepção, hash e resposta individual. Em integrações, consultar operação idempotente antes de reenviar.

## Escalação
Falhas de segurança, isolamento, auditoria ou perda potencial de dados são escaladas imediatamente. Falhas funcionais são encaminhadas para RH; falhas de integração para a equipa ERP; falhas de infraestrutura para operação.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
