-- Hierarquia Inteligente de Nos Organizacionais — Modulo Recursos Humanos
--
-- Padrao: Closure Table
--   Cada linha regista um par (ancestral, descendente, profundidade).
--   Um no e sempre seu proprio ancestral (depth = 0).
--   Permite queries de subarvore e caminho em O(1) sem recursao.
--
-- Dependencia: database-rh.sql deve ser executado primeiro.

-- ============================================================
-- CLOSURE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS org_closures (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id     BIGINT NOT NULL,
    ancestor_id   BIGINT NOT NULL,
    descendant_id BIGINT NOT NULL,
    depth         INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT uq_org_closures UNIQUE (ancestor_id, descendant_id),
    CONSTRAINT fk_org_closures_ancestor   FOREIGN KEY (ancestor_id)   REFERENCES org_units(id) ON DELETE CASCADE,
    CONSTRAINT fk_org_closures_descendant FOREIGN KEY (descendant_id) REFERENCES org_units(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_org_closures_ancestor   ON org_closures (tenant_id, ancestor_id);
CREATE INDEX IF NOT EXISTS idx_org_closures_descendant ON org_closures (tenant_id, descendant_id);

-- ============================================================
-- TRIGGER: INSERCAO DE NO ORGANIZACIONAL
-- ============================================================

CREATE OR REPLACE FUNCTION fn_org_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- Auto-referencia (depth = 0)
    INSERT INTO org_closures (tenant_id, ancestor_id, descendant_id, depth)
    VALUES (NEW.tenant_id, NEW.id, NEW.id, 0);

    IF NEW.parent_id IS NOT NULL THEN
        -- Herda todos os ancestrais do pai, incrementando a profundidade
        INSERT INTO org_closures (tenant_id, ancestor_id, descendant_id, depth)
        SELECT c.tenant_id, c.ancestor_id, NEW.id, c.depth + 1
        FROM org_closures c
        WHERE c.descendant_id = NEW.parent_id;

        -- Define nivel com base no pai
        UPDATE org_units
        SET nivel = (SELECT nivel FROM org_units WHERE id = NEW.parent_id) + 1
        WHERE id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_org_insert ON org_units;
CREATE TRIGGER trg_org_insert
    AFTER INSERT ON org_units
    FOR EACH ROW EXECUTE FUNCTION fn_org_after_insert();

-- ============================================================
-- TRIGGER: MOVIMENTACAO DE NO (muda parent_id)
-- ============================================================

CREATE OR REPLACE FUNCTION fn_org_after_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_novo_nivel INTEGER;
BEGIN
    IF OLD.parent_id IS NOT DISTINCT FROM NEW.parent_id THEN
        RETURN NEW;
    END IF;

    -- 1. Remover ligacoes dos ancestrais externos para toda a subarvore
    DELETE FROM org_closures
    WHERE descendant_id IN (
        SELECT descendant_id FROM org_closures WHERE ancestor_id = NEW.id
    )
    AND ancestor_id NOT IN (
        SELECT descendant_id FROM org_closures WHERE ancestor_id = NEW.id
    );

    -- 2. Reinserir ligacoes a partir do novo pai
    IF NEW.parent_id IS NOT NULL THEN
        INSERT INTO org_closures (tenant_id, ancestor_id, descendant_id, depth)
        SELECT p.tenant_id, p.ancestor_id, s.descendant_id, p.depth + s.depth + 1
        FROM org_closures p
        CROSS JOIN org_closures s
        WHERE p.descendant_id = NEW.parent_id
          AND s.ancestor_id   = NEW.id;

        SELECT nivel INTO v_novo_nivel
        FROM org_units WHERE id = NEW.parent_id;
    ELSE
        v_novo_nivel := 0;
    END IF;

    -- 3. Actualizar nivel de toda a subarvore
    UPDATE org_units u
    SET nivel = v_novo_nivel + c.depth + 1
    FROM org_closures c
    WHERE c.ancestor_id   = NEW.id
      AND c.descendant_id = u.id;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_org_update ON org_units;
CREATE TRIGGER trg_org_update
    AFTER UPDATE OF parent_id ON org_units
    FOR EACH ROW EXECUTE FUNCTION fn_org_after_update();

-- ============================================================
-- FUNCAO: MOVER NO COM VALIDACAO
-- Impede mover um no para dentro da sua propria subarvore.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_org_mover(
    p_unit_id     BIGINT,
    p_novo_pai_id BIGINT
)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF p_novo_pai_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM org_closures
        WHERE ancestor_id = p_unit_id AND descendant_id = p_novo_pai_id AND depth > 0
    ) THEN
        RAISE EXCEPTION 'Nao e possivel mover o no % para dentro da sua propria subarvore (%)',
            p_unit_id, p_novo_pai_id;
    END IF;

    UPDATE org_units
    SET parent_id = p_novo_pai_id
    WHERE id = p_unit_id;
END;
$$;

-- ============================================================
-- FUNCAO: OBTER SUBARVORE DE UM NO
-- Devolve todos os IDs descendentes (incluindo o proprio).
-- ============================================================

CREATE OR REPLACE FUNCTION fn_org_subarvore(p_unit_id BIGINT)
RETURNS TABLE (unit_id BIGINT, depth INTEGER) LANGUAGE sql STABLE AS $$
    SELECT descendant_id, depth
    FROM org_closures
    WHERE ancestor_id = p_unit_id
    ORDER BY depth, descendant_id;
$$;

-- ============================================================
-- FUNCAO: OBTER CAMINHO ATÉ A RAIZ
-- Devolve todos os ancestrais ordenados da raiz para o no.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_org_caminho(p_unit_id BIGINT)
RETURNS TABLE (unit_id BIGINT, nome VARCHAR, nivel INTEGER) LANGUAGE sql STABLE AS $$
    SELECT u.id, u.nome, u.nivel
    FROM org_closures c
    JOIN org_units u ON u.id = c.ancestor_id
    WHERE c.descendant_id = p_unit_id
    ORDER BY c.depth DESC;
$$;

-- ============================================================
-- VIEW: ORG CHART COMPLETO
-- ============================================================

CREATE OR REPLACE VIEW vw_rh_org_chart AS
WITH RECURSIVE tree AS (
    SELECT
        u.id,
        u.tenant_id,
        u.parent_id,
        u.codigo,
        u.nome,
        u.nivel,
        u.responsavel_id,
        u.ativo,
        CAST(u.nome AS TEXT)         AS caminho_nomes,
        CAST(u.id::TEXT AS TEXT)     AS caminho_ids
    FROM org_units u
    WHERE u.parent_id IS NULL

    UNION ALL

    SELECT
        u.id,
        u.tenant_id,
        u.parent_id,
        u.codigo,
        u.nome,
        u.nivel,
        u.responsavel_id,
        u.ativo,
        CONCAT(t.caminho_nomes, ' > ', u.nome),
        CONCAT(t.caminho_ids, '/', u.id::TEXT)
    FROM org_units u
    JOIN tree t ON t.id = u.parent_id
)
SELECT
    t.id,
    t.tenant_id,
    t.parent_id,
    t.codigo,
    t.nome,
    t.nivel,
    t.ativo,
    t.caminho_nomes,
    t.caminho_ids,
    resp.nome AS responsavel_nome,
    (
        SELECT COUNT(*) FROM employees e
        WHERE e.org_unit_id = t.id AND e.estado = 'ativo'
    ) AS funcionarios_directos,
    (
        SELECT COUNT(*) FROM employees e
        JOIN org_closures c ON c.descendant_id = e.org_unit_id
        WHERE c.ancestor_id = t.id AND e.estado = 'ativo'
    ) AS funcionarios_total
FROM tree t
LEFT JOIN employees resp ON resp.id = t.responsavel_id;

-- ============================================================
-- VIEW: HEADCOUNT HIERARQUICO
-- ============================================================

CREATE OR REPLACE VIEW vw_rh_headcount_hierarquico AS
SELECT
    u.id AS org_unit_id,
    u.tenant_id,
    u.nome,
    u.nivel,
    u.parent_id,
    pu.nome AS unidade_pai,
    COUNT(DISTINCT e.id) FILTER (WHERE e.org_unit_id = u.id AND e.estado = 'ativo')    AS directos_ativos,
    COUNT(DISTINCT e.id) FILTER (WHERE e.org_unit_id = u.id AND e.estado = 'suspenso') AS directos_suspensos,
    COUNT(DISTINCT e.id) FILTER (
        WHERE c.ancestor_id = u.id AND e.estado = 'ativo'
    ) AS total_ativos_subarvore
FROM org_units u
LEFT JOIN org_units pu ON pu.id = u.parent_id
LEFT JOIN org_closures c ON c.ancestor_id = u.id
LEFT JOIN employees e ON e.org_unit_id = c.descendant_id
GROUP BY u.id, u.tenant_id, u.nome, u.nivel, u.parent_id, pu.nome;

-- ============================================================
-- VIEW: CAMINHO ORGANIZACIONAL DE CADA FUNCIONARIO
-- ============================================================

CREATE OR REPLACE VIEW vw_rh_employee_org_path AS
SELECT
    e.id AS employee_id,
    e.tenant_id,
    e.nome AS nome_funcionario,
    e.numero,
    e.estado,
    u.nome AS unidade_org,
    u.nivel AS nivel_org,
    p.nome AS cargo,
    oc.caminho_nomes AS caminho_org
FROM employees e
LEFT JOIN org_units u ON u.id = e.org_unit_id
LEFT JOIN employee_positions p ON p.id = e.employee_position_id
LEFT JOIN vw_rh_org_chart oc ON oc.id = e.org_unit_id;
