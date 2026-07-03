-- 078_tarefas.sql — Módulo Gestão de Tarefas (Kanban)

CREATE SCHEMA IF NOT EXISTS tarefas;

CREATE TABLE IF NOT EXISTS tarefas.quadros (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    titulo      VARCHAR(200) NOT NULL,
    descricao   TEXT,
    cor         VARCHAR(7) NOT NULL DEFAULT '#F59E0B',
    arquivado   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tarefas.listas (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    quadro_id   BIGINT NOT NULL,
    titulo      VARCHAR(200) NOT NULL,
    posicao     INTEGER NOT NULL DEFAULT 0,
    arquivada   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_listas_quadro FOREIGN KEY (quadro_id) REFERENCES tarefas.quadros(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tarefas.cartoes (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id     BIGINT NOT NULL,
    lista_id      BIGINT NOT NULL,
    titulo        VARCHAR(255) NOT NULL,
    descricao     TEXT,
    posicao       INTEGER NOT NULL DEFAULT 0,
    data_inicio   DATE,
    data_fim      DATE,
    prioridade    VARCHAR(20) NOT NULL DEFAULT 'media'
                    CHECK (prioridade IN ('baixa', 'media', 'alta', 'urgente')),
    responsaveis  INTEGER[] NOT NULL DEFAULT '{}',
    concluido     BOOLEAN NOT NULL DEFAULT FALSE,
    arquivado     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cartoes_lista FOREIGN KEY (lista_id) REFERENCES tarefas.listas(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tarefas_quadros_tenant ON tarefas.quadros (tenant_id, arquivado);
CREATE INDEX IF NOT EXISTS idx_tarefas_listas_quadro  ON tarefas.listas  (quadro_id, posicao);
CREATE INDEX IF NOT EXISTS idx_tarefas_cartoes_lista  ON tarefas.cartoes (lista_id, posicao);
