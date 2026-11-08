# 35. Documentação para Parceiros (Partner Documentation)

**Referência:** PAR-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Objectivo
Orientar fornecedores de ERP, biometria, hardware, integração e suporte que necessitem de interoperar com a plataforma, sem expor detalhes internos desnecessários.

## Conteúdo que o parceiro recebe
Contrato de API ou eventos, autenticação, ambientes, limites, códigos de erro, versionamento, contactos, janela de manutenção, dados de teste, processo de certificação e requisitos de segurança. Dados reais de colaboradores e biometria não devem ser usados em testes sem autorização específica.

## Integração ERP
O parceiro deve respeitar tenant, período, versão, chave idempotente, confirmações individuais, retries limitados e reconciliação. Um timeout exige consulta do estado antes de novo envio. Resultados abertos não podem ser tratados como definitivos.

## Integração biométrica
O parceiro deve declarar algoritmo, versão, liveness, critérios de qualidade, taxas medidas, localização de processamento, retenção, subcontratantes, eliminação e resposta a incidentes. O contrato deve permitir suspensão, substituição e eliminação verificável.

## Certificação
A certificação inclui testes de contrato, segurança, isolamento, carga, falhas, idempotência, relógio, privacidade e recuperação. Cada versão aprovada do parceiro deve ser registada. Alterações incompatíveis exigem aviso, ambiente de ensaio e aprovação.

## Suporte e incidentes
Incidentes são comunicados com request/correlation ID, tenant afectado, período, operação e evidência mínima. Nunca devem ser enviados templates, imagens faciais, tokens ou dados pessoais por email ou canais não autorizados.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
