# 24. SLA e Disponibilidade

**Referência:** SLA-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Objectivo de serviço
As metas abaixo são propostas e não constituem compromisso contratual até aprovação: disponibilidade central igual ou superior a 99,5% por mês, visibilidade de marcações até 60 segundos no P95 e relatórios correntes até 30 segundos no P95.

## Medição
Disponibilidade = 100 × (minutos elegíveis − minutos indisponíveis) / minutos elegíveis. Devem ser medidos percursos de negócio completos, não apenas health checks. Manutenção aprovada deve ser identificada separadamente; manutenção excedida e interrupções não planeadas contam como indisponibilidade.

## Classes de serviço
| Classe | Exemplo | RTO/RPO |
|---|---|---|
| Crítica | Recepção de marcações e autorização | A definir |
| Operacional | Backoffice e apuramento | A definir |
| Relatórios | Consultas e exportações | A definir |
| Integração | ERP e notificações | A definir |

## Incidentes e comunicação
A operação deve publicar estado, impacto, início, mitigação e recuperação. Relatórios mensais devem incluir disponibilidade, incidentes, latência, erros, manutenção, capacidade e ações preventivas. RTO, RPO, janela de manutenção e contactos devem ser aprovados no contrato de serviço.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
