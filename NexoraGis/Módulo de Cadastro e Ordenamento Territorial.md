# Módulo de Cadastro e Ordenamento Territorial

## Índice

1. [Visão Geral](#1-visão-geral)
2. [Objetivos](#2-objetivos)
3. [Estrutura Territorial](#3-estrutura-territorial)
   - 3.1 [Divisão Administrativa de Moçambique](#31-divisão-administrativa-de-moçambique)
   - 3.2 [Zona Urbana](#32-zona-urbana)
   - 3.3 [Zona Rural](#33-zona-rural)
   - 3.4 [Estrutura Flexível do Sistema](#34-estrutura-flexível-do-sistema)
4. [Gestão de Projetos](#4-gestão-de-projetos)
5. [Cadastro Territorial](#5-cadastro-territorial)
6. [Pessoas e Entidades Relacionadas](#6-pessoas-e-entidades-relacionadas)
7. [Edificações](#7-edificações)
8. [Levantamentos de Campo](#8-levantamentos-de-campo)
9. [Funcionamento Offline](#9-funcionamento-offline)
10. [Integração GNSS/RTK](#10-integração-gnssrtk)
11. [Integração com Drones](#11-integração-com-drones)
12. [Gestão do Plano de Ordenamento](#12-gestão-do-plano-de-ordenamento)
13. [Zoneamento](#13-zoneamento)
14. [Uso Atual vs. Uso Planeado](#14-uso-atual-vs-uso-planeado)
15. [Condicionantes Territoriais](#15-condicionantes-territoriais)
16. [Infraestruturas](#16-infraestruturas)
17. [Equipamentos e Serviços Públicos](#17-equipamentos-e-serviços-públicos)
18. [Análise Espacial](#18-análise-espacial)
19. [Deteção de Conflitos](#19-deteção-de-conflitos)
20. [QGIS](#20-qgis)
21. [GeoServer](#21-geoserver)
22. [WebGIS](#22-webgis)
23. [Gestão de Camadas](#23-gestão-de-camadas)
24. [Importação e Exportação](#24-importação-e-exportação)
25. [Gestão Documental](#25-gestão-documental)
26. [Workflow de Aprovação](#26-workflow-de-aprovação)
27. [Versionamento](#27-versionamento)
28. [Auditoria](#28-auditoria)
29. [Utilizadores e Perfis](#29-utilizadores-e-perfis)
30. [Dashboard Territorial](#30-dashboard-territorial)
31. [Relatórios](#31-relatórios)
32. [Pesquisa Territorial](#32-pesquisa-territorial)
33. [API Geoespacial](#33-api-geoespacial)
34. [Arquitetura Técnica](#34-arquitetura-técnica)
35. [Segurança](#35-segurança)
36. [Multi-Tenant](#36-multi-tenant)
37. [Integração com Outros Sistemas](#37-integração-com-outros-sistemas)
38. [Fiscalização Territorial](#38-fiscalização-territorial)
39. [Monitorização da Evolução Territorial](#39-monitorização-da-evolução-territorial)
40. [Fluxo Completo](#40-fluxo-completo)
41. [Resultado Esperado](#41-resultado-esperado)

---

## 1. Visão Geral

O **Módulo de Cadastro e Ordenamento Territorial** é uma plataforma integrada de gestão geoespacial destinada ao levantamento, cadastro, planeamento, análise, aprovação, publicação e acompanhamento da ocupação do território.

O sistema permite gerir digitalmente todo o ciclo de vida de um **Plano de Ordenamento Territorial**, desde a preparação e recolha de dados no terreno até à produção das plantas finais, aprovação, publicação e posterior atualização.

A solução combina tecnologias de **Sistemas de Informação Geográfica (SIG/GIS)**, aplicações Web e Mobile, bases de dados espaciais e serviços cartográficos.

A arquitetura proposta utiliza:

* Aplicação Web para administração e gestão;
* Aplicação Android para recolha de dados no terreno;
* API REST em ASP.NET Core;
* PostgreSQL/PostGIS;
* QGIS;
* GeoServer;
* WebGIS;
* armazenamento de documentos, imagens, ortofotos e outros ficheiros;
* integração com GNSS/RTK, drones e outras fontes de informação geográfica.

---

## 2. Objetivos

O módulo tem como principais objetivos:

* digitalizar o processo de elaboração dos planos de ordenamento;
* criar uma base territorial centralizada;
* organizar informação cadastral e cartográfica;
* permitir levantamentos georreferenciados;
* identificar a ocupação atual do território;
* definir o uso proposto do solo;
* controlar alterações ao plano;
* acompanhar a implementação do plano;
* identificar ocupações incompatíveis;
* facilitar fiscalização territorial;
* disponibilizar informação aos técnicos e decisores;
* produzir mapas e plantas automaticamente;
* manter histórico das alterações territoriais;
* integrar diferentes instituições através de API;
* disponibilizar determinados dados através de WebGIS.

---

## 3. Estrutura Territorial

O sistema deverá permitir uma estrutura territorial hierárquica configurável, adaptada à realidade administrativa de Moçambique e flexível o suficiente para suportar diferentes contextos municipais e distritais.

### 3.1 Divisão Administrativa de Moçambique

Em Moçambique, a divisão administrativa diferencia-se entre zona urbana e zona rural. O sistema deve refletir esta dualidade sem impor uma hierarquia rígida.

A estrutura base deve ser representada por uma hierarquia configurável de divisões administrativas, onde cada divisão possui:

* código;
* nome;
* tipo (país, província, cidade, município, distrito, distrito municipal, posto administrativo, localidade, bairro, quarteirão, aldeia, povoação, comunidade, unidade de planeamento, etc.);
* indicação de zona urbana/rural;
* geometria;
* área calculada;
* nível hierárquico;
* entidade responsável;
* código do INE (quando disponível);
* estado;
* data de criação;
* documentos associados;
* metadados;
* histórico.

A estrutura não deverá ser rígida, permitindo adaptar o sistema às diferentes organizações administrativas e às variações entre municípios.

### 3.2 Zona Urbana

Na zona urbana, a estrutura típica é:

**Província → Cidade/Município → Distrito municipal ou urbano → Posto administrativo urbano → Bairro → Quarteirão**

Exemplo:

**Província de Maputo → Cidade de Maputo → Distrito Municipal KaMpfumo → Bairro Central → Quarteirão**

Elementos urbanos:

* **Cidade / Município:** centro urbano com governo municipal próprio.
* **Distrito municipal / Distrito urbano:** subdivisão administrativa urbana.
* **Posto administrativo urbano:** unidade de gestão local dentro da cidade.
* **Bairro:** unidade residencial e de vizinhança.
* **Quarteirão:** conjunto de parcelas delimitado por vias.

### 3.3 Zona Rural

Na zona rural, a estrutura típica é:

**Província → Distrito → Posto administrativo → Localidade → Aldeia/Povoação → Comunidade**

Exemplo:

**Província de Maputo → Distrito de Marracuene → Posto Administrativo de Machubo → Localidade → Aldeia**

Elementos rurais:

* **Distrito:** divisão administrativa rural.
* **Posto administrativo:** unidade local de coordenação do distrito.
* **Localidade:** aglomeração populacional rural com certa organização administrativa.
* **Aldeia / Povoação:** pequeno aglomerado habitacional.
* **Comunidade:** grupo populacional com organização social própria, muitas vezes baseada na ocupação tradicional da terra.

### 3.4 Estrutura Flexível do Sistema

Para um sistema de cadastro, recomenda-se a seguinte estrutura flexível:

```text
Província
 └── Distrito/Cidade/Município
      └── Posto administrativo
           └── Localidade/Bairro
                └── Aldeia/Povoação/Quarteirão
                    └── Parcela/Talhão/Lote
```

Em termos simples:

* **Cidade:** organiza-se principalmente em distritos urbanos, bairros e quarteirões.
* **Campo:** organiza-se em distritos, postos administrativos, localidades, aldeias e povoações.

As denominações podem variar ligeiramente entre municípios. O INE utiliza campos como **bairro, aldeia ou povoação**, distinguindo depois a residência como urbana ou rural.

O sistema deverá permitir:

* configurar quais os tipos de divisão administrativa ativos por projeto;
* associar uma parcela a qualquer nível da hierarquia;
* visualizar a hierarquia completa de uma parcela;
* filtrar dados por zona urbana/rural;
* importar limites administrativos a partir de fontes oficiais (INE, cartografia municipal, etc.).

---

## 4. Gestão de Projetos

Cada trabalho de ordenamento deverá ser criado como um **Projeto Territorial**.

Exemplos:

* Plano de Estrutura Urbana;
* Plano Geral de Urbanização;
* Plano Parcial de Urbanização;
* Plano de Pormenor;
* levantamento cadastral;
* regularização territorial;
* atualização cartográfica;
* levantamento de infraestruturas.

Cada projeto poderá conter:

* código;
* designação;
* descrição;
* cliente;
* entidade responsável;
* divisão administrativa de referência;
* localização;
* área de intervenção;
* coordenadas;
* sistema de referência (ex: WGS84 / UTM 36S / 37S);
* equipa técnica;
* responsável técnico;
* data de início;
* data prevista de conclusão;
* estado;
* documentos;
* camadas GIS;
* levantamentos;
* versões do plano.

Estados possíveis:

**Rascunho → Levantamento → Diagnóstico → Proposta → Em Revisão → Aprovado → Publicado → Em Implementação → Arquivado**

---

## 5. Cadastro Territorial

O cadastro constitui um dos componentes centrais da plataforma.

Deverá permitir registar e representar espacialmente:

* parcelas;
* talhões;
* quarteirões;
* lotes;
* edifícios;
* construções;
* vias;
* servidões;
* espaços públicos;
* equipamentos;
* infraestruturas;
* áreas não ocupadas.

### 5.1 Parcela

Cada parcela poderá possuir:

**Identificação**

* ID interno;
* código cadastral;
* número da parcela;
* número do talhão;
* quarteirão / aldeia / povoação / comunidade;
* bairro / localidade;
* divisão administrativa de referência.

**Informação espacial**

* geometria;
* coordenadas;
* área calculada;
* perímetro;
* centroide;
* sistema de coordenadas;
* precisão do levantamento.

**Situação**

* ocupada;
* desocupada;
* parcialmente ocupada;
* em construção;
* abandonada;
* em conflito;
* reservada.

**Uso atual**

* habitacional;
* comercial;
* serviços;
* industrial;
* agrícola;
* institucional;
* recreativo;
* misto;
* outros.

**Uso previsto**

* classificação estabelecida pelo plano;
* parâmetros urbanísticos;
* restrições;
* condicionantes.

O sistema deverá manter separadas as informações de **realidade existente** e de **uso previsto pelo plano**.

---

## 6. Pessoas e Entidades Relacionadas

Quando permitido pela legislação e pelas regras do projeto, uma parcela poderá estar relacionada com:

* proprietário;
* ocupante;
* requerente;
* empresa;
* instituição pública;
* associação;
* concessionário.

A informação pessoal deverá possuir regras específicas de acesso.

A visualização pública através do WebGIS não deverá expor automaticamente dados pessoais.

---

## 7. Edificações

O módulo permitirá cadastrar edificações individualmente ou associadas às parcelas.

Informações possíveis:

* código;
* parcela;
* localização;
* área construída;
* número de pisos;
* tipo de construção;
* finalidade;
* material predominante;
* estado de conservação;
* situação de ocupação;
* fotografias;
* coordenadas;
* data do levantamento.

Poderá existir mais de uma edificação dentro da mesma parcela.

---

## 8. Levantamentos de Campo

O sistema deverá possuir uma aplicação móvel destinada às equipas de campo.

O técnico poderá receber previamente:

* projeto;
* área atribuída;
* rota;
* parcelas;
* formulários;
* tarefas.

No terreno poderá recolher:

* pontos;
* linhas;
* polígonos;
* coordenadas;
* fotografias;
* vídeos;
* observações;
* informações cadastrais;
* condições das infraestruturas;
* ocupação do solo.

---

## 9. Funcionamento Offline

A aplicação de campo deverá suportar funcionamento **offline**.

Antes de sair para o terreno, o técnico poderá descarregar:

* mapa base;
* parcelas;
* limites administrativos;
* formulários;
* tarefas;
* imagens necessárias.

Durante o trabalho, os dados ficam armazenados localmente.

Quando existir Internet:

**Dispositivo → API → Validação → PostGIS**

O sistema deverá controlar conflitos de sincronização e impedir duplicação de registos.

---

## 10. Integração GNSS/RTK

O módulo deverá aceitar levantamentos provenientes de:

* GNSS;
* GNSS RTK;
* estação total;
* GPS portátil;
* aplicações móveis;
* equipamentos externos.

Poderão ser armazenados:

* latitude;
* longitude;
* altitude;
* precisão horizontal;
* precisão vertical;
* método de levantamento;
* equipamento utilizado;
* operador;
* data/hora;
* sistema de referência.

---

## 11. Integração com Drones

Os levantamentos realizados com drones poderão produzir:

* fotografias aéreas;
* ortofotos;
* modelos digitais de terreno;
* modelos digitais de superfície;
* nuvens de pontos;
* modelos 3D.

Estes produtos poderão ser registados no projeto e disponibilizados aos técnicos GIS.

Fluxo:

**Drone → Fotogrametria → Ortofoto/Modelo → Armazenamento → QGIS → Análise → Plano**

---

## 12. Gestão do Plano de Ordenamento

O módulo deverá permitir criar digitalmente o plano sobre a base territorial existente.

Cada plano deverá possuir diferentes versões.

Exemplo:

**Plano 2026 — Versão 1.0**

Posteriormente:

**Versão 1.1**

O histórico anterior deverá permanecer disponível.

---

## 13. Zoneamento

O sistema permitirá definir zonas de utilização do território.

Exemplos:

| Código | Classificação   |
| ------ | --------------- |
| ZH     | Habitação       |
| ZC     | Comércio        |
| ZS     | Serviços        |
| ZM     | Uso misto       |
| ZI     | Indústria       |
| ZA     | Agricultura     |
| ZE     | Equipamentos    |
| ZV     | Espaços verdes  |
| ZT     | Turismo         |
| ZP     | Proteção        |
| ZEX    | Expansão urbana |

Cada zona poderá possuir parâmetros próprios.

Por exemplo:

**ZH-02 — Habitação**

* utilização principal: habitação;
* altura máxima;
* número máximo de pisos;
* ocupação máxima;
* afastamentos;
* área mínima de parcela;
* atividades permitidas;
* atividades condicionadas;
* atividades proibidas.

---

## 14. Uso Atual vs. Uso Planeado

Uma das funções mais importantes será comparar:

**Situação Atual × Plano Aprovado**

Exemplo:

> Parcela PAR-00982
> Uso atual: Habitação
> Uso previsto: Expansão de via

O sistema poderá automaticamente identificar este conflito espacial.

---

## 15. Condicionantes Territoriais

Deverão ser registadas áreas sujeitas a restrições, como:

* linhas de água;
* zonas inundáveis;
* encostas;
* zonas de erosão;
* áreas protegidas;
* corredores ecológicos;
* linhas elétricas;
* estradas;
* ferrovias;
* gasodutos;
* servidões;
* reservas do Estado;
* outras zonas de proteção.

---

## 16. Infraestruturas

O sistema deverá manter cadastro georreferenciado das principais infraestruturas.

### Rede viária

* estradas;
* avenidas;
* ruas;
* caminhos;
* pontes;
* interseções;
* passeios.

### Água

* condutas;
* válvulas;
* reservatórios;
* furos;
* fontanários;
* ligações.

### Saneamento e drenagem

* coletores;
* valas;
* canais;
* caixas;
* estações;
* pontos de descarga.

### Energia

* postes;
* transformadores;
* linhas;
* subestações.

### Telecomunicações

* torres;
* fibra;
* caixas;
* outras infraestruturas.

---

## 17. Equipamentos e Serviços Públicos

Poderão ser cadastrados:

* escolas;
* hospitais;
* centros de saúde;
* mercados;
* esquadras;
* bombeiros;
* edifícios administrativos;
* cemitérios;
* parques;
* instalações desportivas;
* terminais de transporte;
* outros equipamentos.

Isto permitirá analisar a cobertura dos serviços existentes.

---

## 18. Análise Espacial

O sistema deverá oferecer ferramentas de análise geográfica.

Entre elas:

* cálculo de área;
* cálculo de perímetro;
* cálculo de distância;
* buffers;
* interseções;
* sobreposição;
* proximidade;
* densidade;
* identificação de parcelas afetadas;
* identificação de construções em zonas condicionadas;
* análise de cobertura de equipamentos;
* estatísticas territoriais.

---

## 19. Deteção de Conflitos

A plataforma poderá possuir um **motor de validação territorial**.

Exemplo:

Quando uma nova construção é registada:

**Nova construção → localização → PostGIS → comparação com zoneamento → comparação com condicionantes → resultado**

Resultado possível:

> ⚠ Construção localizada numa zona reservada para expansão da rede viária.

Ou:

> ✓ Uso compatível com o Plano de Ordenamento.

---

## 20. QGIS

O QGIS será a principal ferramenta técnica para trabalhos GIS avançados.

Os técnicos poderão:

* abrir projetos;
* visualizar PostGIS;
* editar dados autorizados;
* produzir mapas;
* realizar análises;
* trabalhar com ortofotos;
* trabalhar com rasters;
* produzir layouts cartográficos;
* exportar mapas;
* realizar geoprocessamento.

Arquitetura:

**QGIS ↔ PostgreSQL/PostGIS**

Para operações sensíveis deverão existir mecanismos de controlo, versionamento e aprovação.

---

## 21. GeoServer

O GeoServer será utilizado para publicação de serviços geográficos.

Poderá disponibilizar:

* WMS;
* WFS;
* WMTS;
* outros padrões OGC quando necessários.

Fluxo:

**PostGIS → GeoServer → WebGIS**

Assim, não será necessário disponibilizar acesso direto à base de dados aos utilizadores externos.

---

## 22. WebGIS

O WebGIS será o portal cartográfico da solução.

Permitirá:

* visualizar mapas;
* ligar/desligar camadas;
* pesquisar locais;
* pesquisar parcelas;
* identificar elementos;
* medir distâncias;
* medir áreas;
* consultar atributos;
* visualizar ortofotos;
* imprimir mapas;
* gerar links;
* comparar camadas.

Poderão existir dois ambientes:

**WebGIS Técnico** — acesso completo conforme permissões.

**WebGIS Público** — apenas informação autorizada para consulta pública.

---

## 23. Gestão de Camadas

A plataforma deverá possuir um catálogo central de camadas.

Exemplos:

```text
Limites administrativos
Bairros
Localidades
Quarteirões
Aldeias
Povoações
Comunidades
Parcelas
Edificações
Rede viária
Hidrografia
Zoneamento
Uso atual do solo
Uso proposto
Áreas de expansão
Áreas protegidas
Infraestruturas
Equipamentos
Ortofotos
Modelo de terreno
```

Cada camada deverá possuir metadados, responsável, fonte, data, sistema de coordenadas e versão.

---

## 24. Importação e Exportação

O sistema poderá suportar, conforme o tipo de dado:

* GeoJSON;
* GeoPackage;
* GeoTIFF;
* COG;
* KML/KMZ;
* CSV com coordenadas;
* Shapefile para interoperabilidade;
* PDF;
* DXF/DWG através dos processos adequados;
* XLSX para informação tabular.

---

## 25. Gestão Documental

Cada elemento territorial poderá possuir documentos associados.

Exemplo:

**Parcela → documentos**

* planta;
* requerimento;
* relatório;
* fotografia;
* parecer;
* autorização;
* levantamento;
* outros anexos.

Os ficheiros grandes, principalmente ortofotos e imagens, poderão ser mantidos em armazenamento de objetos, mantendo no PostGIS apenas as referências e metadados necessários.

---

## 26. Workflow de Aprovação

Alterações importantes não deverão entrar imediatamente na versão oficial.

Fluxo recomendado:

**Técnico cria → Submete → Supervisor verifica → Responsável aprova → Publicação**

Estados:

* Rascunho
* Submetido
* Em análise
* Correção solicitada
* Aprovado
* Rejeitado
* Publicado

---

## 27. Versionamento

Uma geometria nunca deverá simplesmente desaparecer quando for alterada.

O sistema deverá guardar:

* geometria anterior;
* geometria nova;
* utilizador;
* data;
* motivo;
* projeto;
* aprovação.

Isso permite reconstruir a situação territorial de uma determinada data.

---

## 28. Auditoria

Operações críticas deverão produzir logs.

Exemplo:

```text
19/08/2026 14:35
Utilizador: Técnico GIS
Operação: ALTERAÇÃO DE GEOMETRIA
Objeto: PAR-000245
Projeto: POT-2026
Versão anterior: 4
Versão nova: 5
```

---

## 29. Utilizadores e Perfis

Exemplos de perfis:

### Administrador

Configuração geral e administração do sistema.

### Gestor do Plano

Gestão de projetos, equipas, versões e aprovação.

### Planeador Territorial

Zoneamento e elaboração do plano.

### Técnico GIS

Cartografia, edição e análise espacial.

### Topógrafo

Levantamentos GNSS/RTK.

### Técnico de Campo

Recolha de informação.

### Fiscal

Verificação da ocupação territorial.

### Consulta

Acesso apenas para leitura.

As permissões deverão ser configuráveis por funcionalidade e operação.

---

## 30. Dashboard Territorial

O dashboard poderá apresentar indicadores como:

* área total;
* área urbanizada;
* área disponível;
* número de parcelas;
* parcelas ocupadas;
* parcelas vazias;
* construções;
* população estimada;
* quilómetros de vias;
* cobertura de infraestruturas;
* áreas verdes;
* zonas de risco;
* conflitos territoriais identificados.

---

## 31. Relatórios

O sistema poderá produzir:

* ficha cadastral;
* ficha de parcela;
* planta de localização;
* planta de enquadramento;
* mapa de uso do solo;
* mapa de zoneamento;
* mapa de infraestruturas;
* relatório de levantamento;
* relatório de conflitos;
* relatório estatístico;
* relatório de evolução territorial.

---

## 32. Pesquisa Territorial

A pesquisa poderá ser feita através de:

* código da parcela;
* coordenada;
* proprietário/ocupante, quando autorizado;
* bairro / localidade;
* quarteirão / aldeia / povoação / comunidade;
* distrito / posto administrativo;
* projeto;
* tipo de utilização;
* zona;
* endereço;
* seleção diretamente no mapa.

---

## 33. API Geoespacial

A API central deverá permitir comunicação com aplicações internas e sistemas externos.

Exemplo:

```text
/api/v1/projects
/api/v1/plans
/api/v1/zones
/api/v1/parcels
/api/v1/buildings
/api/v1/roads
/api/v1/infrastructure
/api/v1/surveys
/api/v1/layers
/api/v1/features
/api/v1/documents
/api/v1/sync
/api/v1/administrative-divisions
```

Para objetos geográficos, **GeoJSON** poderá ser utilizado como um dos formatos de intercâmbio.

---

## 34. Arquitetura Técnica

```text
               ┌────────────────────┐
               │    Aplicação Web   │
               └─────────┬──────────┘
                         │
┌────────────────┐       │       ┌─────────────────┐
│ App de Campo   │───────┼───────│ Outros Sistemas │
└────────────────┘       │       └─────────────────┘
                         ▼
               ┌────────────────────┐
               │ ASP.NET Core API   │
               │                    │
               │ Auth               │
               │ Projetos           │
               │ Cadastro           │
               │ Workflow           │
               │ GIS                │
               │ Auditoria          │
               └─────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │ PostgreSQL/PostGIS  │
              └──────┬────────┬─────┘
                     │        │
                ┌────▼───┐ ┌──▼────────┐
                │ QGIS   │ │ GeoServer │
                └────────┘ └─────┬─────┘
                                 │
                                 ▼
                              WebGIS
```

---

## 35. Segurança

A solução deverá considerar:

* autenticação segura;
* JWT/OAuth2 conforme arquitetura;
* controlo de acesso baseado em permissões;
* separação de organizações/projetos;
* HTTPS;
* auditoria;
* backups;
* encriptação adequada;
* controlo de acesso aos documentos;
* proteção dos dados pessoais;
* restrição de acesso direto à base de dados.

---

## 36. Multi-Tenant

Caso o sistema seja utilizado por diferentes clientes, poderá funcionar em arquitetura **multi-tenant**.

Exemplo:

```text
Plataforma
   │
   ├── Município A
   │      ├── Plano 01
   │      └── Plano 02
   │
   ├── Município B
   │      └── Plano 01
   │
   └── Empresa/Instituição C
          └── Projeto 01
```

Cada organização terá os seus utilizadores, projetos, dados e permissões.

---

## 37. Integração com Outros Sistemas

A arquitetura deverá permitir integração futura com:

* cadastro predial;
* sistemas municipais;
* sistemas fiscais;
* gestão de obras;
* licenciamento;
* água e saneamento;
* energia;
* ambiente;
* gestão de resíduos;
* proteção civil;
* agricultura;
* sistemas estatísticos;
* plataformas de pagamento;
* ERP.

---

## 38. Fiscalização Territorial

Uma evolução importante do módulo será utilizar o próprio plano para fiscalização.

O fiscal poderá selecionar uma parcela no tablet e consultar:

**O que existe atualmente?**

**O que está aprovado?**

**O que o plano permite construir?**

**Existe alguma restrição?**

Poderá depois registar:

* ocorrência;
* fotografia;
* coordenada;
* descrição;
* responsável;
* estado;
* ação necessária.

---

## 39. Monitorização da Evolução Territorial

Com levantamentos periódicos de drone, imagens de satélite ou trabalho de campo, será possível comparar diferentes períodos.

Exemplo:

**2026 → 2027 → 2028**

A plataforma poderá identificar novar construções e alterações de ocupação e compará-las com o plano aprovado.

Isso transforma o módulo de simples ferramenta de elaboração do plano numa verdadeira **plataforma de gestão territorial**.

---

## 40. Fluxo Completo

```text
1. Criar projeto
        ↓
2. Delimitar área
        ↓
3. Importar cartografia existente
        ↓
4. Planeamento do levantamento
        ↓
5. GNSS / RTK / Drone / Campo
        ↓
6. Sincronização com API
        ↓
7. PostgreSQL/PostGIS
        ↓
8. Tratamento no QGIS
        ↓
9. Cadastro territorial
        ↓
10. Diagnóstico
        ↓
11. Elaboração do zoneamento
        ↓
12. Análises espaciais
        ↓
13. Deteção de conflitos
        ↓
14. Revisão
        ↓
15. Aprovação
        ↓
16. Publicação no GeoServer
        ↓
17. WebGIS
        ↓
18. Fiscalização
        ↓
19. Atualização e monitorização
```

---

## 41. Resultado Esperado

O **Módulo de Cadastro e Ordenamento Territorial** deverá funcionar como a infraestrutura digital central para gestão do território.

Em vez de existir apenas um conjunto de mapas, shapefiles, folhas Excel e documentos separados, a organização passa a possuir uma **Base Territorial Digital Única**, integrada com GIS.

A plataforma permitirá saber **o que existe, onde existe, qual é a situação atual, o que está previsto pelo plano, quais são as restrições, quem realizou determinada alteração e como o território evoluiu ao longo do tempo**.

A combinação de **Aplicação Web + App de Campo + API + PostGIS + QGIS + GeoServer + WebGIS** permitirá transformar o plano de ordenamento num sistema operacional, continuamente atualizado e utilizável para planeamento, cadastro, fiscalização e tomada de decisão.
