SET search_path TO rh, public;

-- Generaliza "departamentos" para "unidades organizacionais": permite tipos
-- diferentes de estrutura (departamento, equipa, divisao, seccao, direccao,
-- gabinete, outro) e hierarquia de varios niveis via parent_id.

ALTER TABLE departamentos RENAME TO unidades_organizacionais;
ALTER TABLE unidades_organizacionais RENAME CONSTRAINT uq_departamentos_tenant_codigo TO uq_unidades_organizacionais_tenant_codigo;
ALTER TABLE unidades_organizacionais RENAME CONSTRAINT fk_departamentos_responsavel TO fk_unidades_organizacionais_responsavel;
ALTER INDEX idx_departamentos_tenant_id RENAME TO idx_unidades_organizacionais_tenant_id;

ALTER TABLE unidades_organizacionais
    ADD COLUMN tipo VARCHAR(30) NOT NULL DEFAULT 'departamento'
        CHECK (tipo IN ('departamento', 'equipa', 'divisao', 'seccao', 'direccao', 'gabinete', 'outro')),
    ADD COLUMN parent_id BIGINT;

ALTER TABLE unidades_organizacionais
    ADD CONSTRAINT fk_unidades_organizacionais_parent FOREIGN KEY (parent_id) REFERENCES unidades_organizacionais(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_unidades_organizacionais_parent_id ON unidades_organizacionais (parent_id);

-- funcionarios.department_id -> funcionarios.unit_id
ALTER TABLE funcionarios RENAME COLUMN department_id TO unit_id;
ALTER TABLE funcionarios RENAME CONSTRAINT fk_funcionarios_departamento TO fk_funcionarios_unidade;
ALTER INDEX idx_funcionarios_department_id RENAME TO idx_funcionarios_unit_id;
