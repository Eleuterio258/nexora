# Requisitos Funcionais — Módulo de Cadastro e Ordenamento Territorial

Formato: checklist por área funcional.  
Prioridade: **Alta (A)**, **Média (M)**, **Baixa (B)**.  
Referência: secção do documento principal.

---

## 1. Estrutura Territorial e Divisão Administrativa

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 1.1 | Suportar hierarquia territorial configurável por projeto | A | §3 |
| 1.2 | Representar a divisão administrativa de Moçambique (zona urbana e rural) | A | §3.1 |
| 1.3 | Permitir estrutura urbana: Província → Cidade/Município → Distrito municipal/urbano → Posto administrativo urbano → Bairro → Quarteirão | A | §3.2 |
| 1.4 | Permitir estrutura rural: Província → Distrito → Posto administrativo → Localidade → Aldeia/Povoação → Comunidade | A | §3.3 |
| 1.5 | Cada divisão deve ter código, nome, tipo, geometria, área, nível hierárquico, entidade responsável, estado, metadados e histórico | A | §3.4 |
| 1.6 | Suportar campo de zona urbana/rural/mista por divisão | A | §3.4 |
| 1.7 | Permitir importação de limites administrativos oficiais (INE, cartografia municipal) | A | §3.4 |
| 1.8 | Visualizar hierarquia completa de uma parcela ou divisão | M | §3.4 |
| 1.9 | Permitir associação de parcela a qualquer nível da hierarquia | A | §3.4 |
| 1.10 | Integração com código do INE quando disponível | M | §3.4 |

---

## 2. Gestão de Projetos Territoriais

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 2.1 | Criar projeto territorial com código, designação, descrição, cliente e entidade responsável | A | §4 |
| 2.2 | Associar projeto a divisão administrativa de referência | A | §4 |
| 2.3 | Definir área de intervenção e sistema de coordenadas | A | §4 |
| 2.4 | Gerir equipa técnica e responsável técnico | A | §4 |
| 2.5 | Controlar estados do projeto: Rascunho → Levantamento → Diagnóstico → Proposta → Em Revisão → Aprovado → Publicado → Em Implementação → Arquivado | A | §4 |
| 2.6 | Associar documentos, camadas GIS, levantamentos e versões do plano ao projeto | A | §4 |
| 2.7 | Suportar diferentes tipos de projeto (PEU, PGU, PPU, PP, levantamento, regularização, etc.) | A | §4 |

---

## 3. Cadastro Territorial

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 3.1 | Cadastrar parcelas com geometria, centroide, área e perímetro automáticos | A | §5, §5.1 |
| 3.2 | Cada parcela deve ter código cadastral único | A | §5.1 |
| 3.3 | Registar número da parcela, talhão, quarteirão/aldeia/povoação/comunidade e divisão administrativa | A | §5.1 |
| 3.4 | Suportar situações: ocupada, desocupada, parcialmente ocupada, em construção, abandonada, em conflito, reservada | A | §5.1 |
| 3.5 | Registar uso atual: habitacional, comercial, serviços, industrial, agrícola, institucional, recreativo, misto, outros | A | §5.1 |
| 3.6 | Registar uso previsto com classificação do plano e parâmetros urbanísticos | A | §5.1 |
| 3.7 | Manter separadas as informações de realidade existente e uso previsto | A | §5.1 |
| 3.8 | Cadastrar lotes associados a parcelas | M | §5 |
| 3.9 | Cadastrar quarteirões, talhões e espaços públicos | M | §5 |
| 3.10 | Cadastrar vias e servidões | M | §5 |
| 3.11 | Registar precisão do levantamento e sistema de coordenadas | A | §5.1 |

---

## 4. Pessoas e Entidades

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 4.1 | Associar parcela a proprietário, ocupante, requerente, empresa, instituição pública, associação ou concessionário | A | §6 |
| 4.2 | Registar dados pessoais com regras específicas de acesso | A | §6 |
| 4.3 | WebGIS público não deve expor automaticamente dados pessoais | A | §6 |
| 4.4 | Registar NUIT (Moçambique) e documento de identificação | A | §6 |
| 4.5 | Controlar vigência das relações parcela-entidade | M | §6 |

---

## 5. Edificações

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 5.1 | Cadastrar edificações associadas a parcelas | A | §7 |
| 5.2 | Permitir múltiplas edificações por parcela | A | §7 |
| 5.3 | Registar área construída, número de pisos, tipo, finalidade, material e estado de conservação | A | §7 |
| 5.4 | Anexar fotografias e coordenadas à edificação | A | §7 |
| 5.5 | Registar data do levantamento | M | §7 |

---

## 6. Levantamentos de Campo

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 6.1 | Aplicação móvel para recolha de dados no terreno | A | §8 |
| 6.2 | O técnico recebe projeto, área atribuída, rota, parcelas, formulários e tarefas | A | §8 |
| 6.3 | Recolha de pontos, linhas, polígonos e coordenadas | A | §8 |
| 6.4 | Recolha de fotografias, vídeos e observações | A | §8 |
| 6.5 | Recolha de informações cadastrais e condições de infraestruturas | A | §8 |
| 6.6 | Funcionamento offline com download prévio de dados | A | §9 |
| 6.7 | Sincronização automática quando houver Internet | A | §9 |
| 6.8 | Controlo de conflitos de sincronização e duplicação | A | §9 |

---

## 7. Integração com Equipamentos e Tecnologias

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 7.1 | Integração com GNSS, GNSS RTK, estação total, GPS portátil e apps móveis | A | §10 |
| 7.2 | Armazenar latitude, longitude, altitude, precisão horizontal/vertical, método, equipamento, operador, data/hora e sistema de referência | A | §10 |
| 7.3 | Integração com drones para fotografias aéreas, ortofotos, MDT, MDS, nuvens de pontos e modelos 3D | M | §11 |
| 7.4 | Registar produtos de drone no projeto e disponibilizar aos técnicos GIS | M | §11 |

---

## 8. Plano de Ordenamento e Zoneamento

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 8.1 | Criar plano digitalmente sobre a base territorial existente | A | §12 |
| 8.2 | Suportar versionamento do plano (ex: Plano 2026 — Versão 1.0, 1.1) | A | §12 |
| 8.3 | Manter histórico de versões anteriores | A | §12 |
| 8.4 | Definir zonas de utilização do território (ZH, ZC, ZS, ZM, ZI, ZA, ZE, ZV, ZT, ZP, ZEX) | A | §13 |
| 8.5 | Cada zona deve ter parâmetros próprios: altura máxima, pisos, ocupação, afastamentos, área mínima, atividades permitidas/condicionadas/proibidas | A | §13 |
| 8.6 | Permitir classificação do plano por parcela | A | §13 |

---

## 9. Análise Espacial e Deteção de Conflitos

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 9.1 | Comparar uso atual vs. uso previsto automaticamente | A | §14 |
| 9.2 | Registar condicionantes territoriais (linhas de água, zonas inundáveis, encostas, áreas protegidas, etc.) | A | §15 |
| 9.3 | Ferramentas de análise: área, perímetro, distância, buffers, interseções, sobreposição, proximidade, densidade | A | §18 |
| 9.4 | Identificar parcelas afetadas e construções em zonas condicionadas | A | §18 |
| 9.5 | Análise de cobertura de equipamentos públicos | M | §18 |
| 9.6 | Motor de validação territorial para deteção automática de conflitos | A | §19 |
| 9.7 | Alertar quando nova construção viola zoneamento ou condicionantes | A | §19 |
| 9.8 | Gerar estatísticas territoriais | M | §18 |

---

## 10. Infraestruturas e Equipamentos Públicos

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 10.1 | Cadastrar rede viária (estradas, ruas, caminhos, pontes, interseções, passeios) | A | §16 |
| 10.2 | Cadastrar infraestruturas de água | A | §16 |
| 10.3 | Cadastrar saneamento e drenagem | A | §16 |
| 10.4 | Cadastrar energia (postes, transformadores, linhas, subestações) | A | §16 |
| 10.5 | Cadastrar telecomunicações (torres, fibra, caixas) | M | §16 |
| 10.6 | Cadastrar equipamentos públicos (escolas, hospitais, centros de saúde, mercados, esquadras, bombeiros, etc.) | A | §17 |
| 10.7 | Analisar cobertura dos serviços existentes | M | §17 |

---

## 11. GIS, GeoServer e WebGIS

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 11.1 | Integração com QGIS para trabalhos GIS avançados | A | §20 |
| 11.2 | QGIS deve ler e editar dados autorizados do PostGIS | A | §20 |
| 11.3 | Publicar serviços WMS, WFS e WMTS via GeoServer | A | §21 |
| 11.4 | WebGIS técnico com acesso completo conforme permissões | A | §22 |
| 11.5 | WebGIS público com informação autorizada | A | §22 |
| 11.6 | Funcionalidades do WebGIS: visualizar camadas, pesquisar, medir, consultar atributos, imprimir, comparar | A | §22 |
| 11.7 | Catálogo central de camadas com metadados, responsável, fonte, data, sistema de coordenadas e versão | A | §23 |

---

## 12. Importação, Exportação e Documentos

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 12.1 | Importar GeoJSON, GeoPackage, GeoTIFF, COG, KML/KMZ, CSV, Shapefile, DXF/DWG e XLSX | A | §24 |
| 12.2 | Exportar nos mesmos formatos | A | §24 |
| 12.3 | Associar documentos a parcelas, edificações, projetos e planos | A | §25 |
| 12.4 | Suportar armazenamento de objetos para ficheiros grandes (ortofotos, imagens) | A | §25 |
| 12.5 | Manter no PostGIS apenas referências e metadados dos ficheiros grandes | A | §25 |

---

## 13. Workflow, Versionamento e Auditoria

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 13.1 | Workflow de aprovação: Rascunho → Submetido → Em análise → Correção solicitada → Aprovado/Rejeitado → Publicado | A | §26 |
| 13.2 | Alterações importantes não entram diretamente na versão oficial | A | §26 |
| 13.3 | Guardar geometria anterior e nova no versionamento | A | §27 |
| 13.4 | Registar utilizador, data, motivo, projeto e aprovação na alteração | A | §27 |
| 13.5 | Reconstruir situação territorial de uma determinada data | A | §27 |
| 13.6 | Auditoria de operações críticas com logs detalhados | A | §28 |
| 13.7 | Registar alterações de geometria como operação específica de auditoria | A | §28 |

---

## 14. Utilizadores, Perfis e Segurança

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 14.1 | Perfis: Administrador, Gestor do Plano, Planeador Territorial, Técnico GIS, Topógrafo, Técnico de Campo, Fiscal, Consulta | A | §29 |
| 14.2 | Permissões configuráveis por funcionalidade e operação | A | §29 |
| 14.3 | Autenticação segura com JWT/OAuth2 | A | §35 |
| 14.4 | Controlo de acesso baseado em permissões | A | §35 |
| 14.5 | Separação de organizações/projetos (multi-tenant) | A | §35, §36 |
| 14.6 | HTTPS, backups, encriptação e proteção de dados pessoais | A | §35 |
| 14.7 | Restrição de acesso direto à base de dados | A | §35 |

---

## 15. Dashboard, Relatórios e Pesquisa

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 15.1 | Dashboard com indicadores territoriais (área total, parcelas, construções, vias, infraestruturas, conflitos, etc.) | M | §30 |
| 15.2 | Produzir ficha cadastral, ficha de parcela, plantas, mapas e relatórios | A | §31 |
| 15.3 | Relatório de levantamento, conflitos, estatístico e evolução territorial | M | §31 |
| 15.4 | Pesquisa por código de parcela, coordenada, proprietário, divisão administrativa, projeto, tipo de utilização, zona e endereço | A | §32 |
| 15.5 | Pesquisa por seleção direta no mapa | A | §32 |

---

## 16. Fiscalização e Monitorização

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 16.1 | App de campo para fiscalização territorial | A | §38 |
| 16.2 | Consultar situação atual, aprovada, permitida e restrições da parcela | A | §38 |
| 16.3 | Registar ocorrência com fotografia, coordenada, descrição, responsável e ação necessária | A | §38 |
| 16.4 | Monitorizar evolução territorial com levantamentos periódicos | M | §39 |
| 16.5 | Comparar períodos (2026 → 2027 → 2028) e identificar novas construções | M | §39 |
| 16.6 | Comparar alterações com o plano aprovado | A | §39 |

---

## 17. API e Integrações

| # | Requisito | Prioridade | Ref. |
|---|-----------|------------|------|
| 17.1 | API REST em ASP.NET Core para projetos, planos, zonas, parcelas, edificações, vias, infraestruturas, levantamentos, camadas, documentos e sincronização | A | §33 |
| 17.2 | Endpoints para divisões administrativas | A | §33 |
| 17.3 | GeoJSON como formato de intercâmbio para objetos geográficos | A | §33 |
| 17.4 | Integração futura com cadastro predial, sistemas municipais, fiscais, obras, licenciamento, água, energia, ambiente, agricultura, estatísticas e ERP | M | §37 |

---

## Legenda

- **A (Alta):** requisito essencial para o funcionamento base do sistema.
- **M (Média):** requisito importante, mas pode ser implementado em fase posterior.
- **B (Baixa):** requisito desejável, a considerar em evoluções futuras.

---

## Estatísticas

| Prioridade | Quantidade |
|------------|------------|
| Alta (A)   | 78 |
| Média (M)  | 20 |
| Baixa (B)  | 0 |
| **Total**  | **98** |
