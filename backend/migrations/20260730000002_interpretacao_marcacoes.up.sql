-- Interpretação de marcações: separar o registo bruto da leitura do dia.
--
-- Até aqui o significado de uma marcação era decidido no momento em que ela
-- era gravada: registarEventoAssiduidade/MarcarPonto perguntavam quantos
-- eventos entrada/saída já existiam nesse dia e atribuíam o tipo por paridade
-- (par → entrada, ímpar → saída). Isso obriga cada marcação a ser
-- "definitiva", quando na prática o funcionário carrega duas vezes no leitor,
-- confirma a cara e depois passa o cartão, ou marca à porta e outra vez à
-- entrada do piso. A sequência real
--
--     07:58  08:00  12:03  12:05  13:01  13:04  17:29  17:31
--
-- era lida como entrada(07:58) saída(08:00) entrada(12:03) saída(12:05) ... —
-- 4 turnos de 2 minutos, ~8 minutos trabalhados num dia de 8 horas. O erro não
-- estava nas marcações: estava em decidir o papel de cada uma sem ver as
-- outras.
--
-- Passa a haver duas camadas:
--   1. rh.eventos_assiduidade — o log bruto, imutável, com TODAS as marcações;
--   2. rh.marcacoes_interpretadas — projecção derivada, reconstruída a cada
--      RecalcularDia, que diz que papel cada evento teve no cálculo do dia.
--
-- A segunda é descartável por construção: apagá-la não perde informação
-- nenhuma, basta recalcular. É isso que permite mudar as regras de
-- interpretação (ou a tolerância de agrupamento) e reprocessar o histórico sem
-- tocar nos eventos originais.

BEGIN;

CREATE TABLE IF NOT EXISTS rh.marcacoes_interpretadas (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       bigint      NOT NULL,
    funcionario_id  bigint      NOT NULL REFERENCES rh.funcionarios(id) ON DELETE CASCADE,
    data_referencia date        NOT NULL,
    evento_id       bigint      NOT NULL REFERENCES rh.eventos_assiduidade(id) ON DELETE CASCADE,
    -- papel é a leitura do evento no dia; 'adicional' é a marcação repetida
    -- que confirma a mesma transição e por isso não entra no cálculo.
    papel           varchar(30) NOT NULL,
    utilizado       boolean     NOT NULL DEFAULT false,
    -- grupo junta as marcações que representam a mesma transição (07:58 e
    -- 08:00 são o grupo 0). Serve para a auditoria mostrar porque é que uma
    -- marcação não foi utilizada: há outra, do mesmo grupo, que foi.
    grupo           smallint    NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT NOW(),

    CONSTRAINT marcacoes_interpretadas_papel_check CHECK (
        papel IN ('entrada', 'saida_intervalo', 'regresso_intervalo', 'saida_final', 'adicional')
    ),
    -- Um evento tem no máximo uma leitura: recalcular substitui, não acumula.
    CONSTRAINT uq_marcacoes_interpretadas_evento UNIQUE (evento_id)
);

CREATE INDEX IF NOT EXISTS idx_marcacoes_interpretadas_dia
    ON rh.marcacoes_interpretadas (tenant_id, funcionario_id, data_referencia);

COMMENT ON TABLE rh.marcacoes_interpretadas IS
    'Projecção derivada de rh.eventos_assiduidade: que papel cada marcação teve no cálculo do dia. '
    'Reconstruída por assiduidade.RecalcularDia — nunca editar à mão.';

-- Horas de referência do dia, já interpretadas: a entrada é a primeira
-- marcação do primeiro grupo, a saída a última marcação do último. Ficam
-- gravadas porque são o que a folha de ponto mostra, e recalculá-las a partir
-- dos eventos em cada listagem obrigava a repetir o motor de interpretação em
-- todos os relatórios.
ALTER TABLE rh.resultados_diarios
    ADD COLUMN IF NOT EXISTS primeira_entrada timestamptz,
    ADD COLUMN IF NOT EXISTS ultima_saida     timestamptz;

-- Tolerância de agrupamento. Duas marcações separadas por menos do que isto
-- descrevem a mesma transição. 5 minutos por omissão: é folgado que chegue
-- para a confirmação repetida (segundos) e para o segundo leitor à entrada
-- (1-2 min), e curto que chegue para não engolir uma saída real — ninguém sai
-- para almoço e regressa em menos de 5 minutos.
--
-- É um tipo de regra como os outros (rh.tipos_regra), portanto configurável
-- por funcionário/cargo/departamento/empresa em rh.regras_assiduidade; sem
-- regra explícita vale o default abaixo, resolvido por ResolverRegra.
INSERT INTO rh.tipos_regra (codigo, nome, descricao, parametros, tipo_valor)
VALUES (
    'agrupamento_marcacoes',
    'Agrupamento de marcações repetidas',
    'Intervalo máximo entre duas marcações para que sejam consideradas a mesma transição (entrada, saída para intervalo, regresso ou saída final).',
    '{"minutos": {"tipo": "inteiro", "default": 5, "min": 0}}'::jsonb,
    'jsonb'
)
ON CONFLICT (codigo) DO NOTHING;

COMMIT;
