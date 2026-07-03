-- Migration 061: Fluxos de aprovação multi-nível
--
-- Infraestrutura genérica: qualquer módulo pode criar pedidos de aprovação.
-- Integração actual: compras.purchase_requests (feature 'compras.aprovacoes').

-- ── Definição de fluxo por tenant + feature ────────────────────────────────────
CREATE TABLE saas.approval_flows (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id  BIGINT       NOT NULL REFERENCES saas.tenants(id) ON DELETE CASCADE,
  feature    VARCHAR(120) NOT NULL,
  -- ex: 'compras.requisicoes' — qual feature/contexto dispara este fluxo
  nome       VARCHAR(150) NOT NULL,
  condicao   JSONB        NOT NULL DEFAULT '{}',
  -- ex: {"valor_acima": 50000} — condição para activar o fluxo
  -- vazio = aplica sempre
  niveis     JSONB        NOT NULL DEFAULT '[]',
  -- ex: [{"nivel":1,"cargo_id":5,"prazo_horas":24},{"nivel":2,"cargo_id":3,"prazo_horas":48}]
  ativo      BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, feature, nome)
);

CREATE INDEX idx_approval_flows_tenant_feature ON saas.approval_flows(tenant_id, feature) WHERE ativo = TRUE;

-- ── Pedidos de aprovação em curso ─────────────────────────────────────────────
CREATE TABLE saas.approval_requests (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id   BIGINT      NOT NULL REFERENCES saas.tenants(id) ON DELETE CASCADE,
  flow_id     BIGINT      NOT NULL REFERENCES saas.approval_flows(id),
  entidade    VARCHAR(60) NOT NULL,
  -- ex: 'compras.purchase_requests' — nome da tabela/recurso
  entidade_id BIGINT      NOT NULL,
  nivel_atual INT         NOT NULL DEFAULT 1,
  estado      VARCHAR(20) NOT NULL DEFAULT 'pendente',
  -- 'pendente' | 'aprovado' | 'rejeitado' | 'cancelado'
  criado_por  BIGINT      NOT NULL REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (estado IN ('pendente', 'aprovado', 'rejeitado', 'cancelado'))
);

CREATE INDEX idx_approval_requests_tenant_estado  ON saas.approval_requests(tenant_id, estado);
CREATE INDEX idx_approval_requests_entidade        ON saas.approval_requests(entidade, entidade_id);
CREATE INDEX idx_approval_requests_flow            ON saas.approval_requests(flow_id);

-- ── Histórico de decisões por nível ───────────────────────────────────────────
CREATE TABLE saas.approval_decisions (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  request_id   BIGINT      NOT NULL REFERENCES saas.approval_requests(id) ON DELETE CASCADE,
  nivel        INT         NOT NULL,
  decisao      VARCHAR(20) NOT NULL,
  -- 'aprovado' | 'rejeitado'
  aprovado_por BIGINT      NOT NULL REFERENCES auth.users(id),
  comentario   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (decisao IN ('aprovado', 'rejeitado'))
);

CREATE INDEX idx_approval_decisions_request ON saas.approval_decisions(request_id);
