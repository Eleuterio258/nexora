# 21. Plano de Testes

**Referência:** TST-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Estratégia
A qualidade será verificada por testes unitários, integração, contrato, end-to-end, carga, segurança, acessibilidade, dispositivos, biometria e recuperação. Cada teste deve indicar versão, ambiente, dados, pré-condições, resultado esperado e evidência.

## Níveis e cobertura
| Nível | Cobertura principal |
|---|---|
| Unitário | Regras de horários, tolerâncias, turnos nocturnos, idempotência e transições |
| Integração | Base de dados, filas, identidade, biometria, notificações e ERP |
| Contrato | OpenAPI, eventos, versões e compatibilidade com terminal e ERP |
| E2E | Marcação, offline, correcção, ausência, apuramento, fecho e reabertura |
| Performance | Pico de mudança de turno, relatórios, reconexões e tenants concorrentes |
| Segurança | Isolamento, autorização, replay, rate limit, segredos e vulnerabilidades |
| Biometria | FAR/FRR, liveness, ataques simulados, iluminação e dispositivos aprovados |
| Continuidade | Backup, restore, falha de dependência, perda de resposta e reconciliação |

## Critérios de entrada e saída
A execução exige requisitos aprovados, ambiente conhecido, dados sintéticos ou autorizados e parâmetros definidos. A saída exige evidências dos requisitos essenciais, ausência de defeitos impeditivos e aprovação dos responsáveis de negócio, técnico, dados e operação.

## Cenários obrigatórios
Devem ser cobertos eventos duplicados, respostas perdidas, terminal revogado, autorização offline expirada, período fechado, decisões concorrentes, integração parcial, eliminação pendente, mudança de fuso, feriado local e turno que atravessa a meia-noite.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
