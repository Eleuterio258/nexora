-- Chaves de idempotência das marcações feitas offline na app e sincronizadas
-- por POST /api/self-service/assiduidade/ponto/batch. O SyncAttendanceWorker
-- reenvia o lote sempre que não recebe resposta; sem esta tabela, um reenvio
-- depois de um sucesso parcial gravava a marcação outra vez (o tipo
-- entrada/saída é inferido pela paridade do dia e muda entre tentativas, por
-- isso a deduplicação exacta de RegistarEvento não a apanha).
CREATE TABLE IF NOT EXISTS rh.marcacoes_offline_sincronizadas (
    tenant_id        BIGINT       NOT NULL,
    user_id          BIGINT       NOT NULL,
    idempotency_key  VARCHAR(128) NOT NULL,
    evento_id        BIGINT       REFERENCES rh.eventos_assiduidade(id) ON DELETE SET NULL,
    ocorrido_em      TIMESTAMPTZ  NOT NULL,
    sincronizado_em  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    PRIMARY KEY (tenant_id, user_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_marcacoes_offline_sincronizadas_evento
    ON rh.marcacoes_offline_sincronizadas (evento_id);

COMMENT ON TABLE rh.marcacoes_offline_sincronizadas IS
    'Marcacoes offline da app ja sincronizadas; impede duplicados quando o lote e reenviado.';
