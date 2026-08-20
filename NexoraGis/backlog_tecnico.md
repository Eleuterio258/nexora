# Backlog Técnico — Módulo de Cadastro e Ordenamento Territorial

## Visão Geral da Implementação

O desenvolvimento será organizado em **fases iterativas**, começando pela infraestrutura base, passando pelo cadastro territorial, até chegar à análise avançada, publicação e fiscalização.

---

## Fase 1 — Fundação e Infraestrutura (Semanas 1–4)

### Épico 1.1: Ambiente de Desenvolvimento

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 1.1.1 | Configurar repositório e estrutura de solução | Criar solução ASP.NET Core, projetos em camadas (API, Domain, Application, Infrastructure) | 1 dia |
| 1.1.2 | Configurar Docker Compose | PostgreSQL/PostGIS, GeoServer, MinIO/S3, Redis opcional | 2 dias |
| 1.1.3 | Configurar CI/CD | GitHub Actions ou Azure DevOps para build, testes e deploy | 2 dias |
| 1.1.4 | Configurar logging e monitoramento | Serilog, Application Insights ou similar | 1 dia |

### Épico 1.2: Base de Dados Espacial

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 1.2.1 | Criar schema SQL completo | Executar `schema_cadastro_territorial.sql` e ajustar conforme necessidade | 3 dias |
| 1.2.2 | Configurar EF Core + Npgsql + PostGIS | Mapear entidades, configurar tipos espaciais NetTopologySuite | 3 dias |
| 1.2.3 | Criar migrations iniciais | Gerar migrations para todas as tabelas do schema | 2 dias |
| 1.2.4 | Seed de dados de Moçambique | Províncias e estrutura base via script SQL ou seeder C# | 2 dias |
| 1.2.5 | Criar views e funções auxiliares | Views de hierarquia, funções de área e conflitos | 2 dias |

### Épico 1.3: Autenticação e Autorização

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 1.3.1 | Implementar Identity/Autenticação JWT | Login, refresh token, logout | 3 dias |
| 1.3.2 | Implementar RBAC por perfil | Administrador, Gestor do Plano, Técnico GIS, etc. | 3 dias |
| 1.3.3 | Middleware de autorização por recurso | Controlo de acesso a endpoints e operações | 2 dias |
| 1.3.4 | Gestão de organizações (multi-tenant) | Isolamento de dados por organização | 2 dias |

---

## Fase 2 — Estrutura Territorial e Projetos (Semanas 5–7)

### Épico 2.1: Divisão Administrativa

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 2.1.1 | CRUD de divisões administrativas | API e interface para criar/editar países, províncias, distritos, cidades, etc. | 3 dias |
| 2.1.2 | Hierarquia recursiva | Endpoints para obter pai, filhos e caminho completo | 2 dias |
| 2.1.3 | Importação de limites administrativos | Upload de Shapefile/GeoJSON para divisões | 3 dias |
| 2.1.4 | Visualização hierárquica no frontend | Árvore expansível de divisões | 2 dias |
| 2.1.5 | Filtros por zona urbana/rural | Indicador visual e filtros de pesquisa | 1 dia |

### Épico 2.2: Gestão de Projetos

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 2.2.1 | CRUD de projetos territoriais | Código, designação, tipo, datas, estado | 3 dias |
| 2.2.2 | Associação a divisão administrativa | Selecionar província/distrito/cidade do projeto | 1 dia |
| 2.2.3 | Gestão de equipa técnica | Adicionar/remover técnicos e definir funções | 2 dias |
| 2.2.4 | Workflow de estados do projeto | Transições de estado com validações | 2 dias |
| 2.2.5 | Upload de documentos do projeto | Anexos iniciais e contratos | 2 dias |

---

## Fase 3 — Cadastro Territorial (Semanas 8–13)

### Épico 3.1: Parcelas

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 3.1.1 | CRUD de parcelas | Código cadastral, geometria, atributos | 4 dias |
| 3.1.2 | Cálculos espaciais automáticos | Área, perímetro, centroide via triggers ou aplicação | 2 dias |
| 3.1.3 | Associação à divisão administrativa | Ligação parcela → bairro/localidade/quarteirão/etc. | 2 dias |
| 3.1.4 | Estados e uso do solo | Situação, uso atual, uso previsto | 2 dias |
| 3.1.5 | Pesquisa espacial e por atributos | Filtros múltiplos no frontend | 3 dias |
| 3.1.6 | Validações de geometria | Impedir sobreposições inválidas, auto-interseções | 2 dias |

### Épico 3.2: Edificações e Lotes

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 3.2.1 | CRUD de edificações | Associadas a parcelas, com fotos e atributos | 3 dias |
| 3.2.2 | CRUD de lotes | Subdivisão de parcelas | 2 dias |
| 3.2.3 | Múltiplas edificações por parcela | Suporte a n edificações | 1 dia |

### Épico 3.3: Entidades e Proprietários

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 3.3.1 | CRUD de entidades | Proprietário, ocupante, requerente, empresa, instituição | 3 dias |
| 3.3.2 | Relação parcela-entidade | Com vigência e tipo | 2 dias |
| 3.3.3 | Proteção de dados pessoais | Regras de acesso e mascaramento no WebGIS público | 2 dias |

### Épico 3.4: Infraestruturas e Equipamentos

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 3.4.1 | CRUD de infraestruturas | Rede viária, água, saneamento, energia, telecom | 4 dias |
| 3.4.2 | CRUD de equipamentos públicos | Escolas, hospitais, mercados, etc. | 3 dias |
| 3.4.3 | Catálogo de tipos e subtipos | Configuração flexível por projeto | 2 dias |

---

## Fase 4 — Aplicação de Campo e Sincronização (Semanas 14–17)

### Épico 4.1: App Android de Campo

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 4.1.1 | Setup do projeto Flutter/Android | Estrutura, dependências, mapa base | 3 dias |
| 4.1.2 | Autenticação e seleção de projeto | Login e lista de projetos/tarefas | 2 dias |
| 4.1.3 | Mapa offline | Download de mapa base, parcelas e limites | 4 dias |
| 4.1.4 | Recolha de geometria | Pontos, linhas, polígonos no terreno | 4 dias |
| 4.1.5 | Recolha de fotos e vídeos | Anexos com metadados de localização | 2 dias |
| 4.1.6 | Formulários de campo | Formulários configuráveis por projeto | 3 dias |
| 4.1.7 | Funcionamento offline | Base de dados local (SQLite) | 4 dias |

### Épico 4.2: Sincronização

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 4.2.1 | Endpoint `/api/v1/sync` | Receber dados do campo | 3 dias |
| 4.2.2 | Validação de dados sincronizados | Verificar geometria, duplicados, permissões | 3 dias |
| 4.2.3 | Resolução de conflitos de sincronização | Interface para resolver duplicados | 3 dias |
| 4.2.4 | Fila de sincronização | Processamento assíncrono de grandes volumes | 2 dias |

### Épico 4.3: Integração GNSS/RTK e Drones

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 4.3.1 | Registo de pontos de levantamento | Coordenadas, precisão, equipamento, operador | 2 dias |
| 4.3.2 | Integração com apps GNSS externas | Receber coordenadas de equipamentos RTK | 3 dias |
| 4.3.3 | Registo de produtos de drone | Ortofotos, MDT, MDS, nuvens de pontos | 3 dias |

---

## Fase 5 — Plano, Zoneamento e Análise (Semanas 18–22)

### Épico 5.1: Plano de Ordenamento

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 5.1.1 | CRUD de planos e versões | Plano 2026 v1.0, v1.1, etc. | 3 dias |
| 5.1.2 | Histórico de versões | Manter versões anteriores acessíveis | 2 dias |
| 5.1.3 | Associar plano a projeto | Ligação plano ↔ projeto | 1 dia |

### Épico 5.2: Zoneamento

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 5.2.1 | CRUD de zonas | ZH, ZC, ZM, ZI, ZA, ZE, ZV, ZT, ZP, ZEX | 3 dias |
| 5.2.2 | Parâmetros urbanísticos | Altura, pisos, ocupação, afastamentos, atividades | 2 dias |
| 5.2.3 | Estilos de camada por zona | Cores e legendas no mapa | 2 dias |
| 5.2.4 | Associar zona a parcelas | Classificação do plano por parcela | 2 dias |

### Épico 5.3: Análise Espacial

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 5.3.1 | Ferramentas de medição | Área, perímetro, distância no WebGIS | 3 dias |
| 5.3.2 | Buffers e interseções | Operações espaciais básicas | 3 dias |
| 5.3.3 | Identificação de parcelas afetadas | Por zona, condicionante ou infraestrutura | 3 dias |
| 5.3.4 | Estatísticas territoriais | Sumários por divisão/zona | 2 dias |

### Épico 5.4: Motor de Conflitos

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 5.4.1 | Deteção de uso incompatível | Comparar uso atual vs. uso previsto | 3 dias |
| 5.4.2 | Deteção de construções em zonas condicionadas | Verificação espacial automática | 3 dias |
| 5.4.3 | Registo e gestão de conflitos | Lista de conflitos, resolução | 2 dias |
| 5.4.4 | Notificações de conflito | Alertas no dashboard e por email | 2 dias |

---

## Fase 6 — Workflow, Auditoria e Versionamento (Semanas 23–25)

### Épico 6.1: Aprovação

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 6.1.1 | Workflow de aprovação para parcelas e planos | Estados: rascunho, submetido, em análise, aprovado, rejeitado, publicado | 4 dias |
| 6.1.2 | Notificações entre atores | Técnico → Supervisor → Responsável | 2 dias |
| 6.1.3 | Dashboard de tarefas pendentes | Aprovações em fila | 2 dias |

### Épico 6.2: Versionamento e Auditoria

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 6.2.1 | Versionamento de geometrias | Guardar anterior/nova, motivo, utilizador | 3 dias |
| 6.2.2 | Reconstrução histórica | Ver situação territorial numa data | 2 dias |
| 6.2.3 | Logs de auditoria | Triggers e tabela audit.log | 2 dias |
| 6.2.4 | Interface de consulta de auditoria | Filtros por utilizador, operação, data | 2 dias |

---

## Fase 7 — Publicação e WebGIS (Semanas 26–29)

### Épico 7.1: GeoServer

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 7.1.1 | Configurar GeoServer via Docker | Workspaces, stores, camadas | 2 dias |
| 7.1.2 | Publicar camadas automaticamente | Integração API → GeoServer REST | 4 dias |
| 7.1.3 | Serviços WMS/WFS/WMTS | Configurar e testar | 2 dias |
| 7.1.4 | Estilos SLD por camada | Parcelas, zonas, infraestruturas | 2 dias |

### Épico 7.2: WebGIS

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 7.2.1 | WebGIS técnico | Acesso completo conforme permissões | 5 dias |
| 7.2.2 | WebGIS público | Dados autorizados, sem dados pessoais | 3 dias |
| 7.2.3 | Visualização de camadas | Liga/desliga, transparência, ordem | 3 dias |
| 7.2.4 | Pesquisa e identificação | Parcelas, divisões, equipamentos | 3 dias |
| 7.2.5 | Ferramentas de desenho e medição | Medir distâncias e áreas | 2 dias |
| 7.2.6 | Impressão de mapas | Layouts e exportação PDF/PNG | 3 dias |

### Épico 7.3: Catálogo de Camadas

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 7.3.1 | CRUD do catálogo de camadas | Metadados, responsável, fonte, versão | 3 dias |
| 7.3.2 | Gestão de visibilidade e acesso público | Por camada | 2 dias |

---

## Fase 8 — Relatórios, Dashboard e Fiscalização (Semanas 30–33)

### Épico 8.1: Dashboard

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 8.1.1 | Indicadores territoriais | Área total, parcelas, construções, vias, etc. | 3 dias |
| 8.1.2 | Gráficos e mapas interativos | Biblioteca de visualização | 3 dias |
| 8.1.3 | Filtros por projeto e divisão | Contexto dinâmico | 2 dias |

### Épico 8.2: Relatórios

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 8.2.1 | Ficha cadastral e ficha de parcela | PDF com dados e mapa | 4 dias |
| 8.2.2 | Plantas de localização/enquadramento | Geração automática | 3 dias |
| 8.2.3 | Mapas temáticos | Uso do solo, zoneamento, infraestruturas | 3 dias |
| 8.2.4 | Relatórios de levantamento, conflitos e evolução | PDF/Excel | 4 dias |

### Épico 8.3: Fiscalização Territorial

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 8.3.1 | Módulo de fiscalização na app de campo | Consultar situação e registar ocorrência | 4 dias |
| 8.3.2 | Consulta comparativa | O que existe vs. o que está aprovado vs. o que permite construir | 3 dias |
| 8.3.3 | Registo de ocorrências | Fotografia, coordenada, descrição, ação | 2 dias |
| 8.3.4 | Workflow de resolução de ocorrências | Aberto → Em análise → Resolvido | 2 dias |

---

## Fase 9 — Integrações e Otimização (Semanas 34–36)

### Épico 9.1: Importação/Exportação

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 9.1.1 | Importar Shapefile/GeoJSON/GeoPackage/KML/CSV | Conversão para entidades do sistema | 4 dias |
| 9.1.2 | Importar DXF/DWG | Processamento adequado | 3 dias |
| 9.1.3 | Exportar GeoJSON/Shapefile/GeoPackage/KML/PDF/Excel | Múltiplos formatos | 3 dias |
| 9.1.4 | Importação de ortofotos e rasters | GeoTIFF, COG | 3 dias |

### Épico 9.2: Integrações Externas

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 9.2.1 | Design da API de integração | Contratos para sistemas externos | 2 dias |
| 9.2.2 | Integração com cadastro predial | Consulta de propriedades | 3 dias |
| 9.2.3 | Integração com sistemas municipais/fiscais | Envio/receção de dados | 3 dias |
| 9.2.4 | Webhooks e notificações | Eventos para sistemas externos | 2 dias |

### Épico 9.3: Performance e Escalabilidade

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 9.3.1 | Otimização de queries espaciais | Índices, partições, materialized views | 3 dias |
| 9.3.2 | Cache de camadas frequentes | Redis ou cache do GeoServer | 2 dias |
| 9.3.3 | Paginação e streaming de grandes datasets | Para parcelas e geometrias | 2 dias |
| 9.3.4 | Testes de carga | Simular múltiplos utilizadores | 2 dias |

---

## Fase 10 — Testes, Documentação e Entrega (Semanas 37–40)

### Épico 10.1: Testes

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 10.1.1 | Testes unitários da API | xUnit, cobertura mínima 70% | 5 dias |
| 10.1.2 | Testes de integração | API + base de dados | 4 dias |
| 10.1.3 | Testes end-to-end do WebGIS | Cypress/Playwright | 4 dias |
| 10.1.4 | Testes da app de campo | Emulador e dispositivo real | 3 dias |
| 10.1.5 | Testes de carga e stress | k6 ou JMeter | 2 dias |

### Épico 10.2: Documentação

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 10.2.1 | Documentação da API (Swagger/OpenAPI) | Endpoints e exemplos | 2 dias |
| 10.2.2 | Manual do utilizador | Web, app de campo, QGIS | 4 dias |
| 10.2.3 | Manual de administração | Configuração, permissões, backup | 2 dias |
| 10.2.4 | Documentação técnica de deployment | Docker, infraestrutura | 2 dias |

### Épico 10.3: Entrega e Go-Live

| # | Tarefa | Descrição | Esforço |
|---|--------|-----------|---------|
| 10.3.1 | Ambiente de produção | Servidores, SSL, backups | 3 dias |
| 10.3.2 | Migração de dados piloto | Dados de teste para produção | 2 dias |
| 10.3.3 | Treino dos utilizadores | Sessões presenciais/remotas | 3 dias |
| 10.3.4 | Suporte pós-implantação | Período de garantia | contínuo |

---

## Resumo por Fase

| Fase | Duração | Foco Principal |
|------|---------|----------------|
| 1 — Fundação | Semanas 1–4 | Base de dados, auth, ambiente |
| 2 — Territorial/Projetos | Semanas 5–7 | Divisão administrativa e projetos |
| 3 — Cadastro | Semanas 8–13 | Parcelas, edificações, entidades, infraestruturas |
| 4 — Campo/Sincronização | Semanas 14–17 | App móvel, GNSS, drones, sync |
| 5 — Plano/Análise | Semanas 18–22 | Zoneamento, análise espacial, conflitos |
| 6 — Workflow/Auditoria | Semanas 23–25 | Aprovação, versionamento, logs |
| 7 — Publicação/WebGIS | Semanas 26–29 | GeoServer, WebGIS técnico/público |
| 8 — Relatórios/Fiscalização | Semanas 30–33 | Dashboard, relatórios, fiscalização |
| 9 — Integrações/Performance | Semanas 34–36 | Import/export, APIs externas, otimização |
| 10 — Testes/Entrega | Semanas 37–40 | QA, documentação, produção |

**Duração total estimada: ~40 semanas (10 meses)** com uma equipa de 4–6 desenvolvedores.

---

## Equipa Recomendada

| Perfil | Quantidade | Responsabilidade |
|--------|------------|------------------|
| Tech Lead / Arquiteto | 1 | Arquitetura, decisões técnicas |
| Backend .NET | 2 | API, lógica de negócio, integrações |
| Frontend / WebGIS | 2 | Aplicação web, WebGIS |
| Mobile (Flutter/Android) | 1 | App de campo |
| DBA / GIS Specialist | 1 | PostGIS, QGIS, GeoServer |
| QA / Tester | 1 | Testes, qualidade |
| DevOps | 1 | CI/CD, infraestrutura, deploy |
