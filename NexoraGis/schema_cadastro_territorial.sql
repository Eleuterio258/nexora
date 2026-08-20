-- ============================================================
-- SCHEMA: Módulo de Cadastro e Ordenamento Territorial
-- Adaptado à divisão administrativa de Moçambique
-- SGBD: PostgreSQL 14+ com PostGIS 3.1+
-- ============================================================

-- ------------------------------------------------------------
-- 0. EXTENSÕES
-- ------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- 1. SCHEMAS
-- ------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS territorial;
CREATE SCHEMA IF NOT EXISTS cadastro;
CREATE SCHEMA IF NOT EXISTS gis;
CREATE SCHEMA IF NOT EXISTS workflow;
CREATE SCHEMA IF NOT EXISTS audit;

-- ------------------------------------------------------------
-- 2. TIPOS ENUM / LOOKUPS
-- ------------------------------------------------------------

-- Estados de projeto
CREATE TYPE territorial.project_status AS ENUM (
    'rascunho', 'levantamento', 'diagnostico', 'proposta',
    'em_revisao', 'aprovado', 'publicado', 'em_implementacao', 'arquivado'
);

-- Estados de workflow de aprovação
CREATE TYPE workflow.approval_status AS ENUM (
    'rascunho', 'submetido', 'em_analise', 'correcao_solicitada',
    'aprovado', 'rejeitado', 'publicado'
);

-- Tipos de divisão administrativa em Moçambique
CREATE TYPE territorial.tipo_divisao AS ENUM (
    'pais',
    'provincia',
    'cidade',                -- cidade autónoma / capital
    'municipio',             -- município com governo municipal
    'distrito',              -- distrito rural
    'distrito_municipal',    -- distrito municipal (urbano)
    'distrito_urbano',       -- distrito urbano dentro de cidade/município
    'posto_administrativo',  -- posto administrativo rural
    'posto_administrativo_urbano',
    'localidade',            -- localidade rural
    'bairro',                -- bairro urbano
    'quarteirao',            -- quarteirão urbano
    'aldeia',                -- aldeia rural
    'povoacao',              -- povoação rural
    'comunidade',            -- comunidade rural
    'unidade_planeamento',   -- unidade de planeamento técnica
    'outro'
);

-- Situação de parcela / ocupação
CREATE TYPE cadastro.situacao_parcela AS ENUM (
    'ocupada', 'desocupada', 'parcialmente_ocupada',
    'em_construcao', 'abandonada', 'em_conflito', 'reservada'
);

-- Uso do solo
CREATE TYPE cadastro.uso_solo AS ENUM (
    'habitacional', 'comercial', 'servicos', 'industrial',
    'agricola', 'institucional', 'recreativo', 'misto', 'outros'
);

-- Tipo de entidade relacionada
CREATE TYPE cadastro.tipo_entidade AS ENUM (
    'proprietario', 'ocupante', 'requerente', 'empresa',
    'instituicao_publica', 'associacao', 'concessionario'
);

-- Tipo de infraestrutura
CREATE TYPE cadastro.tipo_infraestrutura AS ENUM (
    'rede_viaria', 'agua', 'saneamento_drenagem',
    'energia', 'telecomunicacoes'
);

-- Tipo de levantamento
CREATE TYPE cadastro.tipo_levantamento AS ENUM (
    'gnss', 'gnss_rtk', 'estacao_total', 'gps_portatil',
    'aplicacao_movel', 'equipamento_externo', 'drone', 'satelite'
);

-- Tipo de documento
CREATE TYPE cadastro.tipo_documento AS ENUM (
    'planta', 'requerimento', 'relatorio', 'fotografia',
    'parecer', 'autorizacao', 'levantamento', 'anexo', 'outro'
);

-- Tipo de operação auditada
CREATE TYPE audit.tipo_operacao AS ENUM (
    'CREATE', 'UPDATE', 'DELETE', 'ALTERACAO_GEOMETRIA',
    'APROVACAO', 'REJEICAO', 'PUBLICACAO', 'LOGIN', 'LOGOUT'
);

-- Tipo de camada GIS
CREATE TYPE gis.tipo_camada AS ENUM (
    'vetorial', 'raster', 'ortofoto', 'modelo_terreno', 'pontos'
);

-- Tipo de conflito
CREATE TYPE territorial.tipo_conflito AS ENUM (
    'uso_incompativel', 'infracao_condicionante', 'sobreposicao',
    'fora_zoneamento', 'construcao_ilegal', 'outro'
);

-- ------------------------------------------------------------
-- 3. DIVISÃO ADMINISTRATIVA FLEXÍVEL (Moçambique)
-- ------------------------------------------------------------
--
-- Estrutura hierárquica configurável:
--
-- ZONA URBANA:
--   Província → Cidade/Município → Distrito municipal/urbano →
--   Posto administrativo urbano → Bairro → Quarteirão
--
-- ZONA RURAL:
--   Província → Distrito → Posto administrativo → Localidade →
--   Aldeia/Povoação → Comunidade
--
-- A tabela é autorreferenciada via parent_id, permitindo qualquer
-- profundidade hierárquica conforme a realidade local.
-- ------------------------------------------------------------

CREATE TABLE territorial.divisao_administrativa (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID REFERENCES territorial.divisao_administrativa(id) ON DELETE CASCADE,
    tipo territorial.tipo_divisao NOT NULL,
    codigo VARCHAR(30) UNIQUE NOT NULL,
    nome VARCHAR(200) NOT NULL,
    nome_normalizado VARCHAR(200),
    zona_urbana BOOLEAN, -- TRUE = urbano, FALSE = rural, NULL = misto/não aplicável
    nivel_hierarquico INT NOT NULL DEFAULT 0,
    entidade_responsavel VARCHAR(200),
    codigo_ine VARCHAR(50), -- código do INE quando disponível
    geometria GEOMETRY(MULTIPOLYGON, 4326),
    area_calculada NUMERIC(15, 2) GENERATED ALWAYS AS (
        CASE WHEN geometria IS NOT NULL THEN ST_Area(geometria::geography) / 10000 ELSE NULL END
    ) STORED,
    centroide GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (
        CASE WHEN geometria IS NOT NULL THEN ST_Centroid(geometria) END
    ) STORED,
    ativo BOOLEAN DEFAULT TRUE,
    metadados JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_divisao_parent ON territorial.divisao_administrativa(parent_id);
CREATE INDEX idx_divisao_tipo ON territorial.divisao_administrativa(tipo);
CREATE INDEX idx_divisao_zona ON territorial.divisao_administrativa(zona_urbana);
CREATE INDEX idx_divisao_geom ON territorial.divisao_administrativa USING GIST(geometria);
CREATE INDEX idx_divisao_codigo_ine ON territorial.divisao_administrativa(codigo_ine);

-- Garantir que o código seja único dentro do mesmo pai (opcional, descomentar se necessário)
-- CREATE UNIQUE INDEX idx_divisao_unique_codigo_parent
-- ON territorial.divisao_administrativa(parent_id, codigo) WHERE parent_id IS NOT NULL;

-- Vista hierárquica completa da divisão administrativa
CREATE OR REPLACE VIEW territorial.vw_divisao_hierarquia AS
WITH RECURSIVE hierarquia AS (
    SELECT
        id,
        parent_id,
        tipo,
        codigo,
        nome,
        zona_urbana,
        nivel_hierarquico,
        ARRAY[nome]::TEXT[] AS caminho,
        ARRAY[tipo::TEXT]::TEXT[] AS tipos_caminho,
        id::TEXT AS caminho_ids
    FROM territorial.divisao_administrativa
    WHERE parent_id IS NULL

    UNION ALL

    SELECT
        d.id,
        d.parent_id,
        d.tipo,
        d.codigo,
        d.nome,
        d.zona_urbana,
        d.nivel_hierarquico,
        h.caminho || d.nome,
        h.tipos_caminho || d.tipo::TEXT,
        h.caminho_ids || ' > ' || d.id::TEXT
    FROM territorial.divisao_administrativa d
    INNER JOIN hierarquia h ON d.parent_id = h.id
)
SELECT
    id,
    parent_id,
    tipo,
    codigo,
    nome,
    zona_urbana,
    nivel_hierarquico,
    array_to_string(caminho, ' > ') AS hierarquia_nomes,
    array_to_string(tipos_caminho, ' > ') AS hierarquia_tipos,
    caminho_ids
FROM hierarquia;

-- Função para obter divisões de um determinado tipo dentro de um território
CREATE OR REPLACE FUNCTION territorial.filhos_por_tipo(pai_id UUID, p_tipo territorial.tipo_divisao)
RETURNS TABLE(id UUID, codigo VARCHAR, nome VARCHAR, tipo territorial.tipo_divisao) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE arvore AS (
        SELECT d.id, d.parent_id, d.codigo, d.nome, d.tipo
        FROM territorial.divisao_administrativa d
        WHERE d.id = pai_id

        UNION ALL

        SELECT d.id, d.parent_id, d.codigo, d.nome, d.tipo
        FROM territorial.divisao_administrativa d
        INNER JOIN arvore a ON d.parent_id = a.id
    )
    SELECT a.id, a.codigo, a.nome, a.tipo
    FROM arvore a
    WHERE a.tipo = p_tipo AND a.id <> pai_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- ------------------------------------------------------------
-- 4. ORGANIZAÇÕES E UTILIZADORES
-- ------------------------------------------------------------

CREATE TABLE territorial.organizacao (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo VARCHAR(50) UNIQUE NOT NULL,
    designacao VARCHAR(200) NOT NULL,
    tipo VARCHAR(100) NOT NULL, -- municipio, governo_distrital, empresa, instituicao, consultora
    nif VARCHAR(50),
    email VARCHAR(200),
    telefone VARCHAR(50),
    endereco TEXT,
    divisao_administrativa_id UUID REFERENCES territorial.divisao_administrativa(id),
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE territorial.utilizador (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacao_id UUID NOT NULL REFERENCES territorial.organizacao(id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    nome_completo VARCHAR(200) NOT NULL,
    perfil VARCHAR(100) NOT NULL CHECK (perfil IN (
        'administrador', 'gestor_plano', 'planeador_territorial',
        'tecnico_gis', 'topografo', 'tecnico_campo', 'fiscal', 'consulta'
    )),
    telefone VARCHAR(50),
    ativo BOOLEAN DEFAULT TRUE,
    ultimo_acesso TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE territorial.permissao (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    perfil VARCHAR(100) NOT NULL,
    recurso VARCHAR(100) NOT NULL, -- parcels, buildings, projects, etc.
    acao VARCHAR(50) NOT NULL,     -- create, read, update, delete, approve
    ativo BOOLEAN DEFAULT TRUE,
    UNIQUE(perfil, recurso, acao)
);

-- ------------------------------------------------------------
-- 5. PROJETOS TERRITORIAIS
-- ------------------------------------------------------------

CREATE TABLE territorial.projeto (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacao_id UUID NOT NULL REFERENCES territorial.organizacao(id) ON DELETE CASCADE,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    designacao VARCHAR(300) NOT NULL,
    descricao TEXT,
    cliente VARCHAR(200),
    tipo VARCHAR(100) NOT NULL, -- plano_estrutura_urbana, pgu, ppu, pp, levantamento, etc.
    localizacao TEXT,
    divisao_administrativa_id UUID REFERENCES territorial.divisao_administrativa(id),
    area_intervencao GEOMETRY(MULTIPOLYGON, 4326),
    sistema_referencia VARCHAR(50) DEFAULT 'WGS84 / UTM 36S / 37S',
    responsavel_tecnico_id UUID REFERENCES territorial.utilizador(id),
    data_inicio DATE,
    data_prevista_conclusao DATE,
    status territorial.project_status DEFAULT 'rascunho',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES territorial.utilizador(id)
);
CREATE INDEX idx_projeto_geom ON territorial.projeto USING GIST(area_intervencao);
CREATE INDEX idx_projeto_divisao ON territorial.projeto(divisao_administrativa_id);

CREATE TABLE territorial.projeto_equipa (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    utilizador_id UUID NOT NULL REFERENCES territorial.utilizador(id) ON DELETE CASCADE,
    funcao VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(projeto_id, utilizador_id)
);

-- ------------------------------------------------------------
-- 6. ZONEAMENTO E PLANO
-- ------------------------------------------------------------

CREATE TABLE territorial.plano (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    codigo VARCHAR(50) NOT NULL,
    designacao VARCHAR(300) NOT NULL,
    versao VARCHAR(20) DEFAULT '1.0',
    data_aprovacao DATE,
    data_publicacao DATE,
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(projeto_id, codigo, versao)
);

CREATE TABLE territorial.zona (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plano_id UUID NOT NULL REFERENCES territorial.plano(id) ON DELETE CASCADE,
    codigo VARCHAR(20) NOT NULL, -- ZH, ZC, ZM, ZI, etc.
    designacao VARCHAR(200) NOT NULL,
    cor VARCHAR(7) DEFAULT '#000000',
    geometria GEOMETRY(MULTIPOLYGON, 4326),
    parametros JSONB, -- altura maxima, pisos, ocupacao, afastamentos, etc.
    atividades_permitidas TEXT[],
    atividades_condicionadas TEXT[],
    atividades_proibidas TEXT[],
    area_calculada NUMERIC(15, 2) GENERATED ALWAYS AS (
        CASE WHEN geometria IS NOT NULL THEN ST_Area(geometria::geography) / 10000 ELSE NULL END
    ) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(plano_id, codigo)
);
CREATE INDEX idx_zona_geom ON territorial.zona USING GIST(geometria);

-- ------------------------------------------------------------
-- 7. CADASTRO - PARCELAS
-- ------------------------------------------------------------

CREATE TABLE cadastro.parcela (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    codigo_cadastral VARCHAR(50) UNIQUE NOT NULL,
    numero_parcela VARCHAR(50),
    numero_talhao VARCHAR(50),

    -- Ligação flexível à divisão administrativa
    divisao_administrativa_id UUID REFERENCES territorial.divisao_administrativa(id),

    geometria GEOMETRY(MULTIPOLYGON, 4326) NOT NULL,
    centroide GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (ST_Centroid(geometria)) STORED,
    area_calculada NUMERIC(15, 2) GENERATED ALWAYS AS (ST_Area(geometria::geography)) STORED,
    perimetro NUMERIC(15, 2) GENERATED ALWAYS AS (ST_Perimeter(geometria::geography)) STORED,
    sistema_coordenadas VARCHAR(50) DEFAULT 'EPSG:4326',
    precisao_levantamento NUMERIC(10, 2),

    situacao cadastro.situacao_parcela DEFAULT 'desocupada',
    uso_atual cadastro.uso_solo,
    uso_previsto cadastro.uso_solo,
    classificacao_plano VARCHAR(100),
    parametros_urbanisticos JSONB,
    restricoes TEXT,
    condicionantes TEXT,

    estado workflow.approval_status DEFAULT 'rascunho',
    versao INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES territorial.utilizador(id),
    updated_by UUID REFERENCES territorial.utilizador(id)
);
CREATE INDEX idx_parcela_geom ON cadastro.parcela USING GIST(geometria);
CREATE INDEX idx_parcela_projeto ON cadastro.parcela(projeto_id);
CREATE INDEX idx_parcela_codigo ON cadastro.parcela(codigo_cadastral);
CREATE INDEX idx_parcela_divisao ON cadastro.parcela(divisao_administrativa_id);

-- Lotes
CREATE TABLE cadastro.lote (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parcela_id UUID NOT NULL REFERENCES cadastro.parcela(id) ON DELETE CASCADE,
    codigo VARCHAR(50) NOT NULL,
    geometria GEOMETRY(MULTIPOLYGON, 4326) NOT NULL,
    area_calculada NUMERIC(15, 2) GENERATED ALWAYS AS (ST_Area(geometria::geography)) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(parcela_id, codigo)
);
CREATE INDEX idx_lote_geom ON cadastro.lote USING GIST(geometria);

-- ------------------------------------------------------------
-- 8. PESSOAS E ENTIDADES
-- ------------------------------------------------------------

CREATE TABLE cadastro.entidade (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tipo cadastro.tipo_entidade NOT NULL,
    nome VARCHAR(300) NOT NULL,
    documento_identificacao VARCHAR(100),
    nuit VARCHAR(50), -- NUIT em vez de NIF (Moçambique)
    morada TEXT,
    telefone VARCHAR(50),
    email VARCHAR(200),
    dados_pessoais BOOLEAN DEFAULT FALSE,
    acesso_publico BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cadastro.parcela_entidade (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parcela_id UUID NOT NULL REFERENCES cadastro.parcela(id) ON DELETE CASCADE,
    entidade_id UUID NOT NULL REFERENCES cadastro.entidade(id) ON DELETE CASCADE,
    tipo_relacao cadastro.tipo_entidade NOT NULL,
    data_inicio DATE,
    data_fim DATE,
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(parcela_id, entidade_id, tipo_relacao, ativo)
);

-- ------------------------------------------------------------
-- 9. EDIFICAÇÕES
-- ------------------------------------------------------------

CREATE TABLE cadastro.edificacao (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parcela_id UUID NOT NULL REFERENCES cadastro.parcela(id) ON DELETE CASCADE,
    codigo VARCHAR(50) NOT NULL,
    localizacao TEXT,
    geometria GEOMETRY(MULTIPOLYGON, 4326),
    area_construida NUMERIC(15, 2),
    numero_pisos INT,
    tipo_construcao VARCHAR(100),
    finalidade cadastro.uso_solo,
    material_predominante VARCHAR(100),
    estado_conservacao VARCHAR(100),
    situacao_ocupacao VARCHAR(100),
    fotografias TEXT[],
    coordenadas GEOMETRY(POINT, 4326),
    data_levantamento DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(parcela_id, codigo)
);
CREATE INDEX idx_edificacao_geom ON cadastro.edificacao USING GIST(geometria);

-- ------------------------------------------------------------
-- 10. INFRAESTRUTURAS
-- ------------------------------------------------------------

CREATE TABLE cadastro.infraestrutura (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    tipo cadastro.tipo_infraestrutura NOT NULL,
    subtipo VARCHAR(100) NOT NULL, -- estrada, conduta, poste, torre, etc.
    codigo VARCHAR(50),
    designacao VARCHAR(200),
    geometria GEOMETRY(GEOMETRY, 4326), -- pode ser ponto, linha ou polígono
    atributos JSONB,
    estado_conservacao VARCHAR(100),
    data_levantamento DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_infraestrutura_geom ON cadastro.infraestrutura USING GIST(geometria);
CREATE INDEX idx_infraestrutura_tipo ON cadastro.infraestrutura(projeto_id, tipo);

-- ------------------------------------------------------------
-- 11. EQUIPAMENTOS E SERVIÇOS PÚBLICOS
-- ------------------------------------------------------------

CREATE TABLE cadastro.equipamento (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    tipo VARCHAR(100) NOT NULL, -- escola, hospital, mercado, etc.
    codigo VARCHAR(50),
    nome VARCHAR(200) NOT NULL,
    geometria GEOMETRY(POINT, 4326),
    morada TEXT,
    contacto VARCHAR(100),
    horario_funcionamento TEXT,
    capacidade INT,
    atributos JSONB,
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_equipamento_geom ON cadastro.equipamento USING GIST(geometria);

-- ------------------------------------------------------------
-- 12. CONDICIONANTES TERRITORIAIS
-- ------------------------------------------------------------

CREATE TABLE cadastro.condicionante (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    tipo VARCHAR(100) NOT NULL, -- linha_agua, zona_inundavel, encosta, etc.
    designacao VARCHAR(200),
    descricao TEXT,
    geometria GEOMETRY(GEOMETRY, 4326),
    buffer_metros NUMERIC(10, 2),
    restritivo BOOLEAN DEFAULT TRUE,
    atributos JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_condicionante_geom ON cadastro.condicionante USING GIST(geometria);

-- ------------------------------------------------------------
-- 13. LEVANTAMENTOS DE CAMPO
-- ------------------------------------------------------------

CREATE TABLE cadastro.levantamento (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    designacao VARCHAR(300),
    responsavel_id UUID REFERENCES territorial.utilizador(id),
    tipo cadastro.tipo_levantamento NOT NULL,
    equipamento_utilizado VARCHAR(200),
    metodo VARCHAR(200),
    data_inicio TIMESTAMPTZ,
    data_fim TIMESTAMPTZ,
    status VARCHAR(50) DEFAULT 'em_curso',
    observacoes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cadastro.ponto_levantamento (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    levantamento_id UUID NOT NULL REFERENCES cadastro.levantamento(id) ON DELETE CASCADE,
    codigo VARCHAR(50),
    geometria GEOMETRY(POINT, 4326) NOT NULL,
    altitude NUMERIC(10, 2),
    precisao_horizontal NUMERIC(10, 3),
    precisao_vertical NUMERIC(10, 3),
    latitude NUMERIC(15, 8),
    longitude NUMERIC(15, 8),
    sistema_referencia VARCHAR(50),
    operador VARCHAR(200),
    data_hora TIMESTAMPTZ,
    fotografias TEXT[],
    observacoes TEXT,
    sincronizado BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_ponto_lev_geom ON cadastro.ponto_levantamento USING GIST(geometria);

-- ------------------------------------------------------------
-- 14. DOCUMENTOS
-- ------------------------------------------------------------

CREATE TABLE cadastro.documento (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    tipo cadastro.tipo_documento NOT NULL,
    titulo VARCHAR(300) NOT NULL,
    descricao TEXT,
    entidade_tipo VARCHAR(100), -- parcela, edificacao, projeto, plano, etc.
    entidade_id UUID,           -- id da entidade referenciada
    ficheiro_url TEXT,
    ficheiro_nome VARCHAR(300),
    ficheiro_tamanho BIGINT,
    ficheiro_hash VARCHAR(128),
    mime_type VARCHAR(100),
    armazenamento_objeto BOOLEAN DEFAULT FALSE,
    acesso_publico BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES territorial.utilizador(id)
);
CREATE INDEX idx_documento_entidade ON cadastro.documento(entidade_tipo, entidade_id);

-- ------------------------------------------------------------
-- 15. WORKFLOW DE APROVAÇÃO
-- ------------------------------------------------------------

CREATE TABLE workflow.aprovacao (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entidade_tipo VARCHAR(100) NOT NULL, -- parcela, edificacao, plano, etc.
    entidade_id UUID NOT NULL,
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    status workflow.approval_status DEFAULT 'rascunho',
    requisitado_por UUID REFERENCES territorial.utilizador(id),
    verificado_por UUID REFERENCES territorial.utilizador(id),
    aprovado_por UUID REFERENCES territorial.utilizador(id),
    data_submissao TIMESTAMPTZ,
    data_analise TIMESTAMPTZ,
    data_aprovacao TIMESTAMPTZ,
    data_publicacao TIMESTAMPTZ,
    motivo_rejeicao TEXT,
    observacoes TEXT,
    versao INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_aprovacao_entidade ON workflow.aprovacao(entidade_tipo, entidade_id);

-- ------------------------------------------------------------
-- 16. VERSIONAMENTO DE GEOMETRIAS
-- ------------------------------------------------------------

CREATE TABLE territorial.geometria_historico (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entidade_tipo VARCHAR(100) NOT NULL, -- parcela, zona, infraestrutura, etc.
    entidade_id UUID NOT NULL,
    projeto_id UUID REFERENCES territorial.projeto(id),
    geometria_anterior GEOMETRY(GEOMETRY, 4326),
    geometria_nova GEOMETRY(GEOMETRY, 4326),
    utilizador_id UUID REFERENCES territorial.utilizador(id),
    data_alteracao TIMESTAMPTZ DEFAULT NOW(),
    motivo TEXT,
    versao_anterior INT,
    versao_nova INT,
    aprovacao_id UUID REFERENCES workflow.aprovacao(id)
);
CREATE INDEX idx_geom_hist_entidade ON territorial.geometria_historico(entidade_tipo, entidade_id);

-- ------------------------------------------------------------
-- 17. CONFLITOS TERRITORIAIS
-- ------------------------------------------------------------

CREATE TABLE territorial.conflito (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    tipo territorial.tipo_conflito NOT NULL,
    descricao TEXT NOT NULL,
    entidade_tipo VARCHAR(100), -- parcela, edificacao
    entidade_id UUID,
    geometria GEOMETRY(GEOMETRY, 4326),
    detalhes JSONB,
    resolvido BOOLEAN DEFAULT FALSE,
    data_detecao TIMESTAMPTZ DEFAULT NOW(),
    data_resolucao TIMESTAMPTZ,
    resolvido_por UUID REFERENCES territorial.utilizador(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_conflito_geom ON territorial.conflito USING GIST(geometria);

-- ------------------------------------------------------------
-- 18. FISCALIZAÇÃO
-- ------------------------------------------------------------

CREATE TABLE territorial.fiscalizacao (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID NOT NULL REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    parcela_id UUID REFERENCES cadastro.parcela(id) ON DELETE SET NULL,
    fiscal_id UUID REFERENCES territorial.utilizador(id),
    data_ocorrencia TIMESTAMPTZ DEFAULT NOW(),
    coordenadas GEOMETRY(POINT, 4326),
    descricao TEXT NOT NULL,
    fotografias TEXT[],
    estado VARCHAR(50) DEFAULT 'aberto',
    acao_necessaria TEXT,
    responsavel UUID REFERENCES territorial.utilizador(id),
    data_resolucao TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_fiscalizacao_geom ON territorial.fiscalizacao USING GIST(coordenadas);

-- ------------------------------------------------------------
-- 19. CATÁLOGO DE CAMADAS GIS
-- ------------------------------------------------------------

CREATE TABLE gis.camada (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projeto_id UUID REFERENCES territorial.projeto(id) ON DELETE CASCADE,
    nome VARCHAR(200) NOT NULL,
    tipo gis.tipo_camada NOT NULL,
    tabela_fonte VARCHAR(200), -- nome da tabela física
    coluna_geometria VARCHAR(100) DEFAULT 'geometria',
    estilo JSONB,
    metadados JSONB,
    responsavel_id UUID REFERENCES territorial.utilizador(id),
    fonte VARCHAR(300),
    data_atualizacao DATE,
    sistema_coordenadas VARCHAR(50) DEFAULT 'EPSG:4326',
    versao VARCHAR(20) DEFAULT '1.0',
    visivel BOOLEAN DEFAULT TRUE,
    publica BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 20. AUDITORIA
-- ------------------------------------------------------------

CREATE TABLE audit.log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilizador_id UUID REFERENCES territorial.utilizador(id),
    utilizador_nome VARCHAR(200),
    operacao audit.tipo_operacao NOT NULL,
    entidade_tipo VARCHAR(100) NOT NULL,
    entidade_id UUID,
    projeto_id UUID REFERENCES territorial.projeto(id),
    dados_anteriores JSONB,
    dados_novos JSONB,
    ip_address INET,
    data_hora TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_audit_entidade ON audit.log(entidade_tipo, entidade_id);
CREATE INDEX idx_audit_data ON audit.log(data_hora);

-- ------------------------------------------------------------
-- 21. FUNÇÕES AUXILIARES
-- ------------------------------------------------------------

-- Função para calcular área em hectares
CREATE OR REPLACE FUNCTION territorial.area_hectares(geom GEOMETRY)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND((ST_Area(geom::geography) / 10000)::NUMERIC, 4);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para obter hierarquia completa de uma divisão administrativa
CREATE OR REPLACE FUNCTION territorial.hierarquia_divisao(p_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_nome TEXT;
    v_pai UUID;
    v_tipo TEXT;
    v_caminho TEXT;
BEGIN
    SELECT nome, parent_id, tipo::TEXT
    INTO v_nome, v_pai, v_tipo
    FROM territorial.divisao_administrativa
    WHERE id = p_id;

    v_caminho := v_tipo || ':' || v_nome;

    WHILE v_pai IS NOT NULL LOOP
        SELECT nome, parent_id, tipo::TEXT
        INTO v_nome, v_pai, v_tipo
        FROM territorial.divisao_administrativa
        WHERE id = v_pai;

        v_caminho := v_tipo || ':' || v_nome || ' > ' || v_caminho;
    END LOOP;

    RETURN v_caminho;
END;
$$ LANGUAGE plpgsql STABLE;

-- Função para detectar conflito de uso
CREATE OR REPLACE FUNCTION territorial.detectar_conflito_uso(parcela_uuid UUID)
RETURNS TABLE(tipo TEXT, descricao TEXT) AS $$
DECLARE
    p_uso_atual cadastro.uso_solo;
    p_uso_previsto cadastro.uso_solo;
    p_geom GEOMETRY;
    p_codigo VARCHAR;
BEGIN
    SELECT uso_atual, uso_previsto, geometria, codigo_cadastral
    INTO p_uso_atual, p_uso_previsto, p_geom, p_codigo
    FROM cadastro.parcela WHERE id = parcela_uuid;

    IF p_uso_atual IS DISTINCT FROM p_uso_previsto AND p_uso_previsto IS NOT NULL THEN
        RETURN QUERY SELECT 'uso_incompativel'::TEXT,
            format('Parcela %s: uso atual (%s) difere do previsto (%s)', p_codigo, p_uso_atual, p_uso_previsto)::TEXT;
    END IF;

    RETURN;
END;
$$ LANGUAGE plpgsql STABLE;

-- ------------------------------------------------------------
-- 22. TRIGGERS DE AUDITORIA
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION audit.log_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_dados_anteriores JSONB;
    v_dados_novos JSONB;
    v_operacao audit.tipo_operacao;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_operacao := 'CREATE';
        v_dados_novos := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        v_operacao := 'UPDATE';
        v_dados_anteriores := to_jsonb(OLD);
        v_dados_novos := to_jsonb(NEW);

        -- Se geometria mudou, registar como ALTERACAO_GEOMETRIA
        IF OLD.geometria IS DISTINCT FROM NEW.geometria THEN
            v_operacao := 'ALTERACAO_GEOMETRIA';
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        v_operacao := 'DELETE';
        v_dados_anteriores := to_jsonb(OLD);
    END IF;

    INSERT INTO audit.log (operacao, entidade_tipo, entidade_id, dados_anteriores, dados_novos)
    VALUES (v_operacao, TG_TABLE_NAME, COALESCE(NEW.id, OLD.id), v_dados_anteriores, v_dados_novos);

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Aplicar auditoria às tabelas principais
CREATE TRIGGER trg_audit_parcela
AFTER INSERT OR UPDATE OR DELETE ON cadastro.parcela
FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

CREATE TRIGGER trg_audit_edificacao
AFTER INSERT OR UPDATE OR DELETE ON cadastro.edificacao
FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

CREATE TRIGGER trg_audit_zona
AFTER INSERT OR UPDATE OR DELETE ON territorial.zona
FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

CREATE TRIGGER trg_audit_infraestrutura
AFTER INSERT OR UPDATE OR DELETE ON cadastro.infraestrutura
FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

CREATE TRIGGER trg_audit_divisao_administrativa
AFTER INSERT OR UPDATE OR DELETE ON territorial.divisao_administrativa
FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

-- ------------------------------------------------------------
-- 23. VIEWS ÚTEIS
-- ------------------------------------------------------------

-- View de parcelas com dados territoriais completos
CREATE OR REPLACE VIEW cadastro.vw_parcela_completa AS
SELECT
    p.id,
    p.codigo_cadastral,
    p.numero_parcela,
    p.numero_talhao,
    p.divisao_administrativa_id,
    d.tipo AS tipo_divisao,
    d.nome AS nome_divisao,
    d.codigo AS codigo_divisao,
    territorial.hierarquia_divisao(d.id) AS hierarquia_completa,
    p.geometria,
    p.area_calculada,
    p.perimetro,
    p.centroide,
    p.situacao,
    p.uso_atual,
    p.uso_previsto,
    p.estado,
    p.versao,
    p.created_at,
    p.updated_at
FROM cadastro.parcela p
LEFT JOIN territorial.divisao_administrativa d ON p.divisao_administrativa_id = d.id;

-- View de divisões urbanas
CREATE OR REPLACE VIEW territorial.vw_divisoes_urbanas AS
SELECT *
FROM territorial.divisao_administrativa
WHERE zona_urbana = TRUE;

-- View de divisões rurais
CREATE OR REPLACE VIEW territorial.vw_divisoes_rurais AS
SELECT *
FROM territorial.divisao_administrativa
WHERE zona_urbana = FALSE;

-- View de conflitos ativos por projeto
CREATE OR REPLACE VIEW territorial.vw_conflitos_ativos AS
SELECT
    c.id,
    c.projeto_id,
    c.tipo,
    c.descricao,
    c.entidade_tipo,
    c.entidade_id,
    c.data_detecao,
    c.resolvido
FROM territorial.conflito c
WHERE c.resolvido = FALSE;

-- ------------------------------------------------------------
-- 24. DADOS INICIAIS
-- ------------------------------------------------------------

-- País: Moçambique
INSERT INTO territorial.divisao_administrativa (tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
VALUES ('pais', 'MZ', 'Moçambique', 'mocambique', 0, NULL);

-- Províncias de Moçambique (exemplos)
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT id, 'provincia', codigo, nome, lower(unaccent(nome)), 1, NULL
FROM (VALUES
    ('MAPUTO', 'Maputo'),
    ('GAZA', 'Gaza'),
    ('INHAMBANE', 'Inhambane'),
    ('SOFALA', 'Sofala'),
    ('MANICA', 'Manica'),
    ('TETE', 'Tete'),
    ('ZAMBEZIA', 'Zambézia'),
    ('NAMPULA', 'Nampula'),
    ('CABO_DELGADO', 'Cabo Delgado'),
    ('NIASSA', 'Niassa')
) AS p(codigo, nome)
CROSS JOIN territorial.divisao_administrativa raiz
WHERE raiz.tipo = 'pais' AND raiz.codigo = 'MZ';

-- Permissões base por perfil
INSERT INTO territorial.permissao (perfil, recurso, acao) VALUES
('administrador', '*', '*'),
('gestor_plano', 'projects', 'create'),
('gestor_plano', 'projects', 'read'),
('gestor_plano', 'projects', 'update'),
('gestor_plano', 'projects', 'approve'),
('planeador_territorial', 'zones', 'create'),
('planeador_territorial', 'zones', 'read'),
('planeador_territorial', 'zones', 'update'),
('tecnico_gis', 'parcels', 'create'),
('tecnico_gis', 'parcels', 'read'),
('tecnico_gis', 'parcels', 'update'),
('topografo', 'surveys', 'create'),
('topografo', 'surveys', 'read'),
('tecnico_campo', 'surveys', 'create'),
('tecnico_campo', 'parcels', 'read'),
('fiscal', 'fiscalizacao', 'create'),
('fiscal', 'parcels', 'read'),
('consulta', '*', 'read');

-- ------------------------------------------------------------
-- FIM DO SCHEMA
-- ------------------------------------------------------------
