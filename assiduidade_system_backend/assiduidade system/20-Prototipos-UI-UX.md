# 20. Protótipos/UI/UX

**Referência:** UX-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Objectivo
Definir a experiência dos utilizadores no backoffice, na aplicação Android e no modo terminal, com foco em marcações rápidas, estados compreensíveis, acessibilidade e prevenção de erros.

## Princípios de interface
A interface deve mostrar sempre o tenant e o âmbito activo, distinguir dados provisórios de definitivos e separar claramente “aceite centralmente”, “guardado localmente” e “rejeitado”. As mensagens não devem revelar dados de terceiros nem expor detalhes biométricos desnecessários.

## Ecrãs prioritários
| Área | Ecrãs mínimos |
|---|---|
| Terminal Android | Selecção do evento, identificação, instruções faciais, resultado, modo offline e contingência |
| Colaborador | Histórico próprio, pedidos de ausência, correcções e estado das decisões |
| RH | Dashboard de pendências, colaboradores, horários, apuramento, fecho e relatórios |
| Aprovação (âmbito hierárquico) | Equipa, ocorrências, pedidos pendentes e decisões; os ecrãs e acções visíveis dependem das permissões do utilizador, não do cargo |
| Administração | Tenant, estrutura, utilizadores, papéis, terminais e configurações |
| Operação | Saúde dos serviços, filas, dispositivos, integrações e alertas |

## Fluxos de UX
A marcação deve exigir o menor número possível de interacções. Após uma falha facial, o terminal deve apresentar alternativa autorizada sem concluir automaticamente uma falta. No modo offline, a confirmação deve indicar que o evento foi guardado localmente e ainda não foi aceite pelo serviço central.

## Acessibilidade e validação
O backoffice deve suportar teclado, foco visível, rótulos para leitor de ecrã, ampliação de texto e estados que não dependam apenas da cor. Protótipos devem ser testados com utilizadores representativos, medindo conclusão, erros, tempo e interpretação dos estados.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
