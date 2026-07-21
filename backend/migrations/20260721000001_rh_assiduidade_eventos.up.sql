-- Sistema flexível de controlo de assiduidade
-- Modelo baseado em eventos independentes, horários flexíveis, regras configuráveis,
-- correcções com aprovação, resultados desacoplados e auditoria completa.

SET search_path TO rh, public;

-- ═══════════════════════════════════════════════════════════════════
-- 1. Catálogos configuráveis
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS tipos_evento (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    categoria VARCHAR(40) NOT NULL DEFAULT 'marcacao'
        CHECK (categoria IN ('marcacao', 'ausencia', 'justificacao', 'presenca')),
    sentido VARCHAR(20)
        CHECK (sentido IN ('inicio', 'fim', 'unico')),
    tipo_par VARCHAR(50),
    afeta_calculo VARCHAR(20) DEFAULT 'nenhum'
        CHECK (afeta_calculo IN ('trabalho', 'intervalo', 'ausencia', 'remoto', 'extra', 'missao', 'formacao', 'nenhum')),
    cor VARCHAR(10),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tipos_evento_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE INDEX IF NOT EXISTS idx_tipos_evento_tenant_id ON tipos_evento (tenant_id);

CREATE TABLE IF NOT EXISTS metodos_marcacao (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    requer_dispositivo BOOLEAN NOT NULL DEFAULT FALSE,
    requer_localizacao BOOLEAN NOT NULL DEFAULT FALSE,
    requer_selfie BOOLEAN NOT NULL DEFAULT FALSE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_metodos_marcacao_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE INDEX IF NOT EXISTS idx_metodos_marcacao_tenant_id ON metodos_marcacao (tenant_id);

CREATE TABLE IF NOT EXISTS tipos_regra (
    id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    parametros JSONB NOT NULL DEFAULT '{}',
    tipo_valor VARCHAR(20) NOT NULL DEFAULT 'jsonb'
        CHECK (tipo_valor IN ('numero', 'hora', 'booleano', 'jsonb'))
);

-- ═══════════════════════════════════════════════════════════════════
-- 2. Horários flexíveis
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE horarios_trabalho
    ADD COLUMN IF NOT EXISTS tipo VARCHAR(40) NOT NULL DEFAULT 'fixo'
        CHECK (tipo IN ('fixo', 'flexivel', 'turno', 'rotativo', 'escala', 'remoto', 'sem_horario')),
    ADD COLUMN IF NOT EXISTS contagem VARCHAR(20) NOT NULL DEFAULT 'diaria'
        CHECK (contagem IN ('diaria', 'semanal', 'mensal')),
    ADD COLUMN IF NOT EXISTS carga_diaria_minima INTERVAL,
    ADD COLUMN IF NOT EXISTS carga_diaria_maxima INTERVAL,
    ADD COLUMN IF NOT EXISTS carga_semanal INTERVAL,
    ADD COLUMN IF NOT EXISTS janela_entrada_inicio INTERVAL,
    ADD COLUMN IF NOT EXISTS janela_entrada_fim INTERVAL;

CREATE TABLE IF NOT EXISTS horarios_dias (
    id BIGSERIAL PRIMARY KEY,
    horario_id BIGINT NOT NULL REFERENCES horarios_trabalho(id) ON DELETE CASCADE,
    dia_semana SMALLINT CHECK (dia_semana BETWEEN 1 AND 7),
    data_especifica DATE,
    ordem SMALLINT NOT NULL DEFAULT 1,
    hora_entrada INTERVAL NOT NULL,
    hora_saida INTERVAL NOT NULL,
    intervalo_inicio INTERVAL,
    intervalo_fim INTERVAL,
    tolerancia_atraso INTERVAL DEFAULT '0',
    tolerancia_saida_antecipada INTERVAL DEFAULT '0',
    eh_nocturno BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_horarios_dias_dia_ou_data CHECK (
        (dia_semana IS NOT NULL AND data_especifica IS NULL) OR
        (dia_semana IS NULL AND data_especifica IS NOT NULL)
    ),
    CONSTRAINT uq_horarios_dias_horario_dia_ordem UNIQUE (horario_id, dia_semana, data_especifica, ordem)
);
CREATE INDEX IF NOT EXISTS idx_horarios_dias_horario_id ON horarios_dias (horario_id);

CREATE TABLE IF NOT EXISTS funcionario_horarios (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    horario_id BIGINT NOT NULL REFERENCES horarios_trabalho(id),
    data_inicio DATE NOT NULL,
    data_fim DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_funcionario_horarios_tenant_func_inicio UNIQUE (tenant_id, funcionario_id, data_inicio)
);
CREATE INDEX IF NOT EXISTS idx_funcionario_horarios_funcionario_id ON funcionario_horarios (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_funcionario_horarios_horario_id ON funcionario_horarios (horario_id);

-- ═══════════════════════════════════════════════════════════════════
-- 3. Eventos de assiduidade
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS eventos_assiduidade (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    tipo_evento_id BIGINT NOT NULL REFERENCES tipos_evento(id),
    metodo_id BIGINT REFERENCES metodos_marcacao(id),
    ocorrido_em TIMESTAMPTZ NOT NULL,
    data_referencia DATE NOT NULL,
    origem VARCHAR(40) NOT NULL DEFAULT 'manual'
        CHECK (origem IN ('biometria', 'impressao_digital', 'reconhecimento_facial', 'rfid', 'nfc', 'qr', 'app', 'web', 'gps', 'geofence', 'selfie', 'manual', 'importacao', 'api')),
    dispositivo_id BIGINT,
    qr_token_id BIGINT,
    nfc_tag_id BIGINT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    localidade_id BIGINT,
    dentro_geofence BOOLEAN,
    foto_url TEXT,
    documento_url TEXT,
    estado VARCHAR(30) NOT NULL DEFAULT 'valido'
        CHECK (estado IN ('valido', 'pendente', 'aprovado', 'rejeitado', 'corrigido', 'duplicado', 'incompleto', 'fora_horario', 'fora_localizacao', 'manual', 'importado', 'em_analise')),
    registado_por BIGINT REFERENCES auth.users(id),
    motivo TEXT,
    observacoes TEXT,
    evento_pai_id BIGINT REFERENCES eventos_assiduidade(id),
    duplicado_de_id BIGINT REFERENCES eventos_assiduidade(id),
    ip_origem INET,
    user_agent TEXT,
    hash_digital VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_func_data ON eventos_assiduidade (funcionario_id, data_referencia, ocorrido_em);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_tenant_data ON eventos_assiduidade (tenant_id, data_referencia);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_estado ON eventos_assiduidade (estado);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_metodo ON eventos_assiduidade (metodo_id);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_origem ON eventos_assiduidade (origem);

-- ═══════════════════════════════════════════════════════════════════
-- 4. Resultados calculados
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS resultados_diarios (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    data_referencia DATE NOT NULL,
    horario_id BIGINT REFERENCES horarios_trabalho(id),
    horas_trabalhadas INTERVAL,
    horas_normais INTERVAL,
    horas_extra INTERVAL,
    horas_nocturnas INTERVAL,
    horas_remoto INTERVAL,
    horas_missao INTERVAL,
    horas_formacao INTERVAL,
    horas_intervalo INTERVAL,
    horas_nao_contabilizadas INTERVAL,
    atraso_minutos INTEGER NOT NULL DEFAULT 0,
    saida_antecipada_minutos INTEGER NOT NULL DEFAULT 0,
    ausencia BOOLEAN NOT NULL DEFAULT FALSE,
    falta_justificada BOOLEAN NOT NULL DEFAULT FALSE,
    falta_injustificada BOOLEAN NOT NULL DEFAULT FALSE,
    saldo_diario INTERVAL,
    saldo_semanal INTERVAL,
    saldo_mensal INTERVAL,
    banco_horas INTERVAL,
    versao_regra INTEGER NOT NULL DEFAULT 1,
    recalculado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_resultados_diarios_tenant_func_data UNIQUE (tenant_id, funcionario_id, data_referencia)
);
CREATE INDEX IF NOT EXISTS idx_resultados_diarios_func_data ON resultados_diarios (funcionario_id, data_referencia);
CREATE INDEX IF NOT EXISTS idx_resultados_diarios_tenant_data ON resultados_diarios (tenant_id, data_referencia);

CREATE TABLE IF NOT EXISTS resultados_periodos (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    tipo_periodo VARCHAR(20) NOT NULL
        CHECK (tipo_periodo IN ('semana', 'mes')),
    ano SMALLINT NOT NULL,
    numero SMALLINT NOT NULL,
    horas_normais INTERVAL,
    horas_extra INTERVAL,
    horas_nocturnas INTERVAL,
    horas_remoto INTERVAL,
    horas_missao INTERVAL,
    atrasos_minutos INTEGER NOT NULL DEFAULT 0,
    faltas INTEGER NOT NULL DEFAULT 0,
    saldo INTERVAL,
    recalculado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_resultados_periodos_tenant_func_tipo_ano_num UNIQUE (tenant_id, funcionario_id, tipo_periodo, ano, numero)
);
CREATE INDEX IF NOT EXISTS idx_resultados_periodos_func_ano ON resultados_periodos (funcionario_id, ano, numero);

-- ═══════════════════════════════════════════════════════════════════
-- 5. Regras configuráveis
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS regras_assiduidade (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tipo_regra_id BIGINT NOT NULL REFERENCES tipos_regra(id),
    ambito VARCHAR(20) NOT NULL
        CHECK (ambito IN ('empresa', 'filial', 'local', 'departamento', 'cargo', 'equipa', 'turno', 'funcionario', 'contrato')),
    entidade_id BIGINT,
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    valor JSONB NOT NULL DEFAULT '{}',
    prioridade SMALLINT NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_regras_assiduidade_tenant_tipo_ambito_entidade_inicio UNIQUE (tenant_id, tipo_regra_id, ambito, entidade_id, data_inicio)
);
CREATE INDEX IF NOT EXISTS idx_regras_assiduidade_tenant_tipo ON regras_assiduidade (tenant_id, tipo_regra_id);
CREATE INDEX IF NOT EXISTS idx_regras_assiduidade_ambito_entidade ON regras_assiduidade (ambito, entidade_id);

-- ═══════════════════════════════════════════════════════════════════
-- 6. Correcções e ajustes
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS correcoes_evento (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    evento_id BIGINT REFERENCES eventos_assiduidade(id),
    data_referencia DATE NOT NULL,
    tipo VARCHAR(40) NOT NULL,
    tipo_evento_id BIGINT REFERENCES tipos_evento(id),
    ocorrido_em_solicitado TIMESTAMPTZ,
    localidade_id_solicitada BIGINT,
    motivo TEXT NOT NULL,
    documento_url TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendente'
        CHECK (estado IN ('pendente', 'aprovado', 'rejeitado')),
    solicitado_por BIGINT NOT NULL REFERENCES auth.users(id),
    solicitado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    decidido_por BIGINT REFERENCES auth.users(id),
    decidido_em TIMESTAMPTZ,
    justificacao_decisao TEXT,
    evento_gerado_id BIGINT REFERENCES eventos_assiduidade(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_correcoes_evento_funcionario ON correcoes_evento (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_correcoes_evento_tenant_estado ON correcoes_evento (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_correcoes_evento_evento_id ON correcoes_evento (evento_id);

-- ═══════════════════════════════════════════════════════════════════
-- 7. Auditoria
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS auditoria_assiduidade (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tabela VARCHAR(50) NOT NULL,
    registo_id BIGINT NOT NULL,
    operacao VARCHAR(10) NOT NULL
        CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    campo VARCHAR(100),
    valor_anterior JSONB,
    valor_novo JSONB,
    alterado_por BIGINT REFERENCES auth.users(id),
    motivo TEXT,
    ip_origem INET,
    dispositivo TEXT,
    localizacao VARCHAR(200),
    estado_anterior VARCHAR(30),
    estado_novo VARCHAR(30),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_auditoria_assiduidade_registo ON auditoria_assiduidade (tabela, registo_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_assiduidade_tenant_data ON auditoria_assiduidade (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_auditoria_assiduidade_operacao ON auditoria_assiduidade (operacao);

-- ═══════════════════════════════════════════════════════════════════
-- 8. Seeds de catálogos padrão
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO tipos_regra (codigo, nome, descricao, parametros, tipo_valor) VALUES
('tolerancia_atraso', 'Tolerância de atraso', 'Minutos de tolerância antes de considerar atraso.', '{"minutos": {"tipo": "inteiro", "min": 0, "default": 10}}', 'jsonb'),
('intervalo_obrigatorio', 'Intervalo obrigatório', 'Intervalo obrigatório após X horas de trabalho.', '{"apos_horas": {"tipo": "decimal", "min": 0, "default": 5}, "duracao_minima": {"tipo": "inteiro", "min": 0, "default": 30}}', 'jsonb'),
('carga_minima', 'Carga mínima diária', 'Mínimo de horas de trabalho por dia.', '{"horas": {"tipo": "decimal", "min": 0, "default": 8}}', 'jsonb'),
('carga_maxima', 'Carga máxima diária', 'Máximo de horas de trabalho por dia.', '{"horas": {"tipo": "decimal", "min": 0, "default": 8}}', 'jsonb'),
('max_horas_extra', 'Máximo de horas extra', 'Máximo de horas extra por período.', '{"horas": {"tipo": "decimal", "min": 0, "default": 2}, "periodo": {"tipo": "string", "opcoes": ["dia", "semana", "mes"], "default": "dia"}}', 'jsonb'),
('marcacao_somente_empresa', 'Marcação apenas dentro da empresa', 'Restringe marcações ao interior do geofence.', '{"ativo": {"tipo": "booleano", "default": true}}', 'jsonb'),
('marcacao_remota_permitida', 'Marcação remota permitida', 'Permite marcação remota para determinados funcionários.', '{"ativo": {"tipo": "booleano", "default": false}}', 'jsonb'),
('manual_sujeito_aprovacao', 'Registo manual sujeito a aprovação', 'Todos os registos manuais requerem aprovação.', '{"ativo": {"tipo": "booleano", "default": true}}', 'jsonb'),
('trabalho_nocturno', 'Trabalho nocturno', 'Regras de cálculo para trabalho nocturno.', '{"inicio_noite": {"tipo": "hora", "default": "22:00"}, "fim_noite": {"tipo": "hora", "default": "06:00"}, "fator": {"tipo": "decimal", "default": 1.25}}', 'jsonb'),
('extra_aprovacao', 'Horas extra sujeitas a aprovação', 'Horas extra só contam após aprovação.', '{"ativo": {"tipo": "booleano", "default": true}}', 'jsonb'),
('ausencia_apos_periodo', 'Ausência após período sem registo', 'Gera ausência/falta após X tempo sem marcação.', '{"horas": {"tipo": "decimal", "min": 0, "default": 4}}', 'jsonb'),
('tolerancia_saida_antecipada', 'Tolerância de saída antecipada', 'Minutos de tolerância antes de considerar saída antecipada.', '{"minutos": {"tipo": "inteiro", "min": 0, "default": 10}}', 'jsonb')
ON CONFLICT (codigo) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════
-- 9. Seed de tipos de evento e métodos de marcação padrão por tenant
-- ═══════════════════════════════════════════════════════════════════

WITH tenants_existentes AS (
    SELECT DISTINCT tenant_id FROM funcionarios
    UNION
    SELECT DISTINCT tenant_id FROM horarios_trabalho
)
INSERT INTO tipos_evento (tenant_id, codigo, nome, categoria, sentido, tipo_par, afeta_calculo, cor)
SELECT
    t.tenant_id,
    d.codigo,
    d.nome,
    d.categoria,
    d.sentido,
    d.tipo_par,
    d.afeta_calculo,
    d.cor
FROM tenants_existentes t
CROSS JOIN (VALUES
    ('entrada', 'Entrada', 'marcacao', 'inicio', 'saida', 'trabalho', '#4CAF50'),
    ('saida', 'Saída', 'marcacao', 'fim', 'entrada', 'trabalho', '#F44336'),
    ('intervalo_inicio', 'Início do intervalo', 'marcacao', 'inicio', 'intervalo_fim', 'intervalo', '#FF9800'),
    ('intervalo_fim', 'Fim do intervalo', 'marcacao', 'fim', 'intervalo_inicio', 'intervalo', '#FF9800'),
    ('saida_temporaria', 'Saída temporária', 'marcacao', 'inicio', 'regresso_temporaria', 'nenhum', '#FFC107'),
    ('regresso_temporaria', 'Regresso de saída temporária', 'marcacao', 'fim', 'saida_temporaria', 'trabalho', '#FFC107'),
    ('remoto_inicio', 'Início de trabalho remoto', 'marcacao', 'inicio', 'remoto_fim', 'remoto', '#2196F3'),
    ('remoto_fim', 'Fim de trabalho remoto', 'marcacao', 'fim', 'remoto_inicio', 'remoto', '#2196F3'),
    ('missao_inicio', 'Início de missão de serviço', 'marcacao', 'inicio', 'missao_fim', 'missao', '#9C27B0'),
    ('missao_fim', 'Fim de missão de serviço', 'marcacao', 'fim', 'missao_inicio', 'missao', '#9C27B0'),
    ('extra_inicio', 'Início de horas extraordinárias', 'marcacao', 'inicio', 'extra_fim', 'extra', '#673AB7'),
    ('extra_fim', 'Fim de horas extraordinárias', 'marcacao', 'fim', 'extra_inicio', 'extra', '#673AB7'),
    ('formacao', 'Presença em formação', 'presenca', 'unico', NULL, 'formacao', '#00BCD4'),
    ('evento', 'Presença em evento', 'presenca', 'unico', NULL, 'formacao', '#00BCD4'),
    ('visita', 'Visita externa', 'presenca', 'unico', NULL, 'trabalho', '#795548'),
    ('cliente', 'Trabalho num cliente', 'presenca', 'unico', NULL, 'trabalho', '#795548'),
    ('falta_justificada', 'Falta justificada', 'ausencia', 'unico', NULL, 'ausencia', '#E91E63'),
    ('falta_injustificada', 'Falta injustificada', 'ausencia', 'unico', NULL, 'ausencia', '#E91E63'),
    ('dispensa', 'Dispensa', 'ausencia', 'unico', NULL, 'ausencia', '#9E9E9E'),
    ('licenca', 'Licença', 'ausencia', 'unico', NULL, 'ausencia', '#9E9E9E'),
    ('ferias', 'Férias', 'ausencia', 'unico', NULL, 'ausencia', '#3F51B5'),
    ('baixa', 'Baixa médica', 'ausencia', 'unico', NULL, 'ausencia', '#3F51B5')
) AS d(codigo, nome, categoria, sentido, tipo_par, afeta_calculo, cor)
ON CONFLICT (tenant_id, codigo) DO NOTHING;

WITH tenants_existentes AS (
    SELECT DISTINCT tenant_id FROM funcionarios
    UNION
    SELECT DISTINCT tenant_id FROM horarios_trabalho
)
INSERT INTO metodos_marcacao (tenant_id, codigo, nome, requer_dispositivo, requer_localizacao, requer_selfie)
SELECT
    t.tenant_id,
    d.codigo,
    d.nome,
    d.requer_dispositivo,
    d.requer_localizacao,
    d.requer_selfie
FROM tenants_existentes t
CROSS JOIN (VALUES
    ('biometria', 'Terminal biométrico', TRUE, FALSE, FALSE),
    ('impressao_digital', 'Impressão digital', TRUE, FALSE, FALSE),
    ('reconhecimento_facial', 'Reconhecimento facial', TRUE, FALSE, TRUE),
    ('rfid', 'Cartão RFID', TRUE, FALSE, FALSE),
    ('nfc', 'NFC', TRUE, FALSE, FALSE),
    ('qr', 'Código QR', FALSE, TRUE, FALSE),
    ('app', 'Aplicação móvel', FALSE, TRUE, TRUE),
    ('web', 'Aplicação web', FALSE, FALSE, FALSE),
    ('gps', 'GPS', FALSE, TRUE, FALSE),
    ('geofence', 'Geofencing', FALSE, TRUE, FALSE),
    ('selfie', 'Selfie', FALSE, TRUE, TRUE),
    ('manual', 'Registo manual', FALSE, FALSE, FALSE),
    ('importacao', 'Importação de ficheiro', FALSE, FALSE, FALSE),
    ('api', 'Integração API', FALSE, FALSE, FALSE)
) AS d(codigo, nome, requer_dispositivo, requer_localizacao, requer_selfie)
ON CONFLICT (tenant_id, codigo) DO NOTHING;
