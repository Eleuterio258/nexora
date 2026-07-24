-- Baseline do esquema nexora_erp
-- Gerado a partir da base de dados de producao em 2026-07-24.
-- Substitui todas as migracoes anteriores (arquivadas em migrations/archive/).

CREATE SCHEMA IF NOT EXISTS assinatura_digital;
CREATE SCHEMA IF NOT EXISTS assinaturas;
CREATE SCHEMA IF NOT EXISTS auditoria;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS autorizacao;
CREATE SCHEMA IF NOT EXISTS centros_custo;
CREATE SCHEMA IF NOT EXISTS clientes;
CREATE SCHEMA IF NOT EXISTS compras;
CREATE SCHEMA IF NOT EXISTS contabilidade;
CREATE SCHEMA IF NOT EXISTS crm;
CREATE SCHEMA IF NOT EXISTS empresas;
CREATE SCHEMA IF NOT EXISTS faturacao;
CREATE SCHEMA IF NOT EXISTS financeiro;
CREATE SCHEMA IF NOT EXISTS gestao_escolar;
CREATE SCHEMA IF NOT EXISTS impostos;
CREATE SCHEMA IF NOT EXISTS logistica;
CREATE SCHEMA IF NOT EXISTS multi_moeda;
CREATE SCHEMA IF NOT EXISTS notifications;
CREATE SCHEMA IF NOT EXISTS pessoas;
CREATE SCHEMA IF NOT EXISTS pos;
CREATE SCHEMA IF NOT EXISTS produtos;
CREATE SCHEMA IF NOT EXISTS recrutamento;
CREATE SCHEMA IF NOT EXISTS rh;
CREATE SCHEMA IF NOT EXISTS saas;
CREATE SCHEMA IF NOT EXISTS seguranca;
CREATE SCHEMA IF NOT EXISTS sistema_configuracao;
CREATE SCHEMA IF NOT EXISTS stock;
CREATE SCHEMA IF NOT EXISTS tarefas;
CREATE SCHEMA IF NOT EXISTS tesouraria;
CREATE SCHEMA IF NOT EXISTS utilizadores;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';
CREATE OR REPLACE FUNCTION auth.criar_cargos_padrao(p_tenant_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id BIGINT;
BEGIN
    -- Director de Turma
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director de Turma',
            'Acompanha pedagogicamente a turma, consulta relatórios e comunica com encarregados.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
    RETURNING id INTO v_id;
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'relatorios'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas'),
        (v_id, 'gestao-escolar', 'gerir_ocorrencias'),
        (v_id, 'gestao-escolar', 'gerir_comunicacao')
    ON CONFLICT DO NOTHING;
    -- Chefe de Turma
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Chefe de Turma',
            'Apoia a comunicação e organização da turma.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
    RETURNING id INTO v_id;
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'gerir_comunicacao')
    ON CONFLICT DO NOTHING;
END;
$$;
CREATE OR REPLACE FUNCTION impostos.fn_aplicar_isencoes_fatura(p_tenant_id bigint, p_invoice_id bigint) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_count INTEGER;
BEGIN
    WITH aplicaveis AS (
        SELECT i.id AS item_id, e.id AS exemption_id, e.tax_id,
               ROW_NUMBER() OVER (
                   PARTITION BY i.id
                   ORDER BY CASE e.entity_type
                       WHEN 'product' THEN 1
                       WHEN 'product_category' THEN 2
                       WHEN 'customer' THEN 3
                       ELSE 4 END, e.id DESC
               ) AS prioridade
          FROM faturacao.invoice_items i
          JOIN faturacao.invoices f ON f.id=i.invoice_id
          LEFT JOIN produtos.products p ON p.id=i.product_id
          JOIN impostos.tax_exemptions e ON e.tenant_id=f.tenant_id AND e.ativo
           AND e.data_inicio<=f.invoice_date
           AND (e.validade IS NULL OR e.validade>=f.invoice_date)
           AND (
               (e.entity_type='customer' AND e.entity_id=f.customer_id) OR
               (e.entity_type='product' AND e.entity_id=i.product_id) OR
               (e.entity_type='product_category' AND e.entity_id=p.product_category_id)
           )
         WHERE f.id=p_invoice_id AND f.tenant_id=p_tenant_id AND f.status='rascunho'
    )
    UPDATE faturacao.invoice_items i
       SET tax_id=a.tax_id,
           tax_exemption_id=a.exemption_id,
           imposto_percent=0,
           imposto_valor=0,
           total=i.subtotal
      FROM aplicaveis a
     WHERE a.item_id=i.id AND a.prioridade=1;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    UPDATE faturacao.invoices f
       SET subtotal=COALESCE(x.subtotal,0),
           imposto_total=COALESCE(x.imposto,0),
           total=COALESCE(x.total,0)
      FROM (
        SELECT invoice_id,SUM(subtotal) subtotal,SUM(imposto_valor) imposto,SUM(total) total
          FROM faturacao.invoice_items WHERE invoice_id=p_invoice_id GROUP BY invoice_id
      ) x
     WHERE f.id=x.invoice_id AND f.tenant_id=p_tenant_id;
    RETURN v_count;
END $$;
CREATE OR REPLACE FUNCTION impostos.trg_tax_return_immutable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.status IN ('submetida','paga') THEN
        RAISE EXCEPTION 'Declaracao submetida e imutavel; crie uma substituicao';
    END IF;
    RETURN NEW;
END $$;
CREATE OR REPLACE FUNCTION impostos.trg_tax_return_lines_immutable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_return_id BIGINT;
    v_status VARCHAR(20);
BEGIN
    IF TG_OP='DELETE' THEN
        v_return_id := OLD.tax_return_id;
    ELSE
        v_return_id := NEW.tax_return_id;
    END IF;
    SELECT status INTO v_status FROM impostos.tax_returns WHERE id=v_return_id;
    IF v_status IN ('submetida','paga') THEN
        RAISE EXCEPTION 'Linhas de declaracao submetida sao imutaveis';
    END IF;
    IF TG_OP='DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END $$;
CREATE OR REPLACE FUNCTION stock.fn_consumir_reserva(p_tenant_id bigint, p_reservation_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item BIGINT;
    v_quantity NUMERIC;
BEGIN
    SELECT stock_item_id,quantity INTO v_item,v_quantity
      FROM stock.stock_reservations
     WHERE id=p_reservation_id AND tenant_id=p_tenant_id AND status='ativa'
     FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reserva activa nao encontrada';
    END IF;
    UPDATE stock.stock_items
       SET quantity=quantity-v_quantity,
           reserved_quantity=GREATEST(reserved_quantity-v_quantity,0),
           updated_at=NOW()
     WHERE id=v_item AND tenant_id=p_tenant_id AND quantity>=v_quantity;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock insuficiente para consumir a reserva';
    END IF;
    UPDATE stock.stock_reservations
       SET status='consumida',updated_at=NOW()
     WHERE id=p_reservation_id;
    INSERT INTO stock.stock_movements(
        tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id
    ) VALUES (
        p_tenant_id,v_item,'saida',v_quantity,'stock_reservation',p_reservation_id
    );
END $$;
CREATE OR REPLACE FUNCTION stock.fn_liberar_reserva(p_tenant_id bigint, p_reservation_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item BIGINT;
    v_quantity NUMERIC;
BEGIN
    SELECT stock_item_id,quantity INTO v_item,v_quantity
      FROM stock.stock_reservations
     WHERE id=p_reservation_id AND tenant_id=p_tenant_id AND status='ativa'
     FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reserva activa nao encontrada';
    END IF;
    UPDATE stock.stock_items
       SET reserved_quantity=GREATEST(reserved_quantity-v_quantity,0),updated_at=NOW()
     WHERE id=v_item AND tenant_id=p_tenant_id;
    UPDATE stock.stock_reservations
       SET status='cancelada',updated_at=NOW()
     WHERE id=p_reservation_id;
    INSERT INTO stock.stock_movements(
        tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id
    ) VALUES (
        p_tenant_id,v_item,'liberacao',v_quantity,'stock_reservation',p_reservation_id
    );
END $$;
CREATE OR REPLACE FUNCTION stock.fn_reservar_stock(p_tenant_id bigint, p_stock_item_id bigint, p_quantity numeric, p_reference_type character varying DEFAULT NULL::character varying, p_reference_id bigint DEFAULT NULL::bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_available NUMERIC;
    v_id BIGINT;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'A quantidade deve ser positiva';
    END IF;
    SELECT available_quantity INTO v_available
      FROM stock.stock_items
     WHERE id=p_stock_item_id AND tenant_id=p_tenant_id
     FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Posicao de stock nao encontrada';
    END IF;
    IF v_available < p_quantity THEN
        RAISE EXCEPTION 'Stock disponivel insuficiente';
    END IF;
    UPDATE stock.stock_items
       SET reserved_quantity=reserved_quantity+p_quantity, updated_at=NOW()
     WHERE id=p_stock_item_id;
    INSERT INTO stock.stock_reservations(
        tenant_id,stock_item_id,quantity,reference_type,reference_id
    ) VALUES (
        p_tenant_id,p_stock_item_id,p_quantity,p_reference_type,p_reference_id
    ) RETURNING id INTO v_id;
    INSERT INTO stock.stock_movements(
        tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id
    ) VALUES (
        p_tenant_id,p_stock_item_id,'reserva',p_quantity,'stock_reservation',v_id
    );
    RETURN v_id;
END $$;
CREATE OR REPLACE FUNCTION tarefas.fn_remove_user_from_cartoes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE tarefas.cartoes
       SET responsaveis = array_remove(responsaveis, OLD.id::integer)
     WHERE OLD.id::integer = ANY(responsaveis);
    RETURN OLD;
END;
$$;
CREATE TABLE IF NOT EXISTS assinatura_digital.documentos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(255) NOT NULL,
    descricao text,
    storage_key character varying(500),
    ficheiro_url character varying(1000),
    hash_sha256 character varying(64),
    status character varying(30) DEFAULT 'rascunho'::character varying NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    data_envio timestamp with time zone,
    data_conclusao timestamp with time zone,
    CONSTRAINT documentos_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('pendente'::character varying)::text, ('assinado'::character varying)::text, ('cancelado'::character varying)::text, ('expirado'::character varying)::text])))
);
CREATE SEQUENCE IF NOT EXISTS assinatura_digital.documentos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE assinatura_digital.documentos_id_seq OWNED BY assinatura_digital.documentos.id;
CREATE TABLE IF NOT EXISTS assinatura_digital.logs (
    id bigint NOT NULL,
    documento_id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    signatario_id bigint,
    acao character varying(50) NOT NULL,
    detalhes jsonb,
    user_id bigint,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now()
);
CREATE SEQUENCE IF NOT EXISTS assinatura_digital.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE assinatura_digital.logs_id_seq OWNED BY assinatura_digital.logs.id;
CREATE TABLE IF NOT EXISTS assinatura_digital.signatarios (
    id bigint NOT NULL,
    documento_id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(255) NOT NULL,
    email character varying(255),
    nuit character varying(30),
    bi character varying(30),
    telefone character varying(30),
    ordem integer DEFAULT 1,
    tipo character varying(30) DEFAULT 'assinatura'::character varying NOT NULL,
    status character varying(30) DEFAULT 'pendente'::character varying NOT NULL,
    campo_pagina integer,
    campo_x numeric(10,2),
    campo_y numeric(10,2),
    campo_largura numeric(10,2),
    campo_altura numeric(10,2),
    assinado_em timestamp with time zone,
    assinatura_hash character varying(64),
    assinatura_ip inet,
    created_at timestamp with time zone DEFAULT now(),
    pessoa_id bigint,
    CONSTRAINT signatarios_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('convidado'::character varying)::text, ('assinado'::character varying)::text, ('recusado'::character varying)::text]))),
    CONSTRAINT signatarios_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('assinatura'::character varying)::text, ('rubrica'::character varying)::text, ('testemunha'::character varying)::text])))
);
CREATE SEQUENCE IF NOT EXISTS assinatura_digital.signatarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE assinatura_digital.signatarios_id_seq OWNED BY assinatura_digital.signatarios.id;
CREATE TABLE IF NOT EXISTS assinatura_digital.versoes_assinadas (
    id bigint NOT NULL,
    documento_id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    storage_key character varying(500) NOT NULL,
    ficheiro_url character varying(1000),
    hash_sha256 character varying(64),
    signatario_id bigint,
    created_at timestamp with time zone DEFAULT now()
);
CREATE SEQUENCE IF NOT EXISTS assinatura_digital.versoes_assinadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE assinatura_digital.versoes_assinadas_id_seq OWNED BY assinatura_digital.versoes_assinadas.id;
CREATE TABLE IF NOT EXISTS assinaturas.subscription_invoices (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    subscription_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    billing_period_start date NOT NULL,
    billing_period_end date NOT NULL,
    due_date date NOT NULL,
    valor_total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    status character varying(20) DEFAULT 'emitida'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT subscription_invoices_status_check CHECK (((status)::text = ANY (ARRAY[('emitida'::character varying)::text, ('paga'::character varying)::text, ('cancelada'::character varying)::text, ('vencida'::character varying)::text])))
);
ALTER TABLE assinaturas.subscription_invoices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME assinaturas.subscription_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS assinaturas.subscription_plans (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    billing_period character varying(20) DEFAULT 'mensal'::character varying NOT NULL,
    preco numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    limites jsonb,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT subscription_plans_billing_period_check CHECK (((billing_period)::text = ANY (ARRAY[('mensal'::character varying)::text, ('trimestral'::character varying)::text, ('anual'::character varying)::text])))
);
ALTER TABLE assinaturas.subscription_plans ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME assinaturas.subscription_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS assinaturas.subscription_usage (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    subscription_id bigint NOT NULL,
    recurso character varying(100) NOT NULL,
    quantidade numeric(18,2) DEFAULT 0 NOT NULL,
    periodo date DEFAULT CURRENT_DATE NOT NULL,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE assinaturas.subscription_usage ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME assinaturas.subscription_usage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS assinaturas.subscriptions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    company_id bigint,
    plan_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    starts_at date NOT NULL,
    ends_at date,
    next_billing_date date,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    unit_price numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    auto_renew boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT subscriptions_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('activa'::character varying)::text, ('suspensa'::character varying)::text, ('cancelada'::character varying)::text, ('expirada'::character varying)::text])))
);
ALTER TABLE assinaturas.subscriptions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME assinaturas.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auditoria.audit_events (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    actor_user_id bigint,
    actor_email character varying(150),
    actor_nome character varying(150),
    service_name character varying(100) NOT NULL,
    module_name character varying(100) NOT NULL,
    action character varying(50) NOT NULL,
    entity_type character varying(100) NOT NULL,
    entity_id character varying(100),
    status character varying(20) DEFAULT 'sucesso'::character varying NOT NULL,
    ip_address character varying(64),
    user_agent text,
    metadata jsonb,
    payload_before jsonb,
    payload_after jsonb,
    previous_hash character varying(64),
    event_hash character varying(64) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT audit_events_status_check CHECK (((status)::text = ANY (ARRAY[('sucesso'::character varying)::text, ('falha'::character varying)::text, ('alerta'::character varying)::text])))
);
COMMENT ON TABLE auditoria.audit_events IS 'Registo de eventos com valor legal/compliance, com cadeia de hash (event_hash + previous_hash). Usar para eventos irreversiveis: fecho de periodo contabilistico, emissao de facturas, aprovacoes RH, alteracoes de permissoes, renovacao de assinaturas.';
ALTER TABLE auditoria.audit_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.audit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auditoria.audit_logs (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    user_id bigint,
    modulo character varying(100) NOT NULL,
    entidade character varying(100) NOT NULL,
    entidade_id bigint,
    acao character varying(100) NOT NULL,
    detalhes jsonb,
    ip_address character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
COMMENT ON TABLE auditoria.audit_logs IS 'Log operacional de rotina: quem fez o que e quando. Preenchido automaticamente pelo middleware AuditModule (Go). Nao tem garantia de imutabilidade - para eventos legais usar audit_events.';
ALTER TABLE auditoria.audit_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE OR REPLACE VIEW auditoria.v_audit_unified AS
 SELECT 'log'::text AS sistema,
    audit_logs.id,
    audit_logs.tenant_id,
    audit_logs.user_id,
    NULL::bigint AS actor_user_id,
    audit_logs.modulo,
    audit_logs.acao AS action,
    audit_logs.entidade AS entity_type,
    (audit_logs.entidade_id)::text AS entity_id,
    NULL::text AS event_hash,
    audit_logs.created_at
   FROM auditoria.audit_logs
UNION ALL
 SELECT 'event'::text AS sistema,
    audit_events.id,
    audit_events.tenant_id,
    NULL::bigint AS user_id,
    audit_events.actor_user_id,
    audit_events.module_name AS modulo,
    audit_events.action,
    audit_events.entity_type,
    (audit_events.entity_id)::text AS entity_id,
    audit_events.event_hash,
    audit_events.created_at
   FROM auditoria.audit_events;
COMMENT ON VIEW auditoria.v_audit_unified IS 'Vista unificada dos dois sistemas de auditoria. sistema=log para audit_logs, event para audit_events.';
CREATE TABLE IF NOT EXISTS auth.api_keys (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    user_id bigint,
    nome character varying(120) NOT NULL,
    key_prefix character varying(20) NOT NULL,
    key_hash text NOT NULL,
    ultimo_uso_em timestamp with time zone,
    expira_em timestamp with time zone,
    ativa boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE auth.api_keys ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.api_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auth.audit_logs (
    id bigint NOT NULL,
    user_id bigint,
    tenant_id bigint,
    acao text NOT NULL,
    modulo text,
    recurso text,
    recurso_id text,
    ip_address inet,
    user_agent text,
    detalhes jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE SEQUENCE IF NOT EXISTS auth.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE auth.audit_logs_id_seq OWNED BY auth.audit_logs.id;
CREATE TABLE IF NOT EXISTS auth.cargos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE auth.cargos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.cargos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auth.email_verifications (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_hash text NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    usado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE auth.email_verifications ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.email_verifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auth.login_history (
    id bigint NOT NULL,
    user_id bigint,
    tenant_id bigint NOT NULL,
    email_tentado character varying(150),
    sucesso boolean NOT NULL,
    ip_address character varying(64),
    user_agent text,
    motivo_falha character varying(255),
    criado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE auth.login_history ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.login_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auth.memberships (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    cargo_id bigint,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    escopo character varying(20) DEFAULT 'erp'::character varying NOT NULL,
    papel character varying(20),
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    CONSTRAINT memberships_escopo_check CHECK (((escopo)::text = ANY (ARRAY[('erp'::character varying)::text, ('escola'::character varying)::text, ('portal_aluno'::character varying)::text, ('portal_encarregado'::character varying)::text, ('portal_professor'::character varying)::text]))),
    CONSTRAINT memberships_papel_check CHECK (((papel IS NULL) OR ((papel)::text = ANY ((ARRAY['superadmin'::character varying, 'funcionario'::character varying, 'aluno'::character varying, 'encarregado'::character varying, 'candidato'::character varying])::text[]))))
);
ALTER TABLE auth.memberships ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auth.password_resets (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_hash text NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    usado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE auth.password_resets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.password_resets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auth.permissoes_cargo (
    id bigint NOT NULL,
    cargo_id bigint NOT NULL,
    modulo character varying(60) NOT NULL,
    acao character varying(60) NOT NULL
);
ALTER TABLE auth.permissoes_cargo ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.permissoes_cargo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auth.permissoes_diretas (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    modulo character varying(60) NOT NULL,
    acao character varying(60) NOT NULL,
    tenant_id bigint
);
ALTER TABLE auth.permissoes_diretas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.permissoes_diretas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auth.permissoes_tipo (
    id bigint NOT NULL,
    tipo text NOT NULL,
    modulo text NOT NULL,
    acao text NOT NULL
);
CREATE SEQUENCE IF NOT EXISTS auth.permissoes_tipo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE auth.permissoes_tipo_id_seq OWNED BY auth.permissoes_tipo.id;
CREATE TABLE IF NOT EXISTS auth.sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_hash text NOT NULL,
    ip_address character varying(64),
    user_agent text,
    iniciado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    encerrado_em timestamp with time zone,
    ativa boolean DEFAULT true NOT NULL
);
ALTER TABLE auth.sessions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS auth.superadmin_ip_allowlist (
    id bigint NOT NULL,
    ip_cidr inet NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint
);
CREATE SEQUENCE IF NOT EXISTS auth.superadmin_ip_allowlist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE auth.superadmin_ip_allowlist_id_seq OWNED BY auth.superadmin_ip_allowlist.id;
CREATE TABLE IF NOT EXISTS auth.superadmin_security_settings (
    chave text NOT NULL,
    valor text NOT NULL,
    atualizado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    atualizado_por bigint
);
CREATE TABLE IF NOT EXISTS auth.users (
    id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    password_hash text NOT NULL,
    telefone character varying(30),
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    email_verificado boolean DEFAULT false NOT NULL,
    ultimo_login_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo character varying(20) DEFAULT 'funcionario'::character varying NOT NULL,
    permissoes_atualizadas_em timestamp with time zone DEFAULT now() NOT NULL,
    pessoa_id bigint,
    CONSTRAINT users_estado_check CHECK (((estado)::text = ANY (ARRAY[('ativo'::character varying)::text, ('bloqueado'::character varying)::text, ('pendente'::character varying)::text, ('inativo'::character varying)::text]))),
    CONSTRAINT users_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('superadmin'::character varying)::text, ('funcionario'::character varying)::text, ('aluno'::character varying)::text, ('encarregado'::character varying)::text, ('candidato'::character varying)::text])))
);
ALTER TABLE auth.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS autorizacao.permissions (
    id bigint NOT NULL,
    codigo character varying(100) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    recurso character varying(100),
    acao character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE autorizacao.permissions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS autorizacao.role_permissions (
    id bigint NOT NULL,
    role_id bigint NOT NULL,
    permission_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE autorizacao.role_permissions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.role_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS autorizacao.roles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE autorizacao.roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS autorizacao.user_roles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE autorizacao.user_roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS centros_custo.cost_center_allocations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    cost_center_id bigint NOT NULL,
    source_service character varying(100) NOT NULL,
    source_type character varying(100) NOT NULL,
    source_id bigint NOT NULL,
    source_line_id bigint,
    descricao character varying(255),
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    allocation_percent numeric(8,4) DEFAULT 100 NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cost_center_allocations_allocation_percent_check CHECK (((allocation_percent > (0)::numeric) AND (allocation_percent <= (100)::numeric))),
    CONSTRAINT cost_center_allocations_valor_check CHECK ((valor >= (0)::numeric))
);
ALTER TABLE centros_custo.cost_center_allocations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME centros_custo.cost_center_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS centros_custo.cost_center_budgets (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    cost_center_id bigint NOT NULL,
    ano integer NOT NULL,
    mes integer,
    valor_orcamentado numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cost_center_budgets_mes_check CHECK (((mes >= 1) AND (mes <= 12)))
);
ALTER TABLE centros_custo.cost_center_budgets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME centros_custo.cost_center_budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS centros_custo.cost_centers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    parent_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    tipo character varying(20) DEFAULT 'centro'::character varying NOT NULL,
    gestor_user_id bigint,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cost_centers_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('centro'::character varying)::text, ('departamento'::character varying)::text, ('projecto'::character varying)::text])))
);
ALTER TABLE centros_custo.cost_centers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME centros_custo.cost_centers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_addresses (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    tipo character varying(30) DEFAULT 'principal'::character varying NOT NULL,
    endereco character varying(255) NOT NULL,
    cidade character varying(100),
    provincia character varying(100),
    pais character varying(100) DEFAULT 'Mocambique'::character varying NOT NULL,
    codigo_postal character varying(30),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT customer_addresses_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('principal'::character varying)::text, ('entrega'::character varying)::text, ('cobranca'::character varying)::text, ('fiscal'::character varying)::text])))
);
ALTER TABLE clientes.customer_addresses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_balances (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    saldo_atual numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_vencido numeric(18,2) DEFAULT 0 NOT NULL,
    credito_disponivel numeric(18,2) DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE clientes.customer_balances ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_balances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_contacts (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    cargo character varying(100),
    telefone character varying(30),
    email character varying(120),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pessoa_id bigint
);
ALTER TABLE clientes.customer_contacts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_credit_limits (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    limite_credito numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    inicio_em date,
    fim_em date,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    motivo text,
    updated_by bigint,
    CONSTRAINT customer_credit_limits_limite_credito_check CHECK ((limite_credito >= (0)::numeric))
);
ALTER TABLE clientes.customer_credit_limits ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_credit_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_discounts (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    motivo character varying(150),
    ativo boolean DEFAULT true NOT NULL,
    inicio_em date,
    fim_em date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT customer_discounts_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('percentual'::character varying)::text, ('valor_fixo'::character varying)::text]))),
    CONSTRAINT customer_discounts_valor_check CHECK ((valor >= (0)::numeric))
);
ALTER TABLE clientes.customer_discounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_documents (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    numero character varying(100),
    ficheiro_url text,
    emitido_em date,
    expira_em date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT customer_documents_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('contrato'::character varying)::text, ('nuit'::character varying)::text, ('bi'::character varying)::text, ('comprovativo'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE clientes.customer_documents ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_groups (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE clientes.customer_groups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_history (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    evento character varying(100) NOT NULL,
    descricao text,
    referencia_tipo character varying(50),
    referencia_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint
);
ALTER TABLE clientes.customer_history ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_notes (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    nota text NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE clientes.customer_notes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_payments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    documento_id bigint,
    metodo character varying(30) NOT NULL,
    referencia character varying(100),
    valor numeric(18,2) NOT NULL,
    pago_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    observacao text,
    created_by bigint,
    CONSTRAINT customer_payments_metodo_check CHECK (((metodo)::text = ANY (ARRAY[('dinheiro'::character varying)::text, ('transferencia'::character varying)::text, ('mpesa'::character varying)::text, ('emola'::character varying)::text, ('cartao'::character varying)::text]))),
    CONSTRAINT customer_payments_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE clientes.customer_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_tag_links (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    customer_tag_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE clientes.customer_tag_links ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_tag_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customer_tags (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    cor character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE clientes.customer_tags ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS clientes.customers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    customer_group_id bigint,
    codigo character varying(50),
    nome character varying(150) NOT NULL,
    nuit character varying(30),
    telefone character varying(30),
    email character varying(120),
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    observacao text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    bloqueio_motivo text,
    bloqueado_em timestamp with time zone,
    pessoa_id bigint,
    CONSTRAINT customers_estado_check CHECK (((estado)::text = ANY (ARRAY[('ativo'::character varying)::text, ('inativo'::character varying)::text, ('bloqueado'::character varying)::text])))
);
ALTER TABLE clientes.customers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.goods_receipt_items (
    id bigint NOT NULL,
    goods_receipt_id bigint NOT NULL,
    purchase_order_item_id bigint NOT NULL,
    product_id bigint,
    quantity_received numeric(18,3) NOT NULL,
    returned_quantity numeric(18,3) DEFAULT 0 NOT NULL,
    unit_cost numeric(18,2) NOT NULL,
    lote character varying(80),
    validade date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT goods_receipt_items_quantity_received_check CHECK ((quantity_received > (0)::numeric)),
    CONSTRAINT goods_receipt_items_returned_quantity_check CHECK ((returned_quantity >= (0)::numeric)),
    CONSTRAINT goods_receipt_items_unit_cost_check CHECK ((unit_cost >= (0)::numeric))
);
ALTER TABLE compras.goods_receipt_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.goods_receipt_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.goods_receipts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    purchase_order_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    receipt_date date DEFAULT CURRENT_DATE NOT NULL,
    warehouse_id bigint,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    observacoes text,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    supplier_document character varying(100),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT goods_receipts_status_check CHECK (((status)::text = ANY (ARRAY[('confirmado'::character varying)::text, ('cancelado'::character varying)::text])))
);
ALTER TABLE compras.goods_receipts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.goods_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_invoice_items (
    id bigint NOT NULL,
    purchase_invoice_id bigint NOT NULL,
    purchase_order_item_id bigint,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    unidade character varying(20) DEFAULT 'UN'::character varying NOT NULL,
    quantity numeric(18,4) NOT NULL,
    unit_price numeric(18,2) NOT NULL,
    desconto numeric(18,2) DEFAULT 0 NOT NULL,
    tax_rate numeric(8,4) DEFAULT 0 NOT NULL,
    tax_amount numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_invoice_items_desconto_check CHECK ((desconto >= (0)::numeric)),
    CONSTRAINT purchase_invoice_items_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT purchase_invoice_items_tax_amount_check CHECK ((tax_amount >= (0)::numeric)),
    CONSTRAINT purchase_invoice_items_tax_rate_check CHECK ((tax_rate >= (0)::numeric)),
    CONSTRAINT purchase_invoice_items_total_check CHECK ((total >= (0)::numeric)),
    CONSTRAINT purchase_invoice_items_unit_price_check CHECK ((unit_price >= (0)::numeric))
);
ALTER TABLE compras.purchase_invoice_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_invoice_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_invoices (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    purchase_order_id bigint,
    goods_receipt_id bigint,
    numero character varying(60) NOT NULL,
    supplier_invoice_number character varying(100),
    invoice_date date DEFAULT CURRENT_DATE NOT NULL,
    due_date date NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    observacoes text,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_invoices_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('emitida'::character varying)::text, ('parcial'::character varying)::text, ('paga'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE compras.purchase_invoices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_order_items (
    id bigint NOT NULL,
    purchase_order_id bigint NOT NULL,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    unidade character varying(30) DEFAULT 'UN'::character varying NOT NULL,
    quantity numeric(18,3) NOT NULL,
    received_quantity numeric(18,3) DEFAULT 0 NOT NULL,
    unit_price numeric(18,2) NOT NULL,
    desconto numeric(18,2) DEFAULT 0 NOT NULL,
    tax_rate numeric(8,4) DEFAULT 0 NOT NULL,
    tax_amount numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT purchase_order_items_desconto_check CHECK ((desconto >= (0)::numeric)),
    CONSTRAINT purchase_order_items_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT purchase_order_items_received_quantity_check CHECK ((received_quantity >= (0)::numeric)),
    CONSTRAINT purchase_order_items_tax_amount_check CHECK ((tax_amount >= (0)::numeric)),
    CONSTRAINT purchase_order_items_tax_rate_check CHECK ((tax_rate >= (0)::numeric)),
    CONSTRAINT purchase_order_items_total_check CHECK ((total >= (0)::numeric)),
    CONSTRAINT purchase_order_items_unit_price_check CHECK ((unit_price >= (0)::numeric))
);
ALTER TABLE compras.purchase_order_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_orders (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    order_date date DEFAULT CURRENT_DATE NOT NULL,
    expected_date date,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    criado_por bigint,
    aprovado_por bigint,
    aprovado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    purchase_request_id bigint,
    payment_terms character varying(120),
    CONSTRAINT purchase_orders_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('aprovada'::character varying)::text, ('parcial'::character varying)::text, ('recebida'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE compras.purchase_orders ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_payment_items (
    id bigint NOT NULL,
    purchase_payment_id bigint NOT NULL,
    purchase_invoice_id bigint NOT NULL,
    valor numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_payment_items_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE compras.purchase_payment_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_payment_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_payments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    numero character varying(60) NOT NULL,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    metodo character varying(30) NOT NULL,
    referencia character varying(100),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    valor numeric(18,2) NOT NULL,
    valor_alocado numeric(18,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    observacoes text,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_payments_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('confirmado'::character varying)::text, ('cancelado'::character varying)::text]))),
    CONSTRAINT purchase_payments_valor_alocado_check CHECK ((valor_alocado >= (0)::numeric)),
    CONSTRAINT purchase_payments_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE compras.purchase_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_request_items (
    id bigint NOT NULL,
    purchase_request_id bigint NOT NULL,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    unidade character varying(20) DEFAULT 'UN'::character varying NOT NULL,
    quantity numeric(18,4) NOT NULL,
    estimated_unit_price numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_request_items_estimated_unit_price_check CHECK ((estimated_unit_price >= (0)::numeric)),
    CONSTRAINT purchase_request_items_quantity_check CHECK ((quantity > (0)::numeric))
);
ALTER TABLE compras.purchase_request_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_request_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_requests (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    request_date date DEFAULT CURRENT_DATE NOT NULL,
    required_date date,
    department character varying(120),
    requested_by bigint,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    prioridade character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    justificacao text,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_requests_prioridade_check CHECK (((prioridade)::text = ANY (ARRAY[('baixa'::character varying)::text, ('normal'::character varying)::text, ('alta'::character varying)::text, ('urgente'::character varying)::text]))),
    CONSTRAINT purchase_requests_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('submetida'::character varying)::text, ('aprovada'::character varying)::text, ('rejeitada'::character varying)::text, ('convertida'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE compras.purchase_requests ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_return_items (
    id bigint NOT NULL,
    purchase_return_id bigint NOT NULL,
    goods_receipt_item_id bigint NOT NULL,
    product_id bigint,
    quantity numeric(18,3) NOT NULL,
    unit_cost numeric(18,2) NOT NULL,
    total numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT purchase_return_items_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT purchase_return_items_total_check CHECK ((total >= (0)::numeric)),
    CONSTRAINT purchase_return_items_unit_cost_check CHECK ((unit_cost >= (0)::numeric))
);
ALTER TABLE compras.purchase_return_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_return_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.purchase_returns (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    goods_receipt_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    return_date date DEFAULT CURRENT_DATE NOT NULL,
    motivo character varying(255) NOT NULL,
    status character varying(20) DEFAULT 'confirmada'::character varying NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    warehouse_id bigint,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_returns_status_check CHECK (((status)::text = ANY (ARRAY[('confirmada'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE compras.purchase_returns ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_returns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.supplier_addresses (
    id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    tipo character varying(30) DEFAULT 'principal'::character varying NOT NULL,
    endereco character varying(255) NOT NULL,
    cidade character varying(100),
    provincia character varying(100),
    pais character varying(100) DEFAULT 'Mocambique'::character varying NOT NULL,
    codigo_postal character varying(30),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT supplier_addresses_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('principal'::character varying)::text, ('entrega'::character varying)::text, ('cobranca'::character varying)::text, ('fiscal'::character varying)::text])))
);
ALTER TABLE compras.supplier_addresses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.supplier_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.supplier_contacts (
    id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    cargo character varying(100),
    telefone character varying(30),
    email character varying(120),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE compras.supplier_contacts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.supplier_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.supplier_groups (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE compras.supplier_groups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.supplier_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS compras.suppliers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_group_id bigint,
    codigo character varying(50),
    nome character varying(150) NOT NULL,
    nuit character varying(30),
    telefone character varying(30),
    email character varying(120),
    moeda_padrao character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    prazo_pagamento_dias integer DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    observacao text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT suppliers_estado_check CHECK (((estado)::text = ANY (ARRAY[('ativo'::character varying)::text, ('inativo'::character varying)::text, ('bloqueado'::character varying)::text])))
);
ALTER TABLE compras.suppliers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.suppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.account_types (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(20) NOT NULL,
    nome character varying(100) NOT NULL,
    classe character varying(20) NOT NULL,
    natureza character varying(20) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT account_types_classe_check CHECK (((classe)::text = ANY (ARRAY[('ativo'::character varying)::text, ('passivo'::character varying)::text, ('capital'::character varying)::text, ('rendimento'::character varying)::text, ('gasto'::character varying)::text]))),
    CONSTRAINT account_types_natureza_check CHECK (((natureza)::text = ANY (ARRAY[('devedora'::character varying)::text, ('credora'::character varying)::text])))
);
ALTER TABLE contabilidade.account_types ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.account_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.accounting_budgets (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    chart_account_id bigint NOT NULL,
    fiscal_year_id bigint NOT NULL,
    mes integer,
    valor_orcamentado numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_accounting_budgets_mes CHECK (((mes IS NULL) OR ((mes >= 1) AND (mes <= 12)))),
    CONSTRAINT chk_accounting_budgets_valor CHECK ((valor_orcamentado >= (0)::numeric))
);
ALTER TABLE contabilidade.accounting_budgets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.accounting_budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.accounting_journals (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(20) NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(20) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounting_journals_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('geral'::character varying)::text, ('vendas'::character varying)::text, ('compras'::character varying)::text, ('tesouraria'::character varying)::text, ('folha'::character varying)::text, ('ajuste'::character varying)::text])))
);
ALTER TABLE contabilidade.accounting_journals ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.accounting_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.fiscal_periods (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    ano integer NOT NULL,
    mes integer NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    fechado_em timestamp with time zone,
    fechado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fiscal_year_id bigint,
    CONSTRAINT accounting_periods_mes_check CHECK (((mes >= 1) AND (mes <= 12))),
    CONSTRAINT accounting_periods_status_check CHECK (((status)::text = ANY (ARRAY[('aberto'::character varying)::text, ('fechado'::character varying)::text])))
);
ALTER TABLE contabilidade.fiscal_periods ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.accounting_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.accounting_reports (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    parametros jsonb DEFAULT '{}'::jsonb NOT NULL,
    conteudo jsonb DEFAULT '{}'::jsonb NOT NULL,
    gerado_por bigint,
    gerado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_accounting_reports_tipo CHECK (((tipo)::text = ANY (ARRAY[('trial_balance'::character varying)::text, ('balance_sheet'::character varying)::text, ('income_statement'::character varying)::text, ('general_ledger'::character varying)::text, ('depreciation_summary'::character varying)::text, ('budget_execution'::character varying)::text])))
);
ALTER TABLE contabilidade.accounting_reports ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.accounting_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.chart_of_accounts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    parent_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    aceita_lancamento boolean DEFAULT true NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    account_type_id bigint
);
ALTER TABLE contabilidade.chart_of_accounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.chart_of_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.depreciation_entries (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    fixed_asset_id bigint NOT NULL,
    fiscal_period_id bigint NOT NULL,
    numero_parcela integer NOT NULL,
    valor_amortizacao numeric(18,2) NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    journal_entry_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_depreciation_entries_status CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('processado'::character varying)::text, ('cancelado'::character varying)::text]))),
    CONSTRAINT chk_depreciation_entries_valor CHECK ((valor_amortizacao >= (0)::numeric))
);
ALTER TABLE contabilidade.depreciation_entries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.depreciation_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.fiscal_years (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    ano integer NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    fechado_em timestamp with time zone,
    fechado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fiscal_years_status_check CHECK (((status)::text = ANY (ARRAY[('aberto'::character varying)::text, ('fechado'::character varying)::text])))
);
ALTER TABLE contabilidade.fiscal_years ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.fiscal_years_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.fixed_assets (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    chart_account_id bigint NOT NULL,
    depreciation_account_id bigint NOT NULL,
    accumulated_depreciation_account_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    data_aquisicao date NOT NULL,
    valor_aquisicao numeric(18,2) NOT NULL,
    valor_residual numeric(18,2) DEFAULT 0 NOT NULL,
    vida_util_meses integer NOT NULL,
    metodo character varying(20) DEFAULT 'linha_recta'::character varying NOT NULL,
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    data_alienacao date,
    valor_alienacao numeric(18,2),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_fixed_assets_estado CHECK (((estado)::text = ANY (ARRAY[('ativo'::character varying)::text, ('alienado'::character varying)::text]))),
    CONSTRAINT chk_fixed_assets_metodo CHECK (((metodo)::text = 'linha_recta'::text)),
    CONSTRAINT chk_fixed_assets_valor_aquisicao CHECK ((valor_aquisicao > (0)::numeric)),
    CONSTRAINT chk_fixed_assets_valor_residual CHECK ((valor_residual >= (0)::numeric)),
    CONSTRAINT chk_fixed_assets_vida_util CHECK ((vida_util_meses > 0))
);
ALTER TABLE contabilidade.fixed_assets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.fixed_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.journal_entries (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    fiscal_period_id bigint NOT NULL,
    accounting_journal_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    entry_date date NOT NULL,
    descricao character varying(255) NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    total_debito numeric(18,2) DEFAULT 0 NOT NULL,
    total_credito numeric(18,2) DEFAULT 0 NOT NULL,
    criado_por bigint,
    publicado_por bigint,
    publicado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT journal_entries_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('publicado'::character varying)::text, ('anulado'::character varying)::text])))
);
ALTER TABLE contabilidade.journal_entries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.journal_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.journal_entry_lines (
    id bigint NOT NULL,
    journal_entry_id bigint NOT NULL,
    account_id bigint NOT NULL,
    descricao character varying(255),
    debit numeric(18,2) DEFAULT 0 NOT NULL,
    credit numeric(18,2) DEFAULT 0 NOT NULL,
    reference_type character varying(50),
    reference_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT journal_entry_lines_credit_check CHECK ((credit >= (0)::numeric)),
    CONSTRAINT journal_entry_lines_debit_check CHECK ((debit >= (0)::numeric))
);
ALTER TABLE contabilidade.journal_entry_lines ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.journal_entry_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.journal_entry_sequences (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    accounting_journal_id bigint NOT NULL,
    ano integer NOT NULL,
    proxima_sequencia integer DEFAULT 1 NOT NULL
);
ALTER TABLE contabilidade.journal_entry_sequences ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.journal_entry_sequences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.period_closing_checks (
    id bigint NOT NULL,
    period_closing_id bigint NOT NULL,
    verificacao character varying(100) NOT NULL,
    passou boolean NOT NULL,
    detalhe text,
    verificado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE contabilidade.period_closing_checks ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.period_closing_checks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS contabilidade.period_closings (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    fiscal_period_id bigint NOT NULL,
    status character varying(20) DEFAULT 'em_curso'::character varying NOT NULL,
    iniciado_por bigint,
    iniciado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    encerrado_por bigint,
    encerrado_em timestamp with time zone,
    justificacao_reabertura text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_period_closings_status CHECK (((status)::text = ANY (ARRAY[('em_curso'::character varying)::text, ('verificado'::character varying)::text, ('encerrado'::character varying)::text, ('reaberto'::character varying)::text])))
);
ALTER TABLE contabilidade.period_closings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.period_closings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS crm.atividades (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    lead_id bigint,
    oportunidade_id bigint,
    tipo character varying(20) DEFAULT 'nota'::character varying NOT NULL,
    titulo character varying(200) NOT NULL,
    descricao text,
    data_atividade timestamp with time zone,
    concluida boolean DEFAULT false NOT NULL,
    responsavel character varying(100),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT atividades_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('nota'::character varying)::text, ('tarefa'::character varying)::text, ('chamada'::character varying)::text, ('reuniao'::character varying)::text, ('email'::character varying)::text]))),
    CONSTRAINT chk_atividades_link CHECK (((lead_id IS NOT NULL) OR (oportunidade_id IS NOT NULL)))
);
ALTER TABLE crm.atividades ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.atividades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS crm.leads (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    empresa character varying(150),
    email character varying(255),
    telefone character varying(30),
    origem character varying(50) DEFAULT 'outro'::character varying NOT NULL,
    estado character varying(20) DEFAULT 'novo'::character varying NOT NULL,
    responsavel character varying(100),
    notas text,
    cliente_id bigint,
    convertido_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    responsavel_id bigint,
    CONSTRAINT leads_estado_check CHECK (((estado)::text = ANY (ARRAY[('novo'::character varying)::text, ('contactado'::character varying)::text, ('qualificado'::character varying)::text, ('desqualificado'::character varying)::text, ('convertido'::character varying)::text]))),
    CONSTRAINT leads_origem_check CHECK (((origem)::text = ANY (ARRAY[('site'::character varying)::text, ('referencia'::character varying)::text, ('redes_sociais'::character varying)::text, ('evento'::character varying)::text, ('chamada_fria'::character varying)::text, ('email'::character varying)::text, ('anuncio'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE crm.leads ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS crm.oportunidades (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(200) NOT NULL,
    lead_id bigint,
    cliente_id bigint,
    estagio character varying(20) DEFAULT 'novo'::character varying NOT NULL,
    valor_estimado numeric(18,2) DEFAULT 0,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    probabilidade smallint DEFAULT 0 NOT NULL,
    data_fecho_prevista date,
    data_fecho_real date,
    motivo_perda text,
    responsavel character varying(100),
    descricao text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    responsavel_id bigint,
    CONSTRAINT oportunidades_estagio_check CHECK (((estagio)::text = ANY (ARRAY[('novo'::character varying)::text, ('qualificado'::character varying)::text, ('proposta'::character varying)::text, ('negociacao'::character varying)::text, ('ganho'::character varying)::text, ('perdido'::character varying)::text]))),
    CONSTRAINT oportunidades_probabilidade_check CHECK (((probabilidade >= 0) AND (probabilidade <= 100))),
    CONSTRAINT oportunidades_valor_estimado_check CHECK ((valor_estimado >= (0)::numeric))
);
ALTER TABLE crm.oportunidades ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.oportunidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.companies (
    id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    nome_comercial character varying(150),
    tipo character varying(30) DEFAULT 'empresa'::character varying NOT NULL,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    moeda_base character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    timezone character varying(60) DEFAULT 'Africa/Maputo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id bigint,
    CONSTRAINT companies_status_check CHECK (((status)::text = ANY (ARRAY[('ativa'::character varying)::text, ('suspensa'::character varying)::text, ('inativa'::character varying)::text]))),
    CONSTRAINT companies_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('empresa'::character varying)::text, ('organizacao'::character varying)::text, ('holding'::character varying)::text, ('filial_independente'::character varying)::text])))
);
ALTER TABLE empresas.companies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.company_addresses (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    branch_id bigint,
    tipo character varying(30) DEFAULT 'principal'::character varying NOT NULL,
    endereco character varying(255) NOT NULL,
    cidade character varying(100),
    provincia character varying(100),
    pais character varying(100) DEFAULT 'Mocambique'::character varying NOT NULL,
    codigo_postal character varying(30),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_addresses_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('principal'::character varying)::text, ('fiscal'::character varying)::text, ('entrega'::character varying)::text, ('filial'::character varying)::text, ('cobranca'::character varying)::text])))
);
ALTER TABLE empresas.company_addresses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.company_banks (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(60) NOT NULL,
    nib character varying(60),
    iban character varying(60),
    swift character varying(30),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE empresas.company_banks ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_banks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.company_branches (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_branches_status_check CHECK (((status)::text = ANY (ARRAY[('ativa'::character varying)::text, ('inativa'::character varying)::text])))
);
ALTER TABLE empresas.company_branches ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_branches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.company_contacts (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    branch_id bigint,
    tipo character varying(30) DEFAULT 'geral'::character varying NOT NULL,
    nome character varying(150),
    telefone character varying(30),
    email character varying(150),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pessoa_id bigint,
    CONSTRAINT company_contacts_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('geral'::character varying)::text, ('financeiro'::character varying)::text, ('comercial'::character varying)::text, ('suporte'::character varying)::text, ('rh'::character varying)::text])))
);
ALTER TABLE empresas.company_contacts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.company_documents (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    numero character varying(100),
    ficheiro_url text,
    emitido_em date,
    expira_em date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_documents_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('alvara'::character varying)::text, ('certidao'::character varying)::text, ('contrato_social'::character varying)::text, ('licenca'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE empresas.company_documents ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.company_licenses (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    plano character varying(50) NOT NULL,
    licenca_chave character varying(120),
    limite_usuarios integer,
    limite_filiais integer,
    inicia_em date NOT NULL,
    expira_em date,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_licenses_status_check CHECK (((status)::text = ANY (ARRAY[('ativa'::character varying)::text, ('expirada'::character varying)::text, ('suspensa'::character varying)::text])))
);
ALTER TABLE empresas.company_licenses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_licenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.company_settings (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE empresas.company_settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.company_tax_info (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    nuit character varying(30) NOT NULL,
    regime_iva character varying(50),
    taxa_iva_padrao numeric(5,2) DEFAULT 17.00 NOT NULL,
    inicio_atividade date,
    reparticao_fiscal character varying(150),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_tax_info_taxa_iva_padrao_check CHECK ((taxa_iva_padrao >= (0)::numeric))
);
ALTER TABLE empresas.company_tax_info ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_tax_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS empresas.company_users (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint NOT NULL,
    branch_id bigint,
    perfil_empresa character varying(50),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE empresas.company_users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.credit_note_items (
    id bigint NOT NULL,
    credit_note_id bigint NOT NULL,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    quantidade numeric(18,4) DEFAULT 1 NOT NULL,
    preco_unitario numeric(18,4) DEFAULT 0 NOT NULL,
    tax_id bigint,
    imposto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL
);
ALTER TABLE faturacao.credit_note_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.credit_note_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.credit_notes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    customer_id bigint NOT NULL,
    invoice_id bigint,
    numero character varying(50) NOT NULL,
    credit_date date DEFAULT CURRENT_DATE NOT NULL,
    motivo character varying(255) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    emitida_em timestamp with time zone,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT credit_notes_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('emitida'::character varying)::text, ('aplicada'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE faturacao.credit_notes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.credit_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.invoice_discounts (
    id bigint NOT NULL,
    invoice_id bigint NOT NULL,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    descricao text,
    CONSTRAINT invoice_discounts_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('percentual'::character varying)::text, ('valor_fixo'::character varying)::text]))),
    CONSTRAINT invoice_discounts_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE faturacao.invoice_discounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.invoice_items (
    id bigint NOT NULL,
    invoice_id bigint NOT NULL,
    product_id bigint NOT NULL,
    descricao character varying(255),
    quantidade numeric(18,4) NOT NULL,
    preco_unitario numeric(18,4) NOT NULL,
    desconto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    desconto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    tax_id bigint,
    imposto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    tax_exemption_id bigint,
    CONSTRAINT invoice_items_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT invoice_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);
ALTER TABLE faturacao.invoice_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.invoice_receipts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    invoice_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    payment_method_id bigint,
    valor numeric(18,2) NOT NULL,
    referencia character varying(100),
    observacoes text,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT invoice_receipts_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('confirmado'::character varying)::text, ('cancelado'::character varying)::text]))),
    CONSTRAINT invoice_receipts_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE faturacao.invoice_receipts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.invoice_series (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tipo character varying(10) NOT NULL,
    prefixo character varying(20) NOT NULL,
    ano integer NOT NULL,
    sequencia integer DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT invoice_series_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('ORC'::character varying)::text, ('ENC'::character varying)::text, ('GR'::character varying)::text, ('FT'::character varying)::text, ('NC'::character varying)::text, ('RB'::character varying)::text, ('VD'::character varying)::text])))
);
ALTER TABLE faturacao.invoice_series ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_series_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.invoice_taxes (
    id bigint NOT NULL,
    invoice_id bigint NOT NULL,
    tax_id bigint,
    nome_imposto character varying(100) NOT NULL,
    taxa numeric(8,4) NOT NULL,
    base_imponivel numeric(18,2) NOT NULL,
    valor_imposto numeric(18,2) NOT NULL
);
ALTER TABLE faturacao.invoice_taxes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.invoices (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    customer_id bigint NOT NULL,
    sales_order_id bigint,
    numero character varying(50) NOT NULL,
    invoice_date date DEFAULT CURRENT_DATE NOT NULL,
    due_date date,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    taxa_cambio numeric(14,6) DEFAULT 1 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_pendente numeric(18,2) GENERATED ALWAYS AS ((total - valor_pago)) STORED,
    payment_terms character varying(100),
    observacoes text,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    emitida_em timestamp with time zone,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    CONSTRAINT invoices_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('emitida'::character varying)::text, ('parcialmente_paga'::character varying)::text, ('paga'::character varying)::text, ('cancelada'::character varying)::text, ('vencida'::character varying)::text]))),
    CONSTRAINT invoices_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('normal'::character varying)::text, ('proforma'::character varying)::text])))
);
ALTER TABLE faturacao.invoices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.sales_deliveries (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    sales_order_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    delivery_date date DEFAULT CURRENT_DATE NOT NULL,
    morada_entrega text,
    observacoes text,
    status character varying(20) DEFAULT 'emitida'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT sales_deliveries_status_check CHECK (((status)::text = ANY (ARRAY[('emitida'::character varying)::text, ('em_transito'::character varying)::text, ('entregue'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE faturacao.sales_deliveries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_deliveries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.sales_delivery_items (
    id bigint NOT NULL,
    sales_delivery_id bigint NOT NULL,
    sales_order_item_id bigint,
    product_id bigint NOT NULL,
    quantidade_entregue numeric(18,4) NOT NULL,
    CONSTRAINT sales_delivery_items_quantidade_entregue_check CHECK ((quantidade_entregue > (0)::numeric))
);
ALTER TABLE faturacao.sales_delivery_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_delivery_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.sales_order_items (
    id bigint NOT NULL,
    sales_order_id bigint NOT NULL,
    product_id bigint NOT NULL,
    descricao character varying(255),
    quantidade numeric(18,4) NOT NULL,
    quantidade_entregue numeric(18,4) DEFAULT 0 NOT NULL,
    preco_unitario numeric(18,4) NOT NULL,
    desconto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    desconto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    tax_id bigint,
    imposto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    CONSTRAINT sales_order_items_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT sales_order_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);
ALTER TABLE faturacao.sales_order_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.sales_orders (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    customer_id bigint NOT NULL,
    sales_quote_id bigint,
    numero character varying(50) NOT NULL,
    order_date date DEFAULT CURRENT_DATE NOT NULL,
    data_entrega_prevista date,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT sales_orders_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('confirmada'::character varying)::text, ('parcial'::character varying)::text, ('entregue'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE faturacao.sales_orders ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.sales_quote_items (
    id bigint NOT NULL,
    sales_quote_id bigint NOT NULL,
    product_id bigint NOT NULL,
    descricao character varying(255),
    quantidade numeric(18,4) NOT NULL,
    preco_unitario numeric(18,4) NOT NULL,
    desconto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    desconto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    tax_id bigint,
    imposto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    CONSTRAINT sales_quote_items_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT sales_quote_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);
ALTER TABLE faturacao.sales_quote_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_quote_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.sales_quotes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    customer_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    quote_date date DEFAULT CURRENT_DATE NOT NULL,
    validade date,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT sales_quotes_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('enviado'::character varying)::text, ('aprovado'::character varying)::text, ('rejeitado'::character varying)::text, ('convertido'::character varying)::text, ('expirado'::character varying)::text])))
);
ALTER TABLE faturacao.sales_quotes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_quotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.sales_return_items (
    id bigint NOT NULL,
    sales_return_id bigint NOT NULL,
    product_id bigint NOT NULL,
    quantidade numeric(18,4) NOT NULL,
    motivo text,
    estado_produto character varying(20) DEFAULT 'bom'::character varying,
    CONSTRAINT sales_return_items_estado_produto_check CHECK (((estado_produto)::text = ANY (ARRAY[('bom'::character varying)::text, ('danificado'::character varying)::text, ('defeito'::character varying)::text]))),
    CONSTRAINT sales_return_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);
ALTER TABLE faturacao.sales_return_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_return_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS faturacao.sales_returns (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    invoice_id bigint,
    credit_note_id bigint,
    numero character varying(50) NOT NULL,
    return_date date DEFAULT CURRENT_DATE NOT NULL,
    observacoes text,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT sales_returns_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('recebida'::character varying)::text, ('processada'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE faturacao.sales_returns ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_returns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS financeiro.accounts_payable (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    supplier_id bigint,
    financial_category_id bigint,
    origem_tipo character varying(50),
    origem_id bigint,
    descricao character varying(255),
    valor_total numeric(18,2) NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pendente numeric(18,2) GENERATED ALWAYS AS ((valor_total - valor_pago)) STORED,
    data_emissao date NOT NULL,
    data_vencimento date NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounts_payable_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('parcial'::character varying)::text, ('liquidada'::character varying)::text, ('cancelada'::character varying)::text, ('vencida'::character varying)::text]))),
    CONSTRAINT accounts_payable_valor_total_check CHECK ((valor_total > (0)::numeric))
);
ALTER TABLE financeiro.accounts_payable ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.accounts_payable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS financeiro.accounts_payable_payments (
    id bigint NOT NULL,
    accounts_payable_id bigint NOT NULL,
    payment_id bigint NOT NULL,
    valor_imputado numeric(18,2) NOT NULL,
    data_imputacao timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounts_payable_payments_valor_imputado_check CHECK ((valor_imputado > (0)::numeric))
);
ALTER TABLE financeiro.accounts_payable_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.accounts_payable_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS financeiro.accounts_receivable (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    customer_id bigint NOT NULL,
    financial_category_id bigint,
    origem_tipo character varying(50),
    origem_id bigint,
    descricao character varying(255),
    valor_total numeric(18,2) NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pendente numeric(18,2) GENERATED ALWAYS AS ((valor_total - valor_pago)) STORED,
    data_emissao date NOT NULL,
    data_vencimento date NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounts_receivable_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('parcial'::character varying)::text, ('liquidada'::character varying)::text, ('cancelada'::character varying)::text, ('vencida'::character varying)::text]))),
    CONSTRAINT accounts_receivable_valor_total_check CHECK ((valor_total > (0)::numeric))
);
ALTER TABLE financeiro.accounts_receivable ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.accounts_receivable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS financeiro.accounts_receivable_payments (
    id bigint NOT NULL,
    accounts_receivable_id bigint NOT NULL,
    payment_id bigint NOT NULL,
    valor_imputado numeric(18,2) NOT NULL,
    data_imputacao timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounts_receivable_payments_valor_imputado_check CHECK ((valor_imputado > (0)::numeric))
);
ALTER TABLE financeiro.accounts_receivable_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.accounts_receivable_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS financeiro.cash_flow_entries (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    financial_category_id bigint,
    tipo character varying(20) NOT NULL,
    origem character varying(30) NOT NULL,
    data date NOT NULL,
    valor numeric(18,2) NOT NULL,
    descricao character varying(255),
    referencia_tipo character varying(50),
    referencia_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cash_flow_entries_origem_check CHECK (((origem)::text = ANY (ARRAY[('realizado'::character varying)::text, ('previsto'::character varying)::text]))),
    CONSTRAINT cash_flow_entries_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('entrada'::character varying)::text, ('saida'::character varying)::text]))),
    CONSTRAINT cash_flow_entries_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE financeiro.cash_flow_entries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.cash_flow_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS financeiro.financial_budgets (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    financial_category_id bigint NOT NULL,
    ano integer NOT NULL,
    mes integer,
    valor_orcamentado numeric(18,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT financial_budgets_mes_check CHECK (((mes >= 1) AND (mes <= 12)))
);
ALTER TABLE financeiro.financial_budgets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.financial_budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS financeiro.financial_categories (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    parent_id bigint,
    codigo character varying(30),
    nome character varying(120) NOT NULL,
    tipo character varying(20) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    CONSTRAINT financial_categories_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('receita'::character varying)::text, ('despesa'::character varying)::text, ('transferencia'::character varying)::text])))
);
ALTER TABLE financeiro.financial_categories ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.financial_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS financeiro.payment_methods (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(30) DEFAULT 'outro'::character varying NOT NULL,
    requer_referencia boolean DEFAULT false NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    CONSTRAINT payment_methods_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('numerario'::character varying)::text, ('transferencia'::character varying)::text, ('tpa'::character varying)::text, ('cheque'::character varying)::text, ('credito'::character varying)::text, ('debito'::character varying)::text, ('mpesa'::character varying)::text, ('emola'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE financeiro.payment_methods ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.payment_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS financeiro.payments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    payment_method_id bigint,
    financial_category_id bigint,
    tipo character varying(20) NOT NULL,
    data_pagamento date NOT NULL,
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    descricao text,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT payments_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('confirmado'::character varying)::text, ('cancelado'::character varying)::text]))),
    CONSTRAINT payments_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('recebimento'::character varying)::text, ('pagamento'::character varying)::text]))),
    CONSTRAINT payments_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE financeiro.payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.guardian_portal_sessions (
    id bigint NOT NULL,
    guardian_email text NOT NULL,
    tenant_id bigint NOT NULL,
    token_hash text NOT NULL,
    ip_address text,
    user_agent text,
    ativa boolean DEFAULT true NOT NULL,
    criada_em timestamp with time zone DEFAULT now() NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE IF NOT EXISTS gestao_escolar.guardian_portal_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gestao_escolar.guardian_portal_sessions_id_seq OWNED BY gestao_escolar.guardian_portal_sessions.id;
CREATE TABLE IF NOT EXISTS gestao_escolar.portal_sessions (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    token_hash text NOT NULL,
    ip_address text,
    user_agent text,
    ativa boolean DEFAULT true NOT NULL,
    criada_em timestamp with time zone DEFAULT now() NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE IF NOT EXISTS gestao_escolar.portal_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gestao_escolar.portal_sessions_id_seq OWNED BY gestao_escolar.portal_sessions.id;
CREATE TABLE IF NOT EXISTS gestao_escolar.school_academic_config (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    level_id bigint,
    nota_minima_aprovacao numeric(6,2) DEFAULT 10 NOT NULL,
    escala_maxima numeric(6,2) DEFAULT 20 NOT NULL,
    sistema_avaliacao character varying(30) DEFAULT '0-20'::character varying NOT NULL,
    arredondamento character varying(20) DEFAULT 'decimal_2'::character varying NOT NULL,
    presenca_minima_percentual numeric(5,2) DEFAULT 75,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_academic_config ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_academic_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_academic_transcripts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    student_id bigint NOT NULL,
    school_year_id bigint NOT NULL,
    enrollment_id bigint,
    level_id bigint,
    series_id bigint,
    course_id bigint,
    class_id bigint,
    classificacao_final numeric(6,2),
    resultado character varying(30) DEFAULT 'pendente'::character varying NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_academic_transcripts_resultado_check CHECK (((resultado)::text = ANY (ARRAY[('pendente'::character varying)::text, ('aprovado'::character varying)::text, ('reprovado'::character varying)::text, ('transferido'::character varying)::text, ('desistiu'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_academic_transcripts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_academic_transcripts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_attendance (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    class_id bigint NOT NULL,
    student_id bigint NOT NULL,
    attendance_date date NOT NULL,
    estado character varying(20) NOT NULL,
    observacoes text,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    subject_id bigint,
    enrollment_id bigint,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_attendance_estado_check CHECK (((estado)::text = ANY (ARRAY[('presente'::character varying)::text, ('ausente'::character varying)::text, ('justificado'::character varying)::text, ('atrasado'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_attendance ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_books (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    isbn character varying(30),
    codigo character varying(40) NOT NULL,
    titulo character varying(200) NOT NULL,
    autor character varying(150),
    editora character varying(120),
    ano_publicacao integer,
    categoria character varying(80),
    exemplares_total integer DEFAULT 1 NOT NULL,
    exemplares_disponiveis integer DEFAULT 1 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_books_exemplares_disponiveis_check CHECK ((exemplares_disponiveis >= 0)),
    CONSTRAINT school_books_exemplares_total_check CHECK ((exemplares_total >= 0))
);
ALTER TABLE gestao_escolar.school_books ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_books_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_calendar_event_types (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    cor character varying(7) DEFAULT '#3B82F6'::character varying,
    impacto_frequencia character varying(20) DEFAULT 'nenhum'::character varying NOT NULL,
    dia_todo boolean DEFAULT true NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_calendar_event_types_impacto_frequencia_check CHECK (((impacto_frequencia)::text = ANY (ARRAY[('nenhum'::character varying)::text, ('nao_contabiliza'::character varying)::text, ('marcar_ausencia'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_calendar_event_types ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_calendar_event_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_calendar_events (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint NOT NULL,
    event_type_id bigint,
    titulo character varying(180) NOT NULL,
    descricao text,
    data_inicio date NOT NULL,
    data_fim date,
    hora_inicio time without time zone,
    hora_fim time without time zone,
    dia_todo boolean DEFAULT true NOT NULL,
    publico_alvo character varying(30) DEFAULT 'todos'::character varying,
    publico_alvo_id bigint,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_calendar_events_check CHECK (((data_fim IS NULL) OR (data_fim >= data_inicio))),
    CONSTRAINT school_calendar_events_check1 CHECK (((hora_fim IS NULL) OR (hora_inicio IS NULL) OR (hora_fim > hora_inicio))),
    CONSTRAINT school_calendar_events_publico_alvo_check CHECK (((publico_alvo)::text = ANY (ARRAY[('todos'::character varying)::text, ('alunos'::character varying)::text, ('professores'::character varying)::text, ('turma'::character varying)::text, ('curso'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_calendar_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_calendar_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_cargo_permissoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    class_id bigint NOT NULL,
    cargo character varying(100) NOT NULL,
    permissao character varying(100) NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_cargo_permissoes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_cargo_permissoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_classes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    nivel character varying(50),
    turma character varying(20),
    capacidade integer,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    school_year_id bigint,
    director_teacher_id bigint,
    sala character varying(50),
    horario jsonb DEFAULT '[]'::jsonb NOT NULL,
    level_id bigint,
    series_id bigint,
    course_id bigint,
    turno character varying(30) DEFAULT 'manha'::character varying
);
ALTER TABLE gestao_escolar.school_classes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_course_subject_terms (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    course_subject_id bigint NOT NULL,
    term_id bigint NOT NULL,
    tem_exame boolean DEFAULT false NOT NULL,
    peso_exame numeric(5,2) DEFAULT NULL::numeric,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_course_subject_terms ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_course_subject_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_course_subjects (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    course_id bigint,
    level_id bigint,
    series_id bigint,
    subject_id bigint NOT NULL,
    obrigatoria boolean DEFAULT true NOT NULL,
    carga_horaria_semanal integer,
    componente character varying(30) DEFAULT 'teorica'::character varying,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_course_subjects_componente_check CHECK (((componente)::text = ANY (ARRAY[('teorica'::character varying)::text, ('pratica'::character varying)::text, ('laboratorial'::character varying)::text, ('anual'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_course_subjects ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_course_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_courses (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    level_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    duracao_anos integer DEFAULT 1 NOT NULL,
    modalidade character varying(30) DEFAULT 'presencial'::character varying NOT NULL,
    grau character varying(60),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_courses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_cycles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    level_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_cycles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_cycles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_enrollments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    student_id bigint NOT NULL,
    class_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    data_matricula date DEFAULT CURRENT_DATE NOT NULL,
    status character varying(20) DEFAULT 'activa'::character varying NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    school_year_id bigint,
    observacoes text,
    transferred_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_enrollments_status_check CHECK (((status)::text = ANY (ARRAY[('activa'::character varying)::text, ('cancelada'::character varying)::text, ('concluida'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_enrollments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_evaluation_types (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    padrao boolean DEFAULT false NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_evaluation_types ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_evaluation_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_fee_generations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    fee_plan_id bigint NOT NULL,
    school_year_id bigint NOT NULL,
    periodo_referencia character varying(30) NOT NULL,
    data_geracao timestamp with time zone DEFAULT now() NOT NULL,
    total_cobrancas integer DEFAULT 0 NOT NULL,
    valor_total numeric(18,2) DEFAULT 0 NOT NULL,
    gerado_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_fee_generations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_fee_generations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_fee_plans (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(30) DEFAULT 'propina'::character varying NOT NULL,
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    periodicidade character varying(20) DEFAULT 'mensal'::character varying NOT NULL,
    dia_vencimento integer,
    classe_nivel character varying(80),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by bigint,
    CONSTRAINT school_fee_plans_valor_check CHECK ((valor >= (0)::numeric))
);
ALTER TABLE gestao_escolar.school_fee_plans ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_fee_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_fees (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    enrollment_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    descricao character varying(150) NOT NULL,
    mes_referencia character varying(20),
    data_vencimento date NOT NULL,
    valor_total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fee_plan_id bigint,
    student_id bigint,
    desconto numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_motivo text,
    entidade character varying(20),
    referencia character varying(40),
    emitida_em timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    cancelamento_motivo text,
    cancelado_em timestamp with time zone,
    cancelado_por bigint,
    desconto_pendente numeric(12,2),
    desconto_pendente_motivo text,
    CONSTRAINT school_fees_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('emitida'::character varying)::text, ('parcial'::character varying)::text, ('paga'::character varying)::text, ('cancelada'::character varying)::text, ('vencida'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_fees ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_fees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_financial_config (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    conta_receita_id bigint,
    conta_bancaria_id bigint,
    centro_custo_id bigint,
    criar_movimento_financeiro boolean DEFAULT false NOT NULL,
    criar_movimento_tesouraria boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    criar_lancamento_contabilidade boolean DEFAULT false NOT NULL,
    conta_debito_id bigint,
    conta_credito_id bigint,
    criar_recibo_faturacao boolean DEFAULT false NOT NULL,
    customer_group_id bigint
);
ALTER TABLE gestao_escolar.school_financial_config ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_financial_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_grade_formulas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    level_id bigint,
    course_id bigint,
    nome character varying(120) NOT NULL,
    descricao text,
    tipo_periodo character varying(30) DEFAULT 'todos'::character varying NOT NULL,
    formula jsonb DEFAULT '{}'::jsonb NOT NULL,
    activa boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_grade_formulas_check CHECK (((level_id IS NOT NULL) OR (course_id IS NOT NULL)))
);
ALTER TABLE gestao_escolar.school_grade_formulas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_grade_formulas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_grade_items (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    term_id bigint NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(30) DEFAULT 'teste'::character varying NOT NULL,
    data_avaliacao date,
    nota_maxima numeric(6,2) DEFAULT 20 NOT NULL,
    peso numeric(6,2) DEFAULT 1 NOT NULL,
    publicado boolean DEFAULT false NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_grade_items_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('TESTE'::character varying)::text, ('TRABALHO'::character varying)::text, ('APRESENTACAO'::character varying)::text, ('EXAME'::character varying)::text, ('RECURSO'::character varying)::text, ('OUTRO'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_grade_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_grade_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_grades (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    grade_item_id bigint NOT NULL,
    student_id bigint NOT NULL,
    enrollment_id bigint,
    nota numeric(6,2),
    observacoes text,
    lancado_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_grades ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_guardians (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    student_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    parentesco character varying(50),
    telefone character varying(30) NOT NULL,
    email character varying(120),
    nuit character varying(30),
    endereco text,
    principal boolean DEFAULT false NOT NULL,
    autorizado_recolher boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    client_id bigint,
    user_id bigint,
    portal_email text,
    portal_ativo boolean DEFAULT false NOT NULL,
    portal_invite_token text,
    portal_invite_expires_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    pessoa_id bigint
);
ALTER TABLE gestao_escolar.school_guardians ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_guardians_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_incident_types (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    gravidade character varying(20) DEFAULT 'media'::character varying NOT NULL,
    requer_encarregado boolean DEFAULT false NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_incident_types_gravidade_check CHECK (((gravidade)::text = ANY (ARRAY[('leve'::character varying)::text, ('media'::character varying)::text, ('grave'::character varying)::text, ('muito_grave'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_incident_types ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_incident_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_levels (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    ordem integer DEFAULT 0 NOT NULL,
    nota_minima_aprovacao numeric(6,2) DEFAULT 10 NOT NULL,
    escala_maxima numeric(6,2) DEFAULT 20 NOT NULL,
    sistema_avaliacao character varying(30) DEFAULT '0-20'::character varying NOT NULL,
    numero_periodos_padrao integer DEFAULT 3 NOT NULL,
    nomenclatura_periodo character varying(30) DEFAULT 'trimestre'::character varying NOT NULL,
    nomenclatura_serie character varying(30) DEFAULT 'classe'::character varying NOT NULL,
    idade_minima integer,
    idade_maxima integer,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_levels ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_library_loans (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    book_id bigint NOT NULL,
    student_id bigint,
    borrower_type character varying(20) DEFAULT 'aluno'::character varying NOT NULL,
    borrower_id bigint,
    emprestado_em date DEFAULT CURRENT_DATE NOT NULL,
    devolucao_prevista date NOT NULL,
    devolvido_em date,
    status character varying(20) DEFAULT 'emprestado'::character varying NOT NULL,
    observacoes text,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_library_loans_status_check CHECK (((status)::text = ANY (ARRAY[('emprestado'::character varying)::text, ('devolvido'::character varying)::text, ('atrasado'::character varying)::text, ('perdido'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_library_loans ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_library_loans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_messages (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(180) NOT NULL,
    conteudo text NOT NULL,
    tipo character varying(30) DEFAULT 'comunicado'::character varying NOT NULL,
    audience_type character varying(30) DEFAULT 'todos'::character varying NOT NULL,
    audience_id bigint,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    publicado_em timestamp with time zone,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_messages_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('publicado'::character varying)::text, ('arquivado'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_messages ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_payments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_fee_id bigint NOT NULL,
    student_id bigint NOT NULL,
    external_id character varying(100),
    metodo character varying(30) NOT NULL,
    referencia character varying(100),
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    conciliado boolean DEFAULT false NOT NULL,
    pago_em timestamp with time zone DEFAULT now() NOT NULL,
    created_by bigint,
    payload_gateway jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_payments_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('confirmado'::character varying)::text, ('falhado'::character varying)::text, ('estornado'::character varying)::text]))),
    CONSTRAINT school_payments_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE gestao_escolar.school_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_sanction_types (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    gravidade character varying(20) DEFAULT 'media'::character varying NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_sanction_types_gravidade_check CHECK (((gravidade)::text = ANY (ARRAY[('leve'::character varying)::text, ('media'::character varying)::text, ('grave'::character varying)::text, ('muito_grave'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_sanction_types ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_sanction_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_series (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    level_id bigint NOT NULL,
    cycle_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_series ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_series_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_student_fee_discounts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    student_id bigint NOT NULL,
    fee_plan_id bigint,
    tipo character varying(20) DEFAULT 'percentagem'::character varying NOT NULL,
    valor numeric(18,2) DEFAULT 0 NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    motivo text,
    aprovado_por bigint,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_student_fee_discounts_check CHECK (((data_fim IS NULL) OR (data_fim >= data_inicio))),
    CONSTRAINT school_student_fee_discounts_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('percentagem'::character varying)::text, ('valor_fixo'::character varying)::text, ('isencao_total'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_student_fee_discounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_student_fee_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_student_incidents (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint NOT NULL,
    student_id bigint NOT NULL,
    enrollment_id bigint,
    incident_type_id bigint,
    reported_by bigint NOT NULL,
    data_ocorrencia date DEFAULT CURRENT_DATE NOT NULL,
    hora_ocorrencia time without time zone,
    local character varying(120),
    descricao text NOT NULL,
    testemunhas text,
    anexos jsonb DEFAULT '[]'::jsonb,
    status character varying(20) DEFAULT 'registada'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_student_incidents_status_check CHECK (((status)::text = ANY (ARRAY[('registada'::character varying)::text, ('em_analise'::character varying)::text, ('resolvida'::character varying)::text, ('arquivada'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_student_incidents ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_student_incidents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_student_merits (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint NOT NULL,
    student_id bigint NOT NULL,
    enrollment_id bigint,
    titulo character varying(150) NOT NULL,
    descricao text,
    data_merito date DEFAULT CURRENT_DATE NOT NULL,
    atribuido_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_student_merits ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_student_merits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_student_roles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    student_id bigint NOT NULL,
    class_id bigint,
    cargo character varying(100) NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    activo boolean DEFAULT true NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_student_roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_student_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_student_sanctions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    incident_id bigint NOT NULL,
    sanction_type_id bigint,
    aplicado_por bigint NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    descricao text,
    cumprida boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_student_sanctions_check CHECK (((data_fim IS NULL) OR (data_fim >= data_inicio)))
);
ALTER TABLE gestao_escolar.school_student_sanctions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_student_sanctions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_students (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    data_nascimento date,
    genero character varying(20),
    encarregado_nome character varying(150),
    encarregado_telefone character varying(30),
    encarregado_email character varying(150),
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    documento_tipo character varying(30),
    documento_numero character varying(60),
    nuit character varying(30),
    telefone character varying(30),
    email character varying(120),
    endereco text,
    fotografia_url text,
    client_id bigint,
    user_id bigint,
    portal_email text,
    portal_ativo boolean DEFAULT false NOT NULL,
    portal_invite_token text,
    portal_invite_expires_at timestamp with time zone,
    pessoa_id bigint,
    CONSTRAINT school_students_estado_check CHECK (((estado)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text, ('transferido'::character varying)::text, ('graduado'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_students ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_subjects (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    carga_horaria integer,
    nota_minima numeric(6,2) DEFAULT 10 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by bigint,
    cor character varying(7) DEFAULT NULL::character varying,
    icone character varying(50) DEFAULT NULL::character varying
);
ALTER TABLE gestao_escolar.school_subjects ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_tasks (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint,
    class_id bigint NOT NULL,
    subject_id bigint,
    teacher_id bigint NOT NULL,
    titulo character varying(180) NOT NULL,
    descricao text,
    tipo character varying(30) DEFAULT 'tarefa'::character varying NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date NOT NULL,
    status character varying(20) DEFAULT 'activa'::character varying NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_tasks_status_check CHECK (((status)::text = ANY (ARRAY[('activa'::character varying)::text, ('concluida'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_tasks ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_teacher_assignments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_teacher_assignments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_teacher_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_teacher_roles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    cargo character varying(100) NOT NULL,
    school_year_id bigint,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    activo boolean DEFAULT true NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE gestao_escolar.school_teacher_roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_teacher_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_teachers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    user_id bigint,
    codigo character varying(30) NOT NULL,
    nome_completo character varying(160) NOT NULL,
    genero character varying(20),
    telefone character varying(40),
    email character varying(150),
    documento_identificacao character varying(60),
    especialidade character varying(120),
    carga_horaria_maxima_semanal integer DEFAULT 40,
    status character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    rh_employee_id bigint,
    pessoa_id bigint,
    CONSTRAINT school_teachers_status_check CHECK (((status)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text, ('suspenso'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_teachers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_teachers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_terms (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    peso numeric(6,2) DEFAULT 1 NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by bigint,
    tipo character varying(30) DEFAULT 'trimestre'::character varying NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    level_id bigint NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_terms_check CHECK ((data_fim >= data_inicio)),
    CONSTRAINT school_terms_status_check CHECK (((status)::text = ANY (ARRAY[('aberto'::character varying)::text, ('encerrado'::character varying)::text]))),
    CONSTRAINT school_terms_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('trimestre'::character varying)::text, ('semestre'::character varying)::text, ('bimestre'::character varying)::text, ('modulo'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_terms ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_time_slots (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(60),
    hora_inicio time without time zone NOT NULL,
    hora_fim time without time zone NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_time_slots_check CHECK ((hora_fim > hora_inicio))
);
ALTER TABLE gestao_escolar.school_time_slots ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_time_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_timetable_entries (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint NOT NULL,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    time_slot_id bigint NOT NULL,
    dia_semana integer NOT NULL,
    sala character varying(50),
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_timetable_entries_check CHECK (((data_fim IS NULL) OR (data_fim >= data_inicio))),
    CONSTRAINT school_timetable_entries_dia_semana_check CHECK (((dia_semana >= 1) AND (dia_semana <= 7)))
);
ALTER TABLE gestao_escolar.school_timetable_entries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_timetable_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_transcript_subjects (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    transcript_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    nota_final numeric(6,2) NOT NULL,
    nota_maxima numeric(6,2) DEFAULT 20 NOT NULL,
    faltas integer DEFAULT 0,
    resultado character varying(20) DEFAULT 'aprovado'::character varying NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_transcript_subjects_resultado_check CHECK (((resultado)::text = ANY (ARRAY[('aprovado'::character varying)::text, ('reprovado'::character varying)::text, ('dispensado'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_transcript_subjects ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_transcript_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS gestao_escolar.school_years (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by bigint,
    CONSTRAINT school_years_check CHECK ((data_fim >= data_inicio)),
    CONSTRAINT school_years_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('activo'::character varying)::text, ('encerrado'::character varying)::text])))
);
ALTER TABLE gestao_escolar.school_years ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_years_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.tax_certificates (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    entity_type character varying(30) NOT NULL,
    entity_id bigint NOT NULL,
    tipo character varying(40) NOT NULL,
    numero character varying(80) NOT NULL,
    data_emissao date NOT NULL,
    validade date,
    ficheiro_url text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_certificates_entity_type_check CHECK (((entity_type)::text = ANY (ARRAY[('tenant'::character varying)::text, ('customer'::character varying)::text, ('supplier'::character varying)::text, ('employee'::character varying)::text]))),
    CONSTRAINT tax_certificates_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('isencao'::character varying)::text, ('bom_contribuinte'::character varying)::text, ('residencia_fiscal'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE impostos.tax_certificates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_certificates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.tax_exemptions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tax_id bigint NOT NULL,
    entity_type character varying(30) NOT NULL,
    entity_id bigint NOT NULL,
    motivo character varying(255),
    numero_isencao character varying(60),
    validade date,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_exemptions_entity_type_check CHECK (((entity_type)::text = ANY (ARRAY[('customer'::character varying)::text, ('supplier'::character varying)::text, ('product'::character varying)::text, ('product_category'::character varying)::text])))
);
ALTER TABLE impostos.tax_exemptions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_exemptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.tax_groups (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(20) NOT NULL,
    nome character varying(100) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE impostos.tax_groups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.tax_regimes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    tipo character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    data_inicio date,
    data_fim date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_regimes_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('simplificado'::character varying)::text, ('normal'::character varying)::text, ('isento'::character varying)::text])))
);
ALTER TABLE impostos.tax_regimes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_regimes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.tax_return_lines (
    id bigint NOT NULL,
    tax_return_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    descricao character varying(255) NOT NULL,
    natureza character varying(20) NOT NULL,
    base_imponivel numeric(18,2) DEFAULT 0 NOT NULL,
    taxa numeric(8,4) DEFAULT 0 NOT NULL,
    valor numeric(18,2) DEFAULT 0 NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    documento_numero character varying(80),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_return_lines_natureza_check CHECK (((natureza)::text = ANY (ARRAY[('debito'::character varying)::text, ('credito'::character varying)::text, ('retencao'::character varying)::text])))
);
ALTER TABLE impostos.tax_return_lines ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_return_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.tax_returns (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    periodo character varying(20) NOT NULL,
    tipo character varying(30) NOT NULL,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    total_base numeric(18,2) DEFAULT 0 NOT NULL,
    total_imposto numeric(18,2) DEFAULT 0 NOT NULL,
    total_credito numeric(18,2) DEFAULT 0 NOT NULL,
    total_a_pagar numeric(18,2) DEFAULT 0 NOT NULL,
    data_submissao timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    periodo_inicio date,
    periodo_fim date,
    substitui_id bigint,
    submetida_por bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total_a_recuperar numeric(18,2) DEFAULT 0 NOT NULL,
    CONSTRAINT tax_returns_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('submetida'::character varying)::text, ('paga'::character varying)::text, ('cancelada'::character varying)::text]))),
    CONSTRAINT tax_returns_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('iva'::character varying)::text, ('irps'::character varying)::text, ('irpc'::character varying)::text, ('retencoes'::character varying)::text])))
);
ALTER TABLE impostos.tax_returns ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_returns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.tax_rules (
    id bigint NOT NULL,
    tax_id bigint NOT NULL,
    valor_minimo numeric(18,2) DEFAULT 0 NOT NULL,
    valor_maximo numeric(18,2),
    taxa numeric(8,4) DEFAULT 0 NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_tax_rules_intervalo CHECK (((valor_maximo IS NULL) OR (valor_maximo > valor_minimo))),
    CONSTRAINT chk_tax_rules_taxa CHECK ((taxa >= (0)::numeric))
);
ALTER TABLE impostos.tax_rules ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.tax_transactions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tax_id bigint NOT NULL,
    referencia_tipo character varying(30) NOT NULL,
    referencia_id bigint,
    fiscal_period_id bigint,
    base_tributavel numeric(18,2) DEFAULT 0 NOT NULL,
    taxa_aplicada numeric(8,4) DEFAULT 0 NOT NULL,
    valor_imposto numeric(18,2) DEFAULT 0 NOT NULL,
    transaction_date date NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_tax_transactions_base CHECK ((base_tributavel >= (0)::numeric)),
    CONSTRAINT chk_tax_transactions_valor CHECK ((valor_imposto >= (0)::numeric))
);
ALTER TABLE impostos.tax_transactions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.taxes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    taxa numeric(8,4) DEFAULT 0 NOT NULL,
    tipo character varying(20) DEFAULT 'iva'::character varying NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tax_group_id bigint,
    CONSTRAINT taxes_taxa_check CHECK ((taxa >= (0)::numeric)),
    CONSTRAINT taxes_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('iva'::character varying)::text, ('isento'::character varying)::text, ('zero'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE impostos.taxes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.withholding_tax_transactions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    withholding_tax_id bigint NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    base_imponivel numeric(18,2) NOT NULL,
    taxa_aplicada numeric(8,4) NOT NULL,
    valor_retido numeric(18,2) NOT NULL,
    transaction_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entity_type character varying(30),
    entity_id bigint,
    documento_numero character varying(80),
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE impostos.withholding_tax_transactions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.withholding_tax_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS impostos.withholding_taxes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    taxa numeric(8,4) NOT NULL,
    aplica_em character varying(30) NOT NULL,
    tipo_entidade character varying(30),
    ativo boolean DEFAULT true NOT NULL,
    tipo character varying(10) DEFAULT 'IRPS'::character varying NOT NULL,
    descricao text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT withholding_taxes_aplica_em_check CHECK (((aplica_em)::text = ANY (ARRAY[('pagamento'::character varying)::text, ('fatura'::character varying)::text]))),
    CONSTRAINT withholding_taxes_taxa_check CHECK ((taxa >= (0)::numeric)),
    CONSTRAINT withholding_taxes_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('IRPS'::character varying)::text, ('IRPC'::character varying)::text]))),
    CONSTRAINT withholding_taxes_tipo_entidade_check CHECK (((tipo_entidade)::text = ANY (ARRAY[('pessoa_singular'::character varying)::text, ('pessoa_colectiva'::character varying)::text, ('todos'::character varying)::text])))
);
ALTER TABLE impostos.withholding_taxes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.withholding_taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS logistica.logistics_drivers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    telefone character varying(30),
    carta_numero character varying(50),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE logistica.logistics_drivers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_drivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS logistica.logistics_routes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    origem character varying(150) NOT NULL,
    destino character varying(150) NOT NULL,
    distancia_km numeric(18,2),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE logistica.logistics_routes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS logistica.logistics_shipments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    source_service character varying(100) NOT NULL,
    source_type character varying(100) NOT NULL,
    source_id bigint NOT NULL,
    logistics_route_id bigint,
    vehicle_id bigint,
    driver_id bigint,
    customer_id bigint,
    delivery_address text,
    scheduled_date date,
    status character varying(20) DEFAULT 'planeada'::character varying NOT NULL,
    observacoes text,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT logistics_shipments_status_check CHECK (((status)::text = ANY (ARRAY[('planeada'::character varying)::text, ('despachada'::character varying)::text, ('em_transito'::character varying)::text, ('entregue'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE logistica.logistics_shipments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_shipments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS logistica.logistics_tracking_events (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    shipment_id bigint NOT NULL,
    evento character varying(30) NOT NULL,
    localizacao character varying(255),
    latitude numeric(10,7),
    longitude numeric(10,7),
    observacoes text,
    event_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT logistics_tracking_events_evento_check CHECK (((evento)::text = ANY (ARRAY[('planeado'::character varying)::text, ('despachado'::character varying)::text, ('em_transito'::character varying)::text, ('entregue'::character varying)::text, ('falha_entrega'::character varying)::text, ('cancelado'::character varying)::text])))
);
ALTER TABLE logistica.logistics_tracking_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_tracking_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS logistica.logistics_vehicles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    matricula character varying(30) NOT NULL,
    descricao character varying(150),
    capacidade_kg numeric(18,2),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE logistica.logistics_vehicles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS multi_moeda.currencies (
    id bigint NOT NULL,
    code character varying(10) NOT NULL,
    name character varying(100) NOT NULL,
    symbol character varying(10),
    decimals integer DEFAULT 2 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT currencies_decimals_check CHECK (((decimals >= 0) AND (decimals <= 6)))
);
COMMENT ON TABLE multi_moeda.currencies IS 'Fonte canónica de moedas para operações financeiras multi-tenant. Inclui decimais e suporte a múltiplos tenants.';
ALTER TABLE multi_moeda.currencies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME multi_moeda.currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS multi_moeda.exchange_rates (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    base_currency_id bigint NOT NULL,
    quote_currency_id bigint NOT NULL,
    rate numeric(18,6) NOT NULL,
    source character varying(50) DEFAULT 'manual'::character varying NOT NULL,
    effective_date date DEFAULT CURRENT_DATE NOT NULL,
    is_official boolean DEFAULT false NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_exchange_rate_pair CHECK ((base_currency_id <> quote_currency_id)),
    CONSTRAINT exchange_rates_rate_check CHECK ((rate > (0)::numeric))
);
ALTER TABLE multi_moeda.exchange_rates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME multi_moeda.exchange_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS multi_moeda.tenant_currencies (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    currency_id bigint NOT NULL,
    is_base boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE multi_moeda.tenant_currencies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME multi_moeda.tenant_currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS notifications.notification_channels (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    tipo character varying(20) NOT NULL,
    configuracao jsonb,
    activo boolean DEFAULT true NOT NULL,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT notification_channels_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('email'::character varying)::text, ('sms'::character varying)::text, ('whatsapp'::character varying)::text, ('push'::character varying)::text])))
);
ALTER TABLE notifications.notification_channels ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME notifications.notification_channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS notifications.notification_messages (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    channel_id bigint,
    template_id bigint,
    canal_tipo character varying(20) NOT NULL,
    destinatario character varying(180) NOT NULL,
    assunto character varying(150),
    corpo text NOT NULL,
    payload jsonb,
    referencia_tipo character varying(50),
    referencia_id bigint,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    tentativas integer DEFAULT 0 NOT NULL,
    erro text,
    enviado_em timestamp with time zone,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT notification_messages_canal_tipo_check CHECK (((canal_tipo)::text = ANY (ARRAY[('email'::character varying)::text, ('sms'::character varying)::text, ('whatsapp'::character varying)::text, ('push'::character varying)::text]))),
    CONSTRAINT notification_messages_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('enviado'::character varying)::text, ('falha'::character varying)::text, ('cancelado'::character varying)::text])))
);
ALTER TABLE notifications.notification_messages ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME notifications.notification_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS notifications.notification_templates (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    canal_tipo character varying(20) NOT NULL,
    assunto character varying(150),
    corpo text NOT NULL,
    variaveis jsonb,
    activo boolean DEFAULT true NOT NULL,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT notification_templates_canal_tipo_check CHECK (((canal_tipo)::text = ANY (ARRAY[('email'::character varying)::text, ('sms'::character varying)::text, ('whatsapp'::character varying)::text, ('push'::character varying)::text])))
);
ALTER TABLE notifications.notification_templates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME notifications.notification_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS notifications.push_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying(255) NOT NULL,
    platform character varying(20) DEFAULT 'android'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE notifications.push_tokens ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME notifications.push_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS pessoas.pessoa_contatos (
    id bigint NOT NULL,
    pessoa_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    valor character varying(255) NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    verificado boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pessoa_contatos_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['email'::character varying, 'telefone'::character varying, 'whatsapp'::character varying])::text[])))
);
ALTER TABLE pessoas.pessoa_contatos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pessoas.pessoa_contatos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS pessoas.pessoa_enderecos (
    id bigint NOT NULL,
    pessoa_id bigint NOT NULL,
    tipo character varying(30) DEFAULT 'residencia'::character varying NOT NULL,
    provincia character varying(60),
    cidade character varying(60),
    bairro character varying(100),
    logradouro text,
    codigo_postal character varying(20),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE pessoas.pessoa_enderecos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pessoas.pessoa_enderecos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS pessoas.pessoa_relacoes (
    id bigint NOT NULL,
    tenant_id bigint,
    pessoa_id bigint NOT NULL,
    pessoa_relacionada_id bigint NOT NULL,
    tipo_relacao character varying(50) NOT NULL,
    responsavel_legal boolean DEFAULT false NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pessoa_relacoes_tipo_relacao_check CHECK (((tipo_relacao)::text = ANY ((ARRAY['pai'::character varying, 'mae'::character varying, 'tutor'::character varying, 'encarregado'::character varying, 'filho'::character varying, 'filha'::character varying, 'conjuge'::character varying, 'irmao'::character varying, 'irma'::character varying, 'avo'::character varying, 'avo_materno'::character varying, 'avo_paterno'::character varying, 'tio'::character varying, 'tia'::character varying, 'outro'::character varying])::text[])))
);
ALTER TABLE pessoas.pessoa_relacoes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pessoas.pessoa_relacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS pessoas.pessoas (
    id bigint NOT NULL,
    codigo character varying(50),
    nome_completo character varying(200) NOT NULL,
    primeiro_nome character varying(100),
    ultimo_nome character varying(100),
    data_nascimento date,
    genero character varying(20),
    nuit character varying(30),
    tipo_documento character varying(30),
    numero_documento character varying(60),
    nacionalidade character varying(60),
    estado_civil character varying(30),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pessoas_genero_check CHECK (((genero)::text = ANY ((ARRAY['M'::character varying, 'F'::character varying, 'outro'::character varying, 'nao_informado'::character varying])::text[])))
);
ALTER TABLE pessoas.pessoas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pessoas.pessoas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS saas.tenants (
    id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    company_id bigint,
    status character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    dominio character varying(255),
    plano_id bigint,
    limite_utilizadores integer,
    limite_armazenamento_gb integer,
    validade_plano date,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tenants_status_check CHECK (((status)::text = ANY (ARRAY[('ativo'::character varying)::text, ('suspenso'::character varying)::text, ('inativo'::character varying)::text])))
);
CREATE OR REPLACE VIEW pessoas.v_pessoa_papeis AS
 SELECT p.id AS pessoa_id,
    p.nome_completo,
    u.id AS user_id,
    u.email,
    m.id AS membership_id,
    m.tenant_id,
    t.nome AS tenant_nome,
    m.papel,
    m.escopo,
    m.cargo_id,
    c.nome AS cargo_nome,
    m.ativo,
    m.data_inicio,
    m.data_fim
   FROM ((((auth.memberships m
     JOIN auth.users u ON ((u.id = m.user_id)))
     JOIN pessoas.pessoas p ON ((p.id = u.pessoa_id)))
     JOIN saas.tenants t ON ((t.id = m.tenant_id)))
     LEFT JOIN auth.cargos c ON ((c.id = m.cargo_id)));
CREATE TABLE IF NOT EXISTS pos.pos_catalog_items (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    codigo_barra character varying(80),
    preco_venda numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE pos.pos_catalog_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_catalog_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS pos.pos_sale_items (
    id bigint NOT NULL,
    pos_sale_id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    descricao character varying(255),
    quantidade numeric(18,2) NOT NULL,
    preco_unitario numeric(18,2) NOT NULL,
    desconto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pos_sale_items_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT pos_sale_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);
ALTER TABLE pos.pos_sale_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_sale_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS pos.pos_sale_payments (
    id bigint NOT NULL,
    pos_sale_id bigint NOT NULL,
    payment_method_id bigint,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    referencia character varying(100),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pos_sale_payments_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('numerario'::character varying)::text, ('transferencia'::character varying)::text, ('tpa'::character varying)::text, ('mpesa'::character varying)::text, ('emola'::character varying)::text, ('outro'::character varying)::text]))),
    CONSTRAINT pos_sale_payments_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE pos.pos_sale_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_sale_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS pos.pos_sales (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    pos_session_id bigint NOT NULL,
    terminal_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    customer_id bigint,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_recebido numeric(18,2) DEFAULT 0 NOT NULL,
    troco numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    sold_at timestamp with time zone,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pos_sales_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('concluida'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE pos.pos_sales ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_sales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS pos.pos_sessions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    terminal_id bigint NOT NULL,
    user_id bigint NOT NULL,
    opened_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_at timestamp with time zone,
    opening_amount numeric(18,2) DEFAULT 0 NOT NULL,
    closing_amount numeric(18,2),
    status character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pos_sessions_status_check CHECK (((status)::text = ANY (ARRAY[('aberta'::character varying)::text, ('fechada'::character varying)::text])))
);
ALTER TABLE pos.pos_sessions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS pos.pos_terminals (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    warehouse_id bigint,
    caixa_id bigint,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE pos.pos_terminals ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_terminals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_attribute_values (
    id bigint NOT NULL,
    product_attribute_id bigint NOT NULL,
    product_id bigint,
    product_variant_id bigint,
    valor character varying(150) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_attribute_values ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_attribute_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_attributes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    tipo character varying(30) DEFAULT 'texto'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT product_attributes_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('texto'::character varying)::text, ('numero'::character varying)::text, ('lista'::character varying)::text, ('booleano'::character varying)::text, ('cor'::character varying)::text])))
);
ALTER TABLE produtos.product_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_barcodes (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    barcode character varying(100) NOT NULL,
    tipo character varying(30),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_barcodes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_barcodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_brands (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_brands ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_brands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_categories (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    parent_id bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_categories ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_discounts (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    motivo character varying(150),
    inicia_em timestamp with time zone,
    fim_em timestamp with time zone,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT product_discounts_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('percentual'::character varying)::text, ('valor_fixo'::character varying)::text]))),
    CONSTRAINT product_discounts_valor_check CHECK ((valor >= (0)::numeric))
);
ALTER TABLE produtos.product_discounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_images (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    ficheiro_url text NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_images ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_kit_items (
    id bigint NOT NULL,
    product_kit_id bigint NOT NULL,
    item_product_id bigint NOT NULL,
    item_variant_id bigint,
    quantidade numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT product_kit_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);
ALTER TABLE produtos.product_kit_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_kit_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_kits (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(150) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_kits ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_kits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_prices (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    tipo_preco character varying(30) DEFAULT 'venda'::character varying NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    valor numeric(18,2) NOT NULL,
    inicia_em timestamp with time zone,
    fim_em timestamp with time zone,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT product_prices_tipo_preco_check CHECK (((tipo_preco)::text = ANY (ARRAY[('custo'::character varying)::text, ('venda'::character varying)::text, ('atacado'::character varying)::text, ('promocional'::character varying)::text]))),
    CONSTRAINT product_prices_valor_check CHECK ((valor >= (0)::numeric))
);
ALTER TABLE produtos.product_prices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_subcategories (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    product_category_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_subcategories ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_subcategories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_tag_links (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_tag_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_tag_links ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_tag_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_tags (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    cor character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_tags ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_units (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(80) NOT NULL,
    simbolo character varying(20),
    casas_decimais integer DEFAULT 2 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_units ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_units_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.product_variants (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(150) NOT NULL,
    sku character varying(80),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.product_variants ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.products (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    product_category_id bigint,
    product_subcategory_id bigint,
    product_brand_id bigint,
    product_unit_id bigint,
    warehouse_default_id bigint,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    tipo character varying(30) DEFAULT 'simples'::character varying NOT NULL,
    iva_percentual numeric(5,2) DEFAULT 17.00 NOT NULL,
    stock_minimo numeric(18,2) DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT products_iva_percentual_check CHECK ((iva_percentual >= (0)::numeric)),
    CONSTRAINT products_stock_minimo_check CHECK ((stock_minimo >= (0)::numeric)),
    CONSTRAINT products_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('simples'::character varying)::text, ('variavel'::character varying)::text, ('kit'::character varying)::text, ('servico'::character varying)::text])))
);
ALTER TABLE produtos.products ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS produtos.warehouses (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    localizacao character varying(255),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE produtos.warehouses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.warehouses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS public.chat_conversas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(200),
    tipo character varying(20) DEFAULT 'individual'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chat_conversas_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('individual'::character varying)::text, ('grupo'::character varying)::text])))
);
CREATE SEQUENCE IF NOT EXISTS public.chat_conversas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.chat_conversas_id_seq OWNED BY public.chat_conversas.id;
CREATE TABLE IF NOT EXISTS public.chat_mensagens (
    id bigint NOT NULL,
    conversa_id bigint NOT NULL,
    autor_id bigint,
    conteudo text NOT NULL,
    tipo character varying(20) DEFAULT 'texto'::character varying NOT NULL,
    ficheiro_url character varying(500),
    eliminada boolean DEFAULT false NOT NULL,
    editada_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chat_mensagens_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('texto'::character varying)::text, ('imagem'::character varying)::text, ('ficheiro'::character varying)::text])))
);
CREATE SEQUENCE IF NOT EXISTS public.chat_mensagens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.chat_mensagens_id_seq OWNED BY public.chat_mensagens.id;
CREATE TABLE IF NOT EXISTS public.chat_participantes (
    conversa_id bigint NOT NULL,
    user_id bigint NOT NULL,
    adicionado_em timestamp with time zone DEFAULT now() NOT NULL,
    ultima_leitura timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public.comunicados (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(300) NOT NULL,
    conteudo text NOT NULL,
    autor_id bigint,
    expira_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE IF NOT EXISTS public.comunicados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.comunicados_id_seq OWNED BY public.comunicados.id;
CREATE TABLE IF NOT EXISTS public.comunicados_lidos (
    comunicado_id bigint NOT NULL,
    user_id bigint NOT NULL,
    lido_em timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.notif_colaborador (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    user_id bigint NOT NULL,
    tipo character varying(50) NOT NULL,
    titulo character varying(300) NOT NULL,
    corpo text,
    lida boolean DEFAULT false NOT NULL,
    link character varying(500),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE IF NOT EXISTS public.notif_colaborador_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.notif_colaborador_id_seq OWNED BY public.notif_colaborador.id;
CREATE TABLE IF NOT EXISTS recrutamento.candidato_sessions (
    id bigint NOT NULL,
    candidato_id bigint NOT NULL,
    token_hash text NOT NULL,
    ip inet,
    user_agent text,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    revogado_em timestamp with time zone
);
CREATE SEQUENCE IF NOT EXISTS recrutamento.candidato_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE recrutamento.candidato_sessions_id_seq OWNED BY recrutamento.candidato_sessions.id;
CREATE TABLE IF NOT EXISTS recrutamento.candidatos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    email character varying(255) NOT NULL,
    nome character varying(150) NOT NULL,
    telefone character varying(30),
    email_verificado boolean DEFAULT false NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_id bigint,
    pessoa_id bigint
);
ALTER TABLE recrutamento.candidatos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.candidatos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS recrutamento.candidatura_campos_custom (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    label character varying(150) NOT NULL,
    tipo character varying(30) NOT NULL,
    opcoes jsonb DEFAULT '[]'::jsonb NOT NULL,
    obrigatorio boolean DEFAULT false NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT candidatura_campos_custom_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('texto'::character varying)::text, ('textarea'::character varying)::text, ('numero'::character varying)::text, ('data'::character varying)::text, ('select'::character varying)::text, ('multiselect'::character varying)::text, ('checkbox'::character varying)::text, ('ficheiro'::character varying)::text])))
);
ALTER TABLE recrutamento.candidatura_campos_custom ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.candidatura_campos_custom_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS recrutamento.candidatura_notas (
    id bigint NOT NULL,
    candidatura_id bigint NOT NULL,
    autor character varying(100) DEFAULT 'admin'::character varying NOT NULL,
    tipo character varying(20) DEFAULT 'nota'::character varying NOT NULL,
    conteudo text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT candidatura_notas_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('nota'::character varying)::text, ('entrevista'::character varying)::text, ('avaliacao'::character varying)::text, ('sistema'::character varying)::text])))
);
ALTER TABLE recrutamento.candidatura_notas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.candidatura_notas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS recrutamento.candidatura_respostas_vaga (
    id bigint NOT NULL,
    candidatura_id bigint NOT NULL,
    campo_id bigint NOT NULL,
    valor text,
    ficheiro character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE recrutamento.candidatura_respostas_vaga ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.candidatura_respostas_vaga_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS recrutamento.candidatura_valores_custom (
    id bigint NOT NULL,
    candidatura_id bigint NOT NULL,
    campo_id bigint NOT NULL,
    valor text,
    ficheiro character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE recrutamento.candidatura_valores_custom ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.candidatura_valores_custom_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS recrutamento.candidaturas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    vaga_id bigint,
    nome character varying(150) NOT NULL,
    email character varying(255) NOT NULL,
    telefone character varying(30),
    vaga_titulo character varying(200) NOT NULL,
    carta text,
    cv_ficheiro character varying(255),
    carta_ficheiro character varying(255),
    ip character varying(45) NOT NULL,
    estado character varying(20) DEFAULT 'recebida'::character varying NOT NULL,
    score smallint,
    responsavel character varying(100),
    entrevista_data timestamp with time zone,
    entrevista_local character varying(200),
    entrevista_link character varying(300),
    entrevista_notas text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    codigo_acompanhamento character varying(20),
    candidato_id bigint,
    pretensao_salarial numeric(12,2),
    disponibilidade character varying(50),
    anos_experiencia integer,
    linkedin character varying(255),
    portfolio character varying(255),
    cidade character varying(100),
    provincia character varying(100),
    como_conheceu character varying(100),
    necessidades_especiais text,
    rh_funcionario_id bigint,
    consentimento_dados boolean DEFAULT false NOT NULL,
    data_consentimento timestamp with time zone,
    CONSTRAINT candidaturas_estado_check CHECK (((estado)::text = ANY (ARRAY[('recebida'::character varying)::text, ('em_analise'::character varying)::text, ('entrevista'::character varying)::text, ('aprovada'::character varying)::text, ('rejeitada'::character varying)::text, ('contratado'::character varying)::text]))),
    CONSTRAINT candidaturas_score_check CHECK (((score >= 1) AND (score <= 5)))
);
ALTER TABLE recrutamento.candidaturas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.candidaturas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS recrutamento.config_notificacoes (
    tenant_id bigint NOT NULL,
    canal_email boolean DEFAULT true NOT NULL,
    canal_sms boolean DEFAULT false NOT NULL,
    notificar_candidatura_recebida boolean DEFAULT true NOT NULL,
    notificar_em_analise boolean DEFAULT false NOT NULL,
    notificar_entrevista_agendada boolean DEFAULT true NOT NULL,
    notificar_aprovada boolean DEFAULT true NOT NULL,
    notificar_rejeitada boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    notificar_contratado boolean DEFAULT true NOT NULL
);
CREATE TABLE IF NOT EXISTS recrutamento.contactos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    email character varying(255) NOT NULL,
    assunto character varying(255) NOT NULL,
    mensagem text NOT NULL,
    ip character varying(45) NOT NULL,
    lido boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE recrutamento.contactos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.contactos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS recrutamento.vaga_campos (
    id bigint NOT NULL,
    vaga_id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    label character varying(150) NOT NULL,
    tipo character varying(30) NOT NULL,
    opcoes jsonb DEFAULT '[]'::jsonb NOT NULL,
    obrigatorio boolean DEFAULT false NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT vaga_campos_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('texto'::character varying)::text, ('textarea'::character varying)::text, ('numero'::character varying)::text, ('data'::character varying)::text, ('select'::character varying)::text, ('multiselect'::character varying)::text, ('checkbox'::character varying)::text, ('ficheiro'::character varying)::text])))
);
ALTER TABLE recrutamento.vaga_campos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.vaga_campos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS recrutamento.vagas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(200) NOT NULL,
    area character varying(100) NOT NULL,
    local character varying(100) DEFAULT 'Maputo, Mocambique'::character varying NOT NULL,
    regime character varying(50) DEFAULT 'Presencial / Hibrido'::character varying NOT NULL,
    tipo character varying(50) DEFAULT 'Estagio'::character varying NOT NULL,
    descricao text NOT NULL,
    sobre_funcao text,
    responsabilidades jsonb DEFAULT '[]'::jsonb NOT NULL,
    req_obrigatorios jsonb DEFAULT '[]'::jsonb NOT NULL,
    req_preferenciais jsonb DEFAULT '[]'::jsonb NOT NULL,
    oferece jsonb DEFAULT '[]'::jsonb NOT NULL,
    ativa boolean DEFAULT true NOT NULL,
    num_vagas smallint DEFAULT 1 NOT NULL,
    prazo date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    permite_publica boolean DEFAULT true NOT NULL,
    permite_conta boolean DEFAULT true NOT NULL,
    cargo_id bigint,
    CONSTRAINT vagas_num_vagas_check CHECK ((num_vagas > 0))
);
ALTER TABLE recrutamento.vagas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.vagas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.adiantamentos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    valor_total numeric(14,2) NOT NULL,
    num_prestacoes integer DEFAULT 1 NOT NULL,
    prestacao_valor numeric(14,2) NOT NULL,
    prestacoes_pagas integer DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    descricao text,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT adiantamentos_estado_check CHECK (((estado)::text = ANY (ARRAY[('ativo'::character varying)::text, ('quitado'::character varying)::text, ('cancelado'::character varying)::text])))
);
ALTER TABLE rh.adiantamentos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.adiantamentos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.auditoria_assiduidade (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tabela character varying(50) NOT NULL,
    registo_id bigint NOT NULL,
    operacao character varying(10) NOT NULL,
    campo character varying(100),
    valor_anterior jsonb,
    valor_novo jsonb,
    alterado_por bigint,
    motivo text,
    ip_origem inet,
    dispositivo text,
    localizacao character varying(200),
    estado_anterior character varying(30),
    estado_novo character varying(30),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT auditoria_assiduidade_operacao_check CHECK (((operacao)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[])))
);
CREATE SEQUENCE IF NOT EXISTS rh.auditoria_assiduidade_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.auditoria_assiduidade_id_seq OWNED BY rh.auditoria_assiduidade.id;
CREATE TABLE IF NOT EXISTS rh.ausencias (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    dias integer,
    motivo text,
    estado character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    aprovado_por bigint,
    aprovado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo_id bigint,
    CONSTRAINT ausencias_estado_check CHECK (((estado)::text = ANY (ARRAY[('pendente'::character varying)::text, ('aprovado'::character varying)::text, ('rejeitado'::character varying)::text, ('gozada'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE rh.ausencias ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.ausencias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.avaliacao_criterios (
    id bigint NOT NULL,
    avaliacao_id bigint NOT NULL,
    criterio_id bigint NOT NULL,
    pontuacao numeric(4,2) NOT NULL
);
ALTER TABLE rh.avaliacao_criterios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.avaliacao_criterios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.avaliacoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    periodo character varying(30),
    avaliador_id bigint,
    pontuacao numeric(4,2),
    comentarios text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    periodo_id bigint,
    estado character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    aprovado_por bigint,
    aprovado_em timestamp with time zone,
    CONSTRAINT avaliacoes_estado_check CHECK (((estado)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('submetida'::character varying)::text, ('aprovada'::character varying)::text])))
);
ALTER TABLE rh.avaliacoes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.avaliacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.beneficios (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    valor_padrao numeric(14,2),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.beneficios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.beneficios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.cargos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    salario_min numeric(14,2),
    salario_max numeric(14,2),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.cargos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.cargos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.componentes_salariais (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    tipo character varying(20) NOT NULL,
    forma_calculo character varying(20) DEFAULT 'fixo'::character varying NOT NULL,
    valor_padrao numeric(14,2),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT componentes_salariais_forma_calculo_check CHECK (((forma_calculo)::text = ANY (ARRAY[('fixo'::character varying)::text, ('percentual'::character varying)::text]))),
    CONSTRAINT componentes_salariais_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('provento'::character varying)::text, ('desconto'::character varying)::text])))
);
ALTER TABLE rh.componentes_salariais ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.componentes_salariais_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.config_contabilidade_folha (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    accounting_journal_id bigint NOT NULL,
    conta_despesa_salarios bigint NOT NULL,
    conta_inss_trabalhador bigint NOT NULL,
    conta_irps bigint NOT NULL,
    conta_salarios_a_pagar bigint NOT NULL,
    conta_adiantamentos bigint,
    conta_inss_patronal bigint,
    taxa_inss_patronal numeric(5,4) DEFAULT 0.07 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.config_contabilidade_folha ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.config_contabilidade_folha_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.contactos_emergencia (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    parentesco character varying(50),
    telefone character varying(30) NOT NULL,
    email character varying(150),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pessoa_id bigint
);
ALTER TABLE rh.contactos_emergencia ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.contactos_emergencia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.contratos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    funcao character varying(120),
    data_inicio date NOT NULL,
    data_fim date,
    salario numeric(14,2),
    ficheiro_url text,
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT contratos_estado_check CHECK (((estado)::text = ANY (ARRAY[('ativo'::character varying)::text, ('encerrado'::character varying)::text, ('rescindido'::character varying)::text]))),
    CONSTRAINT contratos_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('efetivo'::character varying)::text, ('indeterminado'::character varying)::text, ('termo_certo'::character varying)::text, ('termo_incerto'::character varying)::text, ('estagio'::character varying)::text, ('prestacao_servico'::character varying)::text])))
);
ALTER TABLE rh.contratos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.contratos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.correcoes_evento (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    evento_id bigint,
    data_referencia date NOT NULL,
    tipo character varying(40) NOT NULL,
    tipo_evento_id bigint,
    ocorrido_em_solicitado timestamp with time zone,
    localidade_id_solicitada bigint,
    motivo text NOT NULL,
    documento_url text,
    estado character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    solicitado_por bigint NOT NULL,
    solicitado_em timestamp with time zone DEFAULT now() NOT NULL,
    decidido_por bigint,
    decidido_em timestamp with time zone,
    justificacao_decisao text,
    evento_gerado_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT correcoes_evento_estado_check CHECK (((estado)::text = ANY ((ARRAY['pendente'::character varying, 'aprovado'::character varying, 'rejeitado'::character varying])::text[])))
);
CREATE SEQUENCE IF NOT EXISTS rh.correcoes_evento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.correcoes_evento_id_seq OWNED BY rh.correcoes_evento.id;
CREATE TABLE IF NOT EXISTS rh.criterios_avaliacao (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    peso numeric(5,2) DEFAULT 1 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.criterios_avaliacao ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.criterios_avaliacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.unidades_organizacionais (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    responsavel_id bigint,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo character varying(30) DEFAULT 'departamento'::character varying NOT NULL,
    parent_id bigint,
    CONSTRAINT unidades_organizacionais_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('departamento'::character varying)::text, ('equipa'::character varying)::text, ('divisao'::character varying)::text, ('seccao'::character varying)::text, ('direccao'::character varying)::text, ('gabinete'::character varying)::text, ('projeto'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE rh.unidades_organizacionais ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.departamentos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.documentos_funcionario (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    numero character varying(60),
    data_emissao date,
    data_validade date,
    ficheiro_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.documentos_funcionario ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.documentos_funcionario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.emprestimos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    valor_total numeric(14,2) NOT NULL,
    num_prestacoes integer DEFAULT 1 NOT NULL,
    prestacao_valor numeric(14,2) NOT NULL,
    prestacoes_pagas integer DEFAULT 0 NOT NULL,
    taxa_juros numeric(5,4) DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    descricao text,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT emprestimos_estado_check CHECK (((estado)::text = ANY (ARRAY[('ativo'::character varying)::text, ('quitado'::character varying)::text, ('cancelado'::character varying)::text])))
);
ALTER TABLE rh.emprestimos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.emprestimos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.eventos_assiduidade (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo_evento_id bigint NOT NULL,
    metodo_id bigint,
    ocorrido_em timestamp with time zone NOT NULL,
    data_referencia date NOT NULL,
    origem character varying(40) DEFAULT 'manual'::character varying NOT NULL,
    dispositivo_id bigint,
    qr_token_id bigint,
    nfc_tag_id bigint,
    latitude numeric(10,8),
    longitude numeric(11,8),
    localidade_id bigint,
    dentro_geofence boolean,
    foto_url text,
    documento_url text,
    estado character varying(30) DEFAULT 'valido'::character varying NOT NULL,
    registado_por bigint,
    motivo text,
    observacoes text,
    evento_pai_id bigint,
    duplicado_de_id bigint,
    ip_origem inet,
    user_agent text,
    hash_digital character varying(64),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT eventos_assiduidade_estado_check CHECK (((estado)::text = ANY ((ARRAY['valido'::character varying, 'pendente'::character varying, 'aprovado'::character varying, 'rejeitado'::character varying, 'corrigido'::character varying, 'duplicado'::character varying, 'incompleto'::character varying, 'fora_horario'::character varying, 'fora_localizacao'::character varying, 'manual'::character varying, 'importado'::character varying, 'em_analise'::character varying])::text[]))),
    CONSTRAINT eventos_assiduidade_origem_check CHECK (((origem)::text = ANY ((ARRAY['biometria'::character varying, 'impressao_digital'::character varying, 'reconhecimento_facial'::character varying, 'rfid'::character varying, 'nfc'::character varying, 'qr'::character varying, 'app'::character varying, 'web'::character varying, 'gps'::character varying, 'geofence'::character varying, 'selfie'::character varying, 'manual'::character varying, 'importacao'::character varying, 'api'::character varying])::text[])))
);
CREATE SEQUENCE IF NOT EXISTS rh.eventos_assiduidade_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.eventos_assiduidade_id_seq OWNED BY rh.eventos_assiduidade.id;
CREATE TABLE IF NOT EXISTS rh.folhas_pagamento (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    ano integer NOT NULL,
    mes integer NOT NULL,
    estado character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    num_funcionarios integer DEFAULT 0 NOT NULL,
    total_proventos numeric(14,2) DEFAULT 0 NOT NULL,
    total_descontos numeric(14,2) DEFAULT 0 NOT NULL,
    total_liquido numeric(14,2) DEFAULT 0 NOT NULL,
    processada_em timestamp with time zone,
    processada_por bigint,
    paga_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    journal_entry_id bigint,
    bank_account_id bigint,
    cash_register_id bigint,
    movement_id bigint,
    CONSTRAINT folhas_pagamento_estado_check CHECK (((estado)::text = ANY (ARRAY[('aberta'::character varying)::text, ('processada'::character varying)::text, ('paga'::character varying)::text, ('cancelada'::character varying)::text]))),
    CONSTRAINT folhas_pagamento_mes_check CHECK (((mes >= 1) AND (mes <= 12)))
);
ALTER TABLE rh.folhas_pagamento ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.folhas_pagamento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.formacoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    categoria character varying(20) DEFAULT 'tecnica'::character varying NOT NULL,
    duracao_horas numeric(6,2),
    entidade_formadora character varying(150),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT formacoes_categoria_check CHECK (((categoria)::text = ANY (ARRAY[('tecnica'::character varying)::text, ('comportamental'::character varying)::text, ('obrigatoria'::character varying)::text, ('outra'::character varying)::text])))
);
ALTER TABLE rh.formacoes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.formacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.funcionario_beneficios (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    beneficio_id bigint NOT NULL,
    valor numeric(14,2),
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    observacoes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.funcionario_beneficios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.funcionario_beneficios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.funcionario_componentes_salariais (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    componente_id bigint NOT NULL,
    valor numeric(14,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.funcionario_componentes_salariais ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.funcionario_componentes_salariais_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.funcionario_formacoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    formacao_id bigint NOT NULL,
    data_inicio date NOT NULL,
    data_fim date,
    estado character varying(20) DEFAULT 'planeada'::character varying NOT NULL,
    nota numeric(4,2),
    certificado_url text,
    observacoes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT funcionario_formacoes_estado_check CHECK (((estado)::text = ANY (ARRAY[('planeada'::character varying)::text, ('em_curso'::character varying)::text, ('concluida'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE rh.funcionario_formacoes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.funcionario_formacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.funcionario_horarios (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    horario_id bigint NOT NULL,
    data_inicio date NOT NULL,
    data_fim date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE IF NOT EXISTS rh.funcionario_horarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.funcionario_horarios_id_seq OWNED BY rh.funcionario_horarios.id;
CREATE TABLE IF NOT EXISTS rh.funcionarios (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    unit_id bigint,
    numero_funcionario character varying(30),
    nome_completo character varying(150) NOT NULL,
    data_nascimento date,
    genero character varying(10),
    nuit character varying(30),
    telefone character varying(30),
    email character varying(150),
    endereco text,
    cargo character varying(120),
    data_admissao date DEFAULT CURRENT_DATE NOT NULL,
    data_saida date,
    tipo_contrato character varying(30) DEFAULT 'efetivo'::character varying NOT NULL,
    salario_base numeric(14,2),
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_id bigint,
    cargo_id bigint,
    horario_id bigint,
    provincia character varying(60),
    cidade character varying(60),
    bairro character varying(100),
    centro_custo_id bigint,
    nacionalidade character varying(60),
    tipo_documento character varying(30),
    numero_documento character varying(60),
    pessoa_id bigint,
    CONSTRAINT funcionarios_estado_check CHECK (((estado)::text = ANY (ARRAY[('ativo'::character varying)::text, ('suspenso'::character varying)::text, ('licenca'::character varying)::text, ('desligado'::character varying)::text]))),
    CONSTRAINT funcionarios_genero_check CHECK (((genero)::text = ANY (ARRAY[('M'::character varying)::text, ('F'::character varying)::text, ('outro'::character varying)::text]))),
    CONSTRAINT funcionarios_tipo_contrato_check CHECK (((tipo_contrato)::text = ANY (ARRAY[('efetivo'::character varying)::text, ('indeterminado'::character varying)::text, ('termo_certo'::character varying)::text, ('termo_incerto'::character varying)::text, ('estagio'::character varying)::text, ('prestacao_servico'::character varying)::text])))
);
ALTER TABLE rh.funcionarios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.funcionarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.historico_salarial (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    salario_anterior numeric(14,2),
    salario_novo numeric(14,2) NOT NULL,
    data_efectiva date NOT NULL,
    motivo text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.historico_salarial ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.historico_salarial_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.horarios_dias (
    id bigint NOT NULL,
    horario_id bigint NOT NULL,
    dia_semana smallint,
    data_especifica date,
    ordem smallint DEFAULT 1 NOT NULL,
    hora_entrada interval NOT NULL,
    hora_saida interval NOT NULL,
    intervalo_inicio interval,
    intervalo_fim interval,
    tolerancia_atraso interval DEFAULT '00:00:00'::interval,
    tolerancia_saida_antecipada interval DEFAULT '00:00:00'::interval,
    eh_nocturno boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_horarios_dias_dia_ou_data CHECK ((((dia_semana IS NOT NULL) AND (data_especifica IS NULL)) OR ((dia_semana IS NULL) AND (data_especifica IS NOT NULL)))),
    CONSTRAINT horarios_dias_dia_semana_check CHECK (((dia_semana >= 1) AND (dia_semana <= 7)))
);
CREATE SEQUENCE IF NOT EXISTS rh.horarios_dias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.horarios_dias_id_seq OWNED BY rh.horarios_dias.id;
CREATE TABLE IF NOT EXISTS rh.horarios_trabalho (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    hora_entrada character varying(5) NOT NULL,
    hora_saida character varying(5) NOT NULL,
    intervalo_inicio character varying(5),
    intervalo_fim character varying(5),
    dias_semana character varying(20) DEFAULT '1,2,3,4,5'::character varying NOT NULL,
    carga_semanal_horas numeric(5,2),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo character varying(40) DEFAULT 'fixo'::character varying NOT NULL,
    contagem character varying(20) DEFAULT 'diaria'::character varying NOT NULL,
    carga_diaria_minima interval,
    carga_diaria_maxima interval,
    carga_semanal interval,
    janela_entrada_inicio interval,
    janela_entrada_fim interval,
    CONSTRAINT horarios_trabalho_contagem_check CHECK (((contagem)::text = ANY ((ARRAY['diaria'::character varying, 'semanal'::character varying, 'mensal'::character varying])::text[]))),
    CONSTRAINT horarios_trabalho_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['fixo'::character varying, 'flexivel'::character varying, 'turno'::character varying, 'rotativo'::character varying, 'escala'::character varying, 'remoto'::character varying, 'sem_horario'::character varying])::text[])))
);
ALTER TABLE rh.horarios_trabalho ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.horarios_trabalho_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.irps_escaloes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    ano_fiscal integer DEFAULT 2024 NOT NULL,
    limite_inf numeric(14,2) DEFAULT 0 NOT NULL,
    limite_sup numeric(14,2),
    taxa numeric(5,4) NOT NULL,
    parcela_ded numeric(14,2) DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL
);
ALTER TABLE rh.irps_escaloes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.irps_escaloes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.justificacoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo character varying(20) DEFAULT 'falta'::character varying NOT NULL,
    data date NOT NULL,
    motivo text NOT NULL,
    estado character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    ficheiro_url character varying(500),
    aprovado_por bigint,
    aprovado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT justificacoes_estado_check CHECK (((estado)::text = ANY (ARRAY[('pendente'::character varying)::text, ('aprovado'::character varying)::text, ('rejeitado'::character varying)::text]))),
    CONSTRAINT justificacoes_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('falta'::character varying)::text, ('atraso'::character varying)::text])))
);
CREATE SEQUENCE IF NOT EXISTS rh.justificacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.justificacoes_id_seq OWNED BY rh.justificacoes.id;
CREATE TABLE IF NOT EXISTS rh.metodos_marcacao (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    requer_dispositivo boolean DEFAULT false NOT NULL,
    requer_localizacao boolean DEFAULT false NOT NULL,
    requer_selfie boolean DEFAULT false NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE IF NOT EXISTS rh.metodos_marcacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.metodos_marcacao_id_seq OWNED BY rh.metodos_marcacao.id;
CREATE TABLE IF NOT EXISTS rh.periodos_avaliacao (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(60) NOT NULL,
    data_inicio date,
    data_fim date,
    estado character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT periodos_avaliacao_estado_check CHECK (((estado)::text = ANY (ARRAY[('aberto'::character varying)::text, ('encerrado'::character varying)::text])))
);
ALTER TABLE rh.periodos_avaliacao ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.periodos_avaliacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.presencas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    data date NOT NULL,
    hora_entrada character varying(5),
    hora_saida character varying(5),
    horas_extra numeric(5,2) DEFAULT 0 NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    latitude numeric(10,7),
    longitude numeric(10,7),
    observacao text,
    tipo character varying(20) DEFAULT 'presente'::character varying,
    CONSTRAINT presencas_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('presente'::character varying)::text, ('atraso'::character varying)::text, ('falta'::character varying)::text, ('saida_antecipada'::character varying)::text])))
);
ALTER TABLE rh.presencas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.presencas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.processos_disciplinares (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    motivo text NOT NULL,
    descricao text,
    data_ocorrencia date NOT NULL,
    data_abertura date DEFAULT CURRENT_DATE NOT NULL,
    estado character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    decisao text,
    data_decisao date,
    aberto_por bigint,
    decidido_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT processos_disciplinares_estado_check CHECK (((estado)::text = ANY (ARRAY[('aberto'::character varying)::text, ('em_analise'::character varying)::text, ('decidido'::character varying)::text, ('arquivado'::character varying)::text]))),
    CONSTRAINT processos_disciplinares_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('advertencia_verbal'::character varying)::text, ('advertencia_escrita'::character varying)::text, ('suspensao'::character varying)::text, ('despedimento'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE rh.processos_disciplinares ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.processos_disciplinares_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.recibo_vencimento_itens (
    id bigint NOT NULL,
    recibo_id bigint NOT NULL,
    componente_id bigint,
    nome character varying(100) NOT NULL,
    tipo character varying(20) NOT NULL,
    valor numeric(14,2) NOT NULL,
    CONSTRAINT recibo_vencimento_itens_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('provento'::character varying)::text, ('desconto'::character varying)::text])))
);
ALTER TABLE rh.recibo_vencimento_itens ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.recibo_vencimento_itens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.recibos_vencimento (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    folha_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    salario_base numeric(14,2) DEFAULT 0 NOT NULL,
    total_proventos numeric(14,2) DEFAULT 0 NOT NULL,
    total_descontos numeric(14,2) DEFAULT 0 NOT NULL,
    salario_liquido numeric(14,2) DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    centro_custo_id bigint,
    pdf_url text,
    CONSTRAINT recibos_vencimento_estado_check CHECK (((estado)::text = ANY (ARRAY[('pendente'::character varying)::text, ('pago'::character varying)::text])))
);
ALTER TABLE rh.recibos_vencimento ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.recibos_vencimento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.regras_assiduidade (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tipo_regra_id bigint NOT NULL,
    ambito character varying(20) NOT NULL,
    entidade_id bigint,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    valor jsonb DEFAULT '{}'::jsonb NOT NULL,
    prioridade smallint DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT regras_assiduidade_ambito_check CHECK (((ambito)::text = ANY ((ARRAY['empresa'::character varying, 'filial'::character varying, 'local'::character varying, 'departamento'::character varying, 'cargo'::character varying, 'equipa'::character varying, 'turno'::character varying, 'funcionario'::character varying, 'contrato'::character varying])::text[])))
);
CREATE SEQUENCE IF NOT EXISTS rh.regras_assiduidade_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.regras_assiduidade_id_seq OWNED BY rh.regras_assiduidade.id;
CREATE TABLE IF NOT EXISTS rh.resultados_diarios (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    data_referencia date NOT NULL,
    horario_id bigint,
    horas_trabalhadas interval,
    horas_normais interval,
    horas_extra interval,
    horas_nocturnas interval,
    horas_remoto interval,
    horas_missao interval,
    horas_formacao interval,
    horas_intervalo interval,
    horas_nao_contabilizadas interval,
    atraso_minutos integer DEFAULT 0 NOT NULL,
    saida_antecipada_minutos integer DEFAULT 0 NOT NULL,
    ausencia boolean DEFAULT false NOT NULL,
    falta_justificada boolean DEFAULT false NOT NULL,
    falta_injustificada boolean DEFAULT false NOT NULL,
    saldo_diario interval,
    saldo_semanal interval,
    saldo_mensal interval,
    banco_horas interval,
    versao_regra integer DEFAULT 1 NOT NULL,
    recalculado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE IF NOT EXISTS rh.resultados_diarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.resultados_diarios_id_seq OWNED BY rh.resultados_diarios.id;
CREATE TABLE IF NOT EXISTS rh.resultados_periodos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo_periodo character varying(20) NOT NULL,
    ano smallint NOT NULL,
    numero smallint NOT NULL,
    horas_normais interval,
    horas_extra interval,
    horas_nocturnas interval,
    horas_remoto interval,
    horas_missao interval,
    atrasos_minutos integer DEFAULT 0 NOT NULL,
    faltas integer DEFAULT 0 NOT NULL,
    saldo interval,
    recalculado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT resultados_periodos_tipo_periodo_check CHECK (((tipo_periodo)::text = ANY ((ARRAY['semana'::character varying, 'mes'::character varying])::text[])))
);
CREATE SEQUENCE IF NOT EXISTS rh.resultados_periodos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.resultados_periodos_id_seq OWNED BY rh.resultados_periodos.id;
CREATE TABLE IF NOT EXISTS rh.saldos_ausencia (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo_ausencia_id bigint NOT NULL,
    ano integer NOT NULL,
    dias_atribuidos numeric(5,2) DEFAULT 0 NOT NULL,
    dias_usados numeric(5,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.saldos_ausencia ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.saldos_ausencia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.tipos_ausencia (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(60) NOT NULL,
    dias_anuais numeric(5,2),
    remunerada boolean DEFAULT true NOT NULL,
    afeta_saldo boolean DEFAULT false NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE rh.tipos_ausencia ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.tipos_ausencia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS rh.tipos_evento (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    categoria character varying(40) DEFAULT 'marcacao'::character varying NOT NULL,
    sentido character varying(20),
    tipo_par character varying(50),
    afeta_calculo character varying(20) DEFAULT 'nenhum'::character varying,
    cor character varying(10),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT tipos_evento_afeta_calculo_check CHECK (((afeta_calculo)::text = ANY ((ARRAY['trabalho'::character varying, 'intervalo'::character varying, 'ausencia'::character varying, 'remoto'::character varying, 'extra'::character varying, 'missao'::character varying, 'formacao'::character varying, 'nenhum'::character varying])::text[]))),
    CONSTRAINT tipos_evento_categoria_check CHECK (((categoria)::text = ANY ((ARRAY['marcacao'::character varying, 'ausencia'::character varying, 'justificacao'::character varying, 'presenca'::character varying])::text[]))),
    CONSTRAINT tipos_evento_sentido_check CHECK (((sentido)::text = ANY ((ARRAY['inicio'::character varying, 'fim'::character varying, 'unico'::character varying])::text[])))
);
CREATE SEQUENCE IF NOT EXISTS rh.tipos_evento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.tipos_evento_id_seq OWNED BY rh.tipos_evento.id;
CREATE TABLE IF NOT EXISTS rh.tipos_regra (
    id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    parametros jsonb DEFAULT '{}'::jsonb NOT NULL,
    tipo_valor character varying(20) DEFAULT 'jsonb'::character varying NOT NULL,
    CONSTRAINT tipos_regra_tipo_valor_check CHECK (((tipo_valor)::text = ANY ((ARRAY['numero'::character varying, 'hora'::character varying, 'booleano'::character varying, 'jsonb'::character varying])::text[])))
);
CREATE SEQUENCE IF NOT EXISTS rh.tipos_regra_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE rh.tipos_regra_id_seq OWNED BY rh.tipos_regra.id;
CREATE TABLE IF NOT EXISTS saas.approval_decisions (
    id bigint NOT NULL,
    request_id bigint NOT NULL,
    nivel integer NOT NULL,
    decisao character varying(20) NOT NULL,
    aprovado_por bigint NOT NULL,
    comentario text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT approval_decisions_decisao_check CHECK (((decisao)::text = ANY (ARRAY[('aprovado'::character varying)::text, ('rejeitado'::character varying)::text])))
);
ALTER TABLE saas.approval_decisions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME saas.approval_decisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS saas.approval_flows (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    feature character varying(120) NOT NULL,
    nome character varying(150) NOT NULL,
    condicao jsonb DEFAULT '{}'::jsonb NOT NULL,
    niveis jsonb DEFAULT '[]'::jsonb NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE saas.approval_flows ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME saas.approval_flows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS saas.approval_requests (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    flow_id bigint NOT NULL,
    entidade character varying(60) NOT NULL,
    entidade_id bigint NOT NULL,
    nivel_atual integer DEFAULT 1 NOT NULL,
    estado character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    criado_por bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT approval_requests_estado_check CHECK (((estado)::text = ANY (ARRAY[('pendente'::character varying)::text, ('aprovado'::character varying)::text, ('rejeitado'::character varying)::text, ('cancelado'::character varying)::text])))
);
ALTER TABLE saas.approval_requests ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME saas.approval_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS saas.feature_catalog (
    key character varying(120) NOT NULL,
    modulo character varying(60) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    ativo_por_defeito boolean DEFAULT true NOT NULL,
    configuravel boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS saas.global_settings (
    chave character varying(100) NOT NULL,
    valor text,
    descricao text,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE IF NOT EXISTS saas.module_catalog (
    key character varying(60) NOT NULL,
    nome character varying(150) NOT NULL,
    categoria character varying(60) NOT NULL,
    descricao text,
    icone character varying(60),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS saas.module_dependencies (
    modulo character varying(60) NOT NULL,
    requires character varying(60) NOT NULL,
    CONSTRAINT module_dependencies_check CHECK (((modulo)::text <> (requires)::text))
);
CREATE TABLE IF NOT EXISTS saas.plan_modules (
    plan_id bigint NOT NULL,
    modulo character varying(60) NOT NULL
);
CREATE TABLE IF NOT EXISTS saas.plans (
    id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    preco_mensal numeric(18,2) DEFAULT 0 NOT NULL,
    preco_anual numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    limites jsonb DEFAULT '{}'::jsonb NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE saas.plans ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME saas.plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS saas.tenant_dominios (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    dominio character varying(255) NOT NULL,
    canonico boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_tenant_dominios_normalizado CHECK ((((dominio)::text = lower((dominio)::text)) AND ((dominio)::text !~~ 'www.%'::text) AND ((dominio)::text !~~ '%:%'::text)))
);
ALTER TABLE saas.tenant_dominios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME saas.tenant_dominios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS saas.tenant_modules (
    tenant_id bigint NOT NULL,
    modulo character varying(50) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE IF NOT EXISTS saas.tenant_subscriptions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    plano_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    starts_at date NOT NULL,
    ends_at date,
    next_billing_date date,
    status character varying(20) DEFAULT 'activa'::character varying NOT NULL,
    unit_price numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    auto_renew boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tenant_subscriptions_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('activa'::character varying)::text, ('suspensa'::character varying)::text, ('cancelada'::character varying)::text, ('expirada'::character varying)::text])))
);
ALTER TABLE saas.tenant_subscriptions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME saas.tenant_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
ALTER TABLE saas.tenants ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME saas.tenants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS seguranca.security_ip_allowlist (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    descricao character varying(150),
    ip_or_cidr character varying(80) NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE seguranca.security_ip_allowlist ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME seguranca.security_ip_allowlist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS seguranca.security_mfa_enrollments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    user_id bigint NOT NULL,
    metodo character varying(20) DEFAULT 'totp'::character varying NOT NULL,
    secret character varying(255) NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    last_verified_at timestamp with time zone,
    revoked_at timestamp with time zone,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT security_mfa_enrollments_metodo_check CHECK (((metodo)::text = ANY (ARRAY[('totp'::character varying)::text, ('sms'::character varying)::text, ('email'::character varying)::text])))
);
ALTER TABLE seguranca.security_mfa_enrollments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME seguranca.security_mfa_enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS seguranca.security_policies (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    configuracao jsonb NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE seguranca.security_policies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME seguranca.security_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.api_logs (
    id bigint NOT NULL,
    tenant_id bigint,
    metodo character varying(10) NOT NULL,
    rota character varying(255) NOT NULL,
    status_code integer,
    duracao_ms integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE sistema_configuracao.api_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.api_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.cities (
    id bigint NOT NULL,
    country_id bigint,
    nome character varying(100) NOT NULL
);
ALTER TABLE sistema_configuracao.cities ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.cities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.countries (
    id bigint NOT NULL,
    codigo character varying(10) NOT NULL,
    nome character varying(100) NOT NULL
);
ALTER TABLE sistema_configuracao.countries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.currencies (
    id bigint NOT NULL,
    codigo character varying(10) NOT NULL,
    nome character varying(80) NOT NULL,
    simbolo character varying(10),
    ativa boolean DEFAULT true NOT NULL
);
COMMENT ON TABLE sistema_configuracao.currencies IS 'Moedas de referência global da plataforma (MZN, USD). Para operações financeiras multi-tenant usar multi_moeda.currencies ou v_currencies.';
ALTER TABLE sistema_configuracao.currencies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.email_templates (
    id bigint NOT NULL,
    tenant_id bigint,
    codigo character varying(50) NOT NULL,
    assunto character varying(150) NOT NULL,
    corpo text NOT NULL
);
ALTER TABLE sistema_configuracao.email_templates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.email_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.exchange_rates (
    id bigint NOT NULL,
    from_currency_id bigint NOT NULL,
    to_currency_id bigint NOT NULL,
    rate numeric(18,6) NOT NULL,
    rate_date date NOT NULL
);
ALTER TABLE sistema_configuracao.exchange_rates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.exchange_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.integrations (
    id bigint NOT NULL,
    tenant_id bigint,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    configuracao jsonb,
    ativa boolean DEFAULT true NOT NULL
);
ALTER TABLE sistema_configuracao.integrations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.languages (
    id bigint NOT NULL,
    codigo character varying(10) NOT NULL,
    nome character varying(80) NOT NULL
);
ALTER TABLE sistema_configuracao.languages ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.settings (
    id bigint NOT NULL,
    tenant_id bigint,
    chave character varying(120) NOT NULL,
    valor text,
    escopo character varying(30) DEFAULT 'global'::character varying NOT NULL,
    CONSTRAINT settings_escopo_check CHECK (((escopo)::text = ANY (ARRAY[('global'::character varying)::text, ('tenant'::character varying)::text, ('user'::character varying)::text])))
);
ALTER TABLE sistema_configuracao.settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.sms_templates (
    id bigint NOT NULL,
    tenant_id bigint,
    codigo character varying(50) NOT NULL,
    corpo text NOT NULL
);
ALTER TABLE sistema_configuracao.sms_templates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.sms_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.system_logs (
    id bigint NOT NULL,
    tenant_id bigint,
    nivel character varying(20) NOT NULL,
    modulo character varying(80),
    mensagem text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE sistema_configuracao.system_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.system_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.tenant_branding (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    logo_url text,
    cor_primaria character varying(20),
    cor_secundaria character varying(20),
    slogan character varying(150),
    website_url text,
    suporte_email character varying(150),
    suporte_telefone character varying(30),
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE sistema_configuracao.tenant_branding ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_branding_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.tenant_defaults (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE sistema_configuracao.tenant_defaults ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_defaults_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.tenant_document_settings (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    modulo character varying(50) NOT NULL,
    tipo_documento character varying(50) NOT NULL,
    prefixo character varying(20),
    reinicia_anualmente boolean DEFAULT true NOT NULL,
    serie_activa character varying(20),
    layout_template character varying(100),
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE sistema_configuracao.tenant_document_settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_document_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.tenant_feature_flags (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(100) NOT NULL,
    activo boolean DEFAULT false NOT NULL,
    configuracao jsonb,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modulo character varying(60)
);
ALTER TABLE sistema_configuracao.tenant_feature_flags ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_feature_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS sistema_configuracao.tenant_integrations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(100) NOT NULL,
    activo boolean DEFAULT false NOT NULL,
    endpoint_url text,
    credenciais jsonb,
    configuracao jsonb,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE sistema_configuracao.tenant_integrations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE OR REPLACE VIEW sistema_configuracao.v_currencies AS
 SELECT mc.id,
    mc.code AS codigo,
    mc.name AS nome,
    mc.symbol AS simbolo,
    mc.decimals,
    mc.active AS ativa,
        CASE
            WHEN (sc.id IS NOT NULL) THEN true
            ELSE false
        END AS is_sistema_config
   FROM (multi_moeda.currencies mc
     LEFT JOIN sistema_configuracao.currencies sc ON (((sc.codigo)::text = (mc.code)::text)));
COMMENT ON VIEW sistema_configuracao.v_currencies IS 'Vista unificada de moedas. Fonte canónica: multi_moeda.currencies. is_sistema_config=true indica moedas também presentes na configuração global de plataforma.';
CREATE TABLE IF NOT EXISTS stock.stock_adjustments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    adjustment_type character varying(20) NOT NULL,
    quantity numeric(18,2) NOT NULL,
    reason text,
    adjusted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_adjustments_adjustment_type_check CHECK (((adjustment_type)::text = ANY (ARRAY[('positivo'::character varying)::text, ('negativo'::character varying)::text])))
);
ALTER TABLE stock.stock_adjustments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_adjustments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_alerts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    alert_type character varying(30) NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    mensagem text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_alerts_alert_type_check CHECK (((alert_type)::text = ANY (ARRAY[('stock_minimo'::character varying)::text, ('stock_maximo'::character varying)::text, ('lote_expirar'::character varying)::text]))),
    CONSTRAINT stock_alerts_status_check CHECK (((status)::text = ANY (ARRAY[('aberto'::character varying)::text, ('resolvido'::character varying)::text, ('ignorado'::character varying)::text])))
);
ALTER TABLE stock.stock_alerts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_batches (
    id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    batch_number character varying(80) NOT NULL,
    manufacture_date date,
    expiry_date date,
    quantity numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE stock.stock_batches ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_count_items (
    id bigint NOT NULL,
    stock_count_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    system_quantity numeric(18,2) NOT NULL,
    counted_quantity numeric(18,2) NOT NULL,
    difference_quantity numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE stock.stock_count_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_count_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_counts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    warehouse_id bigint NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    count_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    CONSTRAINT stock_counts_status_check CHECK (((status)::text = ANY (ARRAY[('aberto'::character varying)::text, ('fechado'::character varying)::text, ('cancelado'::character varying)::text])))
);
ALTER TABLE stock.stock_counts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_items (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    warehouse_id bigint NOT NULL,
    quantity numeric(18,2) DEFAULT 0 NOT NULL,
    reserved_quantity numeric(18,2) DEFAULT 0 NOT NULL,
    available_quantity numeric(18,2) GENERATED ALWAYS AS ((quantity - reserved_quantity)) STORED,
    minimum_quantity numeric(18,2) DEFAULT 0 NOT NULL,
    maximum_quantity numeric(18,2),
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE stock.stock_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_logs (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint,
    acao character varying(100) NOT NULL,
    detalhe text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE stock.stock_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_movements (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    quantity numeric(18,2) NOT NULL,
    reference_type character varying(50),
    reference_id bigint,
    movement_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_movements_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('entrada'::character varying)::text, ('saida'::character varying)::text, ('transferencia_entrada'::character varying)::text, ('transferencia_saida'::character varying)::text, ('ajuste'::character varying)::text, ('reserva'::character varying)::text, ('liberacao'::character varying)::text])))
);
ALTER TABLE stock.stock_movements ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_reservations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    quantity numeric(18,2) NOT NULL,
    reference_type character varying(50),
    reference_id bigint,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    reserved_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_reservations_status_check CHECK (((status)::text = ANY (ARRAY[('ativa'::character varying)::text, ('consumida'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE stock.stock_reservations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_reservations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_serial_numbers (
    id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    serial_number character varying(120) NOT NULL,
    status character varying(20) DEFAULT 'disponivel'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_serial_numbers_status_check CHECK (((status)::text = ANY (ARRAY[('disponivel'::character varying)::text, ('reservado'::character varying)::text, ('vendido'::character varying)::text, ('devolvido'::character varying)::text])))
);
ALTER TABLE stock.stock_serial_numbers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_serial_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_transfer_items (
    id bigint NOT NULL,
    stock_transfer_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    quantity numeric(18,2) NOT NULL,
    CONSTRAINT stock_transfer_items_quantity_check CHECK ((quantity > (0)::numeric))
);
ALTER TABLE stock.stock_transfer_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_transfer_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.stock_transfers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    from_warehouse_id bigint NOT NULL,
    to_warehouse_id bigint NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    transfer_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    confirmed_at timestamp with time zone,
    received_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    CONSTRAINT stock_transfers_status_check CHECK (((status)::text = ANY (ARRAY[('pendente'::character varying)::text, ('em_transito'::character varying)::text, ('concluida'::character varying)::text, ('cancelada'::character varying)::text])))
);
ALTER TABLE stock.stock_transfers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_transfers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS stock.warehouse_locations (
    id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(30),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE stock.warehouse_locations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.warehouse_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS tarefas.cartoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    lista_id bigint NOT NULL,
    titulo character varying(255) NOT NULL,
    descricao text,
    posicao integer DEFAULT 0 NOT NULL,
    data_inicio date,
    data_fim date,
    prioridade character varying(20) DEFAULT 'media'::character varying NOT NULL,
    responsaveis integer[] DEFAULT '{}'::integer[] NOT NULL,
    concluido boolean DEFAULT false NOT NULL,
    arquivado boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cartoes_prioridade_check CHECK (((prioridade)::text = ANY (ARRAY[('baixa'::character varying)::text, ('media'::character varying)::text, ('alta'::character varying)::text, ('urgente'::character varying)::text])))
);
ALTER TABLE tarefas.cartoes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tarefas.cartoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS tarefas.listas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    quadro_id bigint NOT NULL,
    titulo character varying(200) NOT NULL,
    posicao integer DEFAULT 0 NOT NULL,
    arquivada boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE tarefas.listas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tarefas.listas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS tarefas.quadros (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(200) NOT NULL,
    descricao text,
    cor character varying(7) DEFAULT '#F59E0B'::character varying NOT NULL,
    arquivado boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE tarefas.quadros ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tarefas.quadros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS tesouraria.bank_accounts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(80) NOT NULL,
    iban character varying(80),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    saldo_inicial numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_actual numeric(18,2) DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE tesouraria.bank_accounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.bank_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS tesouraria.cash_registers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    nome character varying(120) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    saldo_inicial numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_actual numeric(18,2) DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE tesouraria.cash_registers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.cash_registers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS tesouraria.movements (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    bank_account_id bigint,
    cash_register_id bigint,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    data_movimento date DEFAULT CURRENT_DATE NOT NULL,
    metodo character varying(40),
    referencia character varying(100),
    descricao text,
    reference_type character varying(60),
    reference_id bigint,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT movements_check CHECK (((((bank_account_id IS NOT NULL))::integer + ((cash_register_id IS NOT NULL))::integer) = 1)),
    CONSTRAINT movements_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('recebimento'::character varying)::text, ('pagamento'::character varying)::text]))),
    CONSTRAINT movements_valor_check CHECK ((valor > (0)::numeric))
);
ALTER TABLE tesouraria.movements ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS tesouraria.reconciliations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    bank_account_id bigint NOT NULL,
    periodo_inicio date NOT NULL,
    periodo_fim date NOT NULL,
    saldo_extracto numeric(18,2) NOT NULL,
    saldo_sistema numeric(18,2) DEFAULT 0 NOT NULL,
    diferenca numeric(18,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    observacoes text,
    criada_por bigint,
    fechada_por bigint,
    fechada_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reconciliations_check CHECK ((periodo_fim >= periodo_inicio)),
    CONSTRAINT reconciliations_status_check CHECK (((status)::text = ANY (ARRAY[('aberta'::character varying)::text, ('fechada'::character varying)::text])))
);
ALTER TABLE tesouraria.reconciliations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.reconciliations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS utilizadores.profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    primeiro_nome character varying(100),
    ultimo_nome character varying(100),
    nome_exibicao character varying(150),
    data_nascimento date,
    genero character varying(20),
    idioma character varying(20) DEFAULT 'pt'::character varying,
    timezone character varying(60) DEFAULT 'Africa/Maputo'::character varying,
    bio text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE utilizadores.profiles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS utilizadores.user_activity (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    modulo character varying(100),
    acao character varying(120) NOT NULL,
    descricao text,
    ip_address character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE utilizadores.user_activity ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS utilizadores.user_avatar (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    ficheiro_url text NOT NULL,
    mime_type character varying(100),
    tamanho_bytes bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE utilizadores.user_avatar ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_avatar_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS utilizadores.user_devices (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    device_id character varying(120) NOT NULL,
    nome character varying(120),
    plataforma character varying(50),
    user_agent text,
    ultimo_acesso_em timestamp with time zone,
    confiavel boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE utilizadores.user_devices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS utilizadores.user_notifications (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    tipo character varying(50) NOT NULL,
    titulo character varying(150) NOT NULL,
    mensagem text NOT NULL,
    lida boolean DEFAULT false NOT NULL,
    lida_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE utilizadores.user_notifications ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS utilizadores.user_preferences (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE utilizadores.user_preferences ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS utilizadores.user_security_logs (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    evento character varying(100) NOT NULL,
    severidade character varying(20) DEFAULT 'info'::character varying NOT NULL,
    detalhe text,
    ip_address character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT user_security_logs_severidade_check CHECK (((severidade)::text = ANY (ARRAY[('info'::character varying)::text, ('warning'::character varying)::text, ('critical'::character varying)::text])))
);
ALTER TABLE utilizadores.user_security_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_security_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS utilizadores.user_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE utilizadores.user_settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE IF NOT EXISTS utilizadores.user_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    token_hash text NOT NULL,
    expira_em timestamp with time zone,
    revogado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT user_tokens_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('refresh'::character varying)::text, ('email_verify'::character varying)::text, ('mfa'::character varying)::text, ('integration'::character varying)::text])))
);
ALTER TABLE utilizadores.user_tokens ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
ALTER TABLE ONLY assinatura_digital.documentos ALTER COLUMN id SET DEFAULT nextval('assinatura_digital.documentos_id_seq'::regclass);
ALTER TABLE ONLY assinatura_digital.logs ALTER COLUMN id SET DEFAULT nextval('assinatura_digital.logs_id_seq'::regclass);
ALTER TABLE ONLY assinatura_digital.signatarios ALTER COLUMN id SET DEFAULT nextval('assinatura_digital.signatarios_id_seq'::regclass);
ALTER TABLE ONLY assinatura_digital.versoes_assinadas ALTER COLUMN id SET DEFAULT nextval('assinatura_digital.versoes_assinadas_id_seq'::regclass);
ALTER TABLE ONLY auth.audit_logs ALTER COLUMN id SET DEFAULT nextval('auth.audit_logs_id_seq'::regclass);
ALTER TABLE ONLY auth.permissoes_tipo ALTER COLUMN id SET DEFAULT nextval('auth.permissoes_tipo_id_seq'::regclass);
ALTER TABLE ONLY auth.superadmin_ip_allowlist ALTER COLUMN id SET DEFAULT nextval('auth.superadmin_ip_allowlist_id_seq'::regclass);
ALTER TABLE ONLY gestao_escolar.guardian_portal_sessions ALTER COLUMN id SET DEFAULT nextval('gestao_escolar.guardian_portal_sessions_id_seq'::regclass);
ALTER TABLE ONLY gestao_escolar.portal_sessions ALTER COLUMN id SET DEFAULT nextval('gestao_escolar.portal_sessions_id_seq'::regclass);
ALTER TABLE ONLY public.chat_conversas ALTER COLUMN id SET DEFAULT nextval('public.chat_conversas_id_seq'::regclass);
ALTER TABLE ONLY public.chat_mensagens ALTER COLUMN id SET DEFAULT nextval('public.chat_mensagens_id_seq'::regclass);
ALTER TABLE ONLY public.comunicados ALTER COLUMN id SET DEFAULT nextval('public.comunicados_id_seq'::regclass);
ALTER TABLE ONLY public.notif_colaborador ALTER COLUMN id SET DEFAULT nextval('public.notif_colaborador_id_seq'::regclass);
ALTER TABLE ONLY recrutamento.candidato_sessions ALTER COLUMN id SET DEFAULT nextval('recrutamento.candidato_sessions_id_seq'::regclass);
ALTER TABLE ONLY rh.auditoria_assiduidade ALTER COLUMN id SET DEFAULT nextval('rh.auditoria_assiduidade_id_seq'::regclass);
ALTER TABLE ONLY rh.correcoes_evento ALTER COLUMN id SET DEFAULT nextval('rh.correcoes_evento_id_seq'::regclass);
ALTER TABLE ONLY rh.eventos_assiduidade ALTER COLUMN id SET DEFAULT nextval('rh.eventos_assiduidade_id_seq'::regclass);
ALTER TABLE ONLY rh.funcionario_horarios ALTER COLUMN id SET DEFAULT nextval('rh.funcionario_horarios_id_seq'::regclass);
ALTER TABLE ONLY rh.horarios_dias ALTER COLUMN id SET DEFAULT nextval('rh.horarios_dias_id_seq'::regclass);
ALTER TABLE ONLY rh.justificacoes ALTER COLUMN id SET DEFAULT nextval('rh.justificacoes_id_seq'::regclass);
ALTER TABLE ONLY rh.metodos_marcacao ALTER COLUMN id SET DEFAULT nextval('rh.metodos_marcacao_id_seq'::regclass);
ALTER TABLE ONLY rh.regras_assiduidade ALTER COLUMN id SET DEFAULT nextval('rh.regras_assiduidade_id_seq'::regclass);
ALTER TABLE ONLY rh.resultados_diarios ALTER COLUMN id SET DEFAULT nextval('rh.resultados_diarios_id_seq'::regclass);
ALTER TABLE ONLY rh.resultados_periodos ALTER COLUMN id SET DEFAULT nextval('rh.resultados_periodos_id_seq'::regclass);
ALTER TABLE ONLY rh.tipos_evento ALTER COLUMN id SET DEFAULT nextval('rh.tipos_evento_id_seq'::regclass);
ALTER TABLE ONLY rh.tipos_regra ALTER COLUMN id SET DEFAULT nextval('rh.tipos_regra_id_seq'::regclass);
ALTER TABLE ONLY assinatura_digital.documentos
    ADD CONSTRAINT documentos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY assinatura_digital.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY assinatura_digital.signatarios
    ADD CONSTRAINT signatarios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY assinatura_digital.versoes_assinadas
    ADD CONSTRAINT versoes_assinadas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY assinaturas.subscription_invoices
    ADD CONSTRAINT subscription_invoices_pkey PRIMARY KEY (id);
ALTER TABLE ONLY assinaturas.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);
ALTER TABLE ONLY assinaturas.subscription_usage
    ADD CONSTRAINT subscription_usage_pkey PRIMARY KEY (id);
ALTER TABLE ONLY assinaturas.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY assinaturas.subscription_invoices
    ADD CONSTRAINT uq_subscription_invoices UNIQUE (tenant_id, numero);
ALTER TABLE ONLY assinaturas.subscription_plans
    ADD CONSTRAINT uq_subscription_plans UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY assinaturas.subscriptions
    ADD CONSTRAINT uq_subscriptions UNIQUE (tenant_id, numero);
ALTER TABLE ONLY auditoria.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auditoria.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.api_keys
    ADD CONSTRAINT api_keys_key_hash_key UNIQUE (key_hash);
ALTER TABLE ONLY auth.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.cargos
    ADD CONSTRAINT cargos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.cargos
    ADD CONSTRAINT cargos_tenant_id_nome_key UNIQUE (tenant_id, nome);
ALTER TABLE ONLY auth.email_verifications
    ADD CONSTRAINT email_verifications_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.email_verifications
    ADD CONSTRAINT email_verifications_token_hash_key UNIQUE (token_hash);
ALTER TABLE ONLY auth.login_history
    ADD CONSTRAINT login_history_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.password_resets
    ADD CONSTRAINT password_resets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.password_resets
    ADD CONSTRAINT password_resets_token_hash_key UNIQUE (token_hash);
ALTER TABLE ONLY auth.permissoes_cargo
    ADD CONSTRAINT permissoes_cargo_cargo_id_modulo_acao_key UNIQUE (cargo_id, modulo, acao);
ALTER TABLE ONLY auth.permissoes_cargo
    ADD CONSTRAINT permissoes_cargo_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.permissoes_diretas
    ADD CONSTRAINT permissoes_diretas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.permissoes_tipo
    ADD CONSTRAINT permissoes_tipo_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_token_hash_key UNIQUE (token_hash);
ALTER TABLE ONLY auth.superadmin_ip_allowlist
    ADD CONSTRAINT superadmin_ip_allowlist_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth.superadmin_security_settings
    ADD CONSTRAINT superadmin_security_settings_pkey PRIMARY KEY (chave);
ALTER TABLE ONLY auth.memberships
    ADD CONSTRAINT uq_memberships_user_tenant_escopo_papel UNIQUE (user_id, tenant_id, escopo, papel);
ALTER TABLE ONLY auth.permissoes_diretas
    ADD CONSTRAINT uq_permissoes_diretas_user_tenant_modulo_acao UNIQUE (user_id, tenant_id, modulo, acao);
ALTER TABLE ONLY auth.permissoes_tipo
    ADD CONSTRAINT uq_permissoes_tipo UNIQUE (tipo, modulo, acao);
ALTER TABLE ONLY auth.superadmin_ip_allowlist
    ADD CONSTRAINT uq_superadmin_ip_allowlist UNIQUE (ip_cidr);
ALTER TABLE ONLY auth.users
    ADD CONSTRAINT uq_users_email UNIQUE (email);
ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY autorizacao.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY autorizacao.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY autorizacao.permissions
    ADD CONSTRAINT uq_permissions_codigo UNIQUE (codigo);
ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT uq_role_permissions UNIQUE (role_id, permission_id);
ALTER TABLE ONLY autorizacao.roles
    ADD CONSTRAINT uq_roles_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT uq_user_roles UNIQUE (user_id, role_id);
ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY centros_custo.cost_center_allocations
    ADD CONSTRAINT cost_center_allocations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY centros_custo.cost_center_budgets
    ADD CONSTRAINT cost_center_budgets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY centros_custo.cost_centers
    ADD CONSTRAINT cost_centers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY centros_custo.cost_center_budgets
    ADD CONSTRAINT uq_cost_center_budgets UNIQUE (tenant_id, cost_center_id, ano, mes);
ALTER TABLE ONLY centros_custo.cost_centers
    ADD CONSTRAINT uq_cost_centers UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY clientes.customer_addresses
    ADD CONSTRAINT customer_addresses_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_balances
    ADD CONSTRAINT customer_balances_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_contacts
    ADD CONSTRAINT customer_contacts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_credit_limits
    ADD CONSTRAINT customer_credit_limits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_discounts
    ADD CONSTRAINT customer_discounts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_documents
    ADD CONSTRAINT customer_documents_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_groups
    ADD CONSTRAINT customer_groups_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_history
    ADD CONSTRAINT customer_history_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_notes
    ADD CONSTRAINT customer_notes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_payments
    ADD CONSTRAINT customer_payments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_tag_links
    ADD CONSTRAINT customer_tag_links_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_tags
    ADD CONSTRAINT customer_tags_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clientes.customer_balances
    ADD CONSTRAINT uq_customer_balances_customer UNIQUE (customer_id);
ALTER TABLE ONLY clientes.customer_credit_limits
    ADD CONSTRAINT uq_customer_credit_limits_customer UNIQUE (customer_id);
ALTER TABLE ONLY clientes.customer_groups
    ADD CONSTRAINT uq_customer_groups UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY clientes.customer_tag_links
    ADD CONSTRAINT uq_customer_tag_links UNIQUE (customer_id, customer_tag_id);
ALTER TABLE ONLY clientes.customer_tags
    ADD CONSTRAINT uq_customer_tags UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY clientes.customers
    ADD CONSTRAINT uq_customers_tenant_codigo UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);
ALTER TABLE ONLY clientes.customers
    ADD CONSTRAINT uq_customers_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit);
ALTER TABLE ONLY compras.goods_receipt_items
    ADD CONSTRAINT goods_receipt_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.goods_receipts
    ADD CONSTRAINT goods_receipts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_invoice_items
    ADD CONSTRAINT purchase_invoice_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_tenant_id_numero_key UNIQUE (tenant_id, numero);
ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_tenant_id_supplier_id_supplier_invoice_nu_key UNIQUE NULLS NOT DISTINCT (tenant_id, supplier_id, supplier_invoice_number);
ALTER TABLE ONLY compras.purchase_order_items
    ADD CONSTRAINT purchase_order_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_payment_items
    ADD CONSTRAINT purchase_payment_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_payment_items
    ADD CONSTRAINT purchase_payment_items_purchase_payment_id_purchase_invoice_key UNIQUE (purchase_payment_id, purchase_invoice_id);
ALTER TABLE ONLY compras.purchase_payments
    ADD CONSTRAINT purchase_payments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_payments
    ADD CONSTRAINT purchase_payments_tenant_id_numero_key UNIQUE (tenant_id, numero);
ALTER TABLE ONLY compras.purchase_request_items
    ADD CONSTRAINT purchase_request_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_requests
    ADD CONSTRAINT purchase_requests_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_requests
    ADD CONSTRAINT purchase_requests_tenant_id_numero_key UNIQUE (tenant_id, numero);
ALTER TABLE ONLY compras.purchase_return_items
    ADD CONSTRAINT purchase_return_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.purchase_returns
    ADD CONSTRAINT purchase_returns_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.supplier_addresses
    ADD CONSTRAINT supplier_addresses_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.supplier_contacts
    ADD CONSTRAINT supplier_contacts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.supplier_groups
    ADD CONSTRAINT supplier_groups_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY compras.goods_receipts
    ADD CONSTRAINT uq_goods_receipts UNIQUE (tenant_id, numero);
ALTER TABLE ONLY compras.purchase_orders
    ADD CONSTRAINT uq_purchase_orders UNIQUE (tenant_id, numero);
ALTER TABLE ONLY compras.purchase_returns
    ADD CONSTRAINT uq_purchase_returns UNIQUE (tenant_id, numero);
ALTER TABLE ONLY compras.supplier_groups
    ADD CONSTRAINT uq_supplier_groups UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY compras.suppliers
    ADD CONSTRAINT uq_suppliers_tenant_codigo UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);
ALTER TABLE ONLY compras.suppliers
    ADD CONSTRAINT uq_suppliers_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit);
ALTER TABLE ONLY contabilidade.account_types
    ADD CONSTRAINT account_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.accounting_budgets
    ADD CONSTRAINT accounting_budgets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.accounting_journals
    ADD CONSTRAINT accounting_journals_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.fiscal_periods
    ADD CONSTRAINT accounting_periods_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.accounting_reports
    ADD CONSTRAINT accounting_reports_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.chart_of_accounts
    ADD CONSTRAINT chart_of_accounts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT depreciation_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.fiscal_years
    ADD CONSTRAINT fiscal_years_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT fixed_assets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.journal_entries
    ADD CONSTRAINT journal_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.journal_entry_lines
    ADD CONSTRAINT journal_entry_lines_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.journal_entry_sequences
    ADD CONSTRAINT journal_entry_sequences_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.period_closing_checks
    ADD CONSTRAINT period_closing_checks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.period_closings
    ADD CONSTRAINT period_closings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contabilidade.account_types
    ADD CONSTRAINT uq_account_types UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY contabilidade.accounting_budgets
    ADD CONSTRAINT uq_accounting_budgets_conta_ano_mes UNIQUE (tenant_id, chart_account_id, fiscal_year_id, mes);
ALTER TABLE ONLY contabilidade.accounting_journals
    ADD CONSTRAINT uq_accounting_journals UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY contabilidade.fiscal_periods
    ADD CONSTRAINT uq_accounting_periods UNIQUE (tenant_id, ano, mes);
ALTER TABLE ONLY contabilidade.chart_of_accounts
    ADD CONSTRAINT uq_chart_of_accounts UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT uq_depreciation_entries_asset_period UNIQUE (fixed_asset_id, fiscal_period_id);
ALTER TABLE ONLY contabilidade.fiscal_years
    ADD CONSTRAINT uq_fiscal_years UNIQUE (tenant_id, ano);
ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT uq_fixed_assets_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY contabilidade.journal_entries
    ADD CONSTRAINT uq_journal_entries UNIQUE (tenant_id, numero);
ALTER TABLE ONLY contabilidade.journal_entry_sequences
    ADD CONSTRAINT uq_journal_entry_sequences UNIQUE (tenant_id, accounting_journal_id, ano);
ALTER TABLE ONLY crm.atividades
    ADD CONSTRAINT atividades_pkey PRIMARY KEY (id);
ALTER TABLE ONLY crm.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);
ALTER TABLE ONLY crm.oportunidades
    ADD CONSTRAINT oportunidades_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.company_addresses
    ADD CONSTRAINT company_addresses_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.company_banks
    ADD CONSTRAINT company_banks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.company_branches
    ADD CONSTRAINT company_branches_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.company_contacts
    ADD CONSTRAINT company_contacts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.company_documents
    ADD CONSTRAINT company_documents_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.company_licenses
    ADD CONSTRAINT company_licenses_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.company_settings
    ADD CONSTRAINT company_settings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.company_tax_info
    ADD CONSTRAINT company_tax_info_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.company_users
    ADD CONSTRAINT company_users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY empresas.companies
    ADD CONSTRAINT uq_companies_codigo UNIQUE (codigo);
ALTER TABLE ONLY empresas.company_branches
    ADD CONSTRAINT uq_company_branches UNIQUE (company_id, codigo);
ALTER TABLE ONLY empresas.company_settings
    ADD CONSTRAINT uq_company_settings UNIQUE (company_id, chave);
ALTER TABLE ONLY empresas.company_tax_info
    ADD CONSTRAINT uq_company_tax_info_company UNIQUE (company_id);
ALTER TABLE ONLY empresas.company_tax_info
    ADD CONSTRAINT uq_company_tax_info_nuit UNIQUE (nuit);
ALTER TABLE ONLY empresas.company_users
    ADD CONSTRAINT uq_company_users UNIQUE (company_id, user_id);
ALTER TABLE ONLY faturacao.credit_note_items
    ADD CONSTRAINT credit_note_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.credit_notes
    ADD CONSTRAINT credit_notes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.invoice_discounts
    ADD CONSTRAINT invoice_discounts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.invoice_items
    ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.invoice_receipts
    ADD CONSTRAINT invoice_receipts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.invoice_series
    ADD CONSTRAINT invoice_series_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.invoice_taxes
    ADD CONSTRAINT invoice_taxes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.sales_deliveries
    ADD CONSTRAINT sales_deliveries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.sales_delivery_items
    ADD CONSTRAINT sales_delivery_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.sales_order_items
    ADD CONSTRAINT sales_order_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.sales_orders
    ADD CONSTRAINT sales_orders_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.sales_quote_items
    ADD CONSTRAINT sales_quote_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.sales_quotes
    ADD CONSTRAINT sales_quotes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.sales_return_items
    ADD CONSTRAINT sales_return_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.sales_returns
    ADD CONSTRAINT sales_returns_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faturacao.credit_notes
    ADD CONSTRAINT uq_credit_notes UNIQUE (tenant_id, numero);
ALTER TABLE ONLY faturacao.invoice_receipts
    ADD CONSTRAINT uq_invoice_receipts UNIQUE (tenant_id, numero);
ALTER TABLE ONLY faturacao.invoice_series
    ADD CONSTRAINT uq_invoice_series UNIQUE (tenant_id, tipo, ano);
ALTER TABLE ONLY faturacao.invoices
    ADD CONSTRAINT uq_invoices UNIQUE (tenant_id, numero);
ALTER TABLE ONLY faturacao.sales_deliveries
    ADD CONSTRAINT uq_sales_deliveries UNIQUE (tenant_id, numero);
ALTER TABLE ONLY faturacao.sales_orders
    ADD CONSTRAINT uq_sales_orders UNIQUE (tenant_id, numero);
ALTER TABLE ONLY faturacao.sales_quotes
    ADD CONSTRAINT uq_sales_quotes UNIQUE (tenant_id, numero);
ALTER TABLE ONLY faturacao.sales_returns
    ADD CONSTRAINT uq_sales_returns UNIQUE (tenant_id, numero);
ALTER TABLE ONLY financeiro.accounts_payable_payments
    ADD CONSTRAINT accounts_payable_payments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY financeiro.accounts_payable
    ADD CONSTRAINT accounts_payable_pkey PRIMARY KEY (id);
ALTER TABLE ONLY financeiro.accounts_receivable_payments
    ADD CONSTRAINT accounts_receivable_payments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY financeiro.accounts_receivable
    ADD CONSTRAINT accounts_receivable_pkey PRIMARY KEY (id);
ALTER TABLE ONLY financeiro.cash_flow_entries
    ADD CONSTRAINT cash_flow_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY financeiro.financial_budgets
    ADD CONSTRAINT financial_budgets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY financeiro.financial_categories
    ADD CONSTRAINT financial_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY financeiro.payment_methods
    ADD CONSTRAINT payment_methods_pkey PRIMARY KEY (id);
ALTER TABLE ONLY financeiro.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY financeiro.accounts_payable
    ADD CONSTRAINT uq_accounts_payable UNIQUE (tenant_id, numero);
ALTER TABLE ONLY financeiro.accounts_receivable
    ADD CONSTRAINT uq_accounts_receivable UNIQUE (tenant_id, numero);
ALTER TABLE ONLY financeiro.accounts_payable_payments
    ADD CONSTRAINT uq_ap_payments UNIQUE (accounts_payable_id, payment_id);
ALTER TABLE ONLY financeiro.accounts_receivable_payments
    ADD CONSTRAINT uq_ar_payments UNIQUE (accounts_receivable_id, payment_id);
ALTER TABLE ONLY financeiro.financial_budgets
    ADD CONSTRAINT uq_financial_budgets UNIQUE (tenant_id, financial_category_id, ano, mes);
ALTER TABLE ONLY financeiro.payment_methods
    ADD CONSTRAINT uq_payment_methods UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY financeiro.payments
    ADD CONSTRAINT uq_payments UNIQUE (tenant_id, numero);
ALTER TABLE ONLY gestao_escolar.guardian_portal_sessions
    ADD CONSTRAINT guardian_portal_sessions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.guardian_portal_sessions
    ADD CONSTRAINT guardian_portal_sessions_token_hash_key UNIQUE (token_hash);
ALTER TABLE ONLY gestao_escolar.portal_sessions
    ADD CONSTRAINT portal_sessions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.portal_sessions
    ADD CONSTRAINT portal_sessions_token_hash_key UNIQUE (token_hash);
ALTER TABLE ONLY gestao_escolar.school_academic_config
    ADD CONSTRAINT school_academic_config_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_academic_config
    ADD CONSTRAINT school_academic_config_tenant_id_key UNIQUE (tenant_id);
ALTER TABLE ONLY gestao_escolar.school_academic_transcripts
    ADD CONSTRAINT school_academic_transcripts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_academic_transcripts
    ADD CONSTRAINT school_academic_transcripts_tenant_id_student_id_school_yea_key UNIQUE (tenant_id, student_id, school_year_id);
ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT school_attendance_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_books
    ADD CONSTRAINT school_books_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_books
    ADD CONSTRAINT school_books_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_calendar_event_types
    ADD CONSTRAINT school_calendar_event_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_calendar_event_types
    ADD CONSTRAINT school_calendar_event_types_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_calendar_events
    ADD CONSTRAINT school_calendar_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_cargo_permissoes
    ADD CONSTRAINT school_cargo_permissoes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_cargo_permissoes
    ADD CONSTRAINT school_cargo_permissoes_tenant_id_class_id_cargo_permissao_key UNIQUE (tenant_id, class_id, cargo, permissao);
ALTER TABLE ONLY gestao_escolar.school_classes
    ADD CONSTRAINT school_classes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_course_subject_terms
    ADD CONSTRAINT school_course_subject_terms_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_course_subject_terms
    ADD CONSTRAINT school_course_subject_terms_tenant_id_course_subject_id_ter_key UNIQUE (tenant_id, course_subject_id, term_id);
ALTER TABLE ONLY gestao_escolar.school_course_subjects
    ADD CONSTRAINT school_course_subjects_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_course_subjects
    ADD CONSTRAINT school_course_subjects_tenant_id_course_id_series_id_subjec_key UNIQUE (tenant_id, course_id, series_id, subject_id);
ALTER TABLE ONLY gestao_escolar.school_courses
    ADD CONSTRAINT school_courses_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_courses
    ADD CONSTRAINT school_courses_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_cycles
    ADD CONSTRAINT school_cycles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_cycles
    ADD CONSTRAINT school_cycles_tenant_id_level_id_codigo_key UNIQUE (tenant_id, level_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT school_enrollments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_evaluation_types
    ADD CONSTRAINT school_evaluation_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_evaluation_types
    ADD CONSTRAINT school_evaluation_types_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_fee_generations
    ADD CONSTRAINT school_fee_generations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_fee_generations
    ADD CONSTRAINT school_fee_generations_tenant_id_fee_plan_id_periodo_refere_key UNIQUE (tenant_id, fee_plan_id, periodo_referencia);
ALTER TABLE ONLY gestao_escolar.school_fee_plans
    ADD CONSTRAINT school_fee_plans_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_fee_plans
    ADD CONSTRAINT school_fee_plans_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT school_fees_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_financial_config
    ADD CONSTRAINT school_financial_config_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_financial_config
    ADD CONSTRAINT school_financial_config_tenant_id_key UNIQUE (tenant_id);
ALTER TABLE ONLY gestao_escolar.school_grade_formulas
    ADD CONSTRAINT school_grade_formulas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_grade_formulas
    ADD CONSTRAINT school_grade_formulas_tenant_id_level_id_course_id_tipo_per_key UNIQUE (tenant_id, level_id, course_id, tipo_periodo);
ALTER TABLE ONLY gestao_escolar.school_grade_items
    ADD CONSTRAINT school_grade_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_tenant_id_grade_item_id_student_id_key UNIQUE (tenant_id, grade_item_id, student_id);
ALTER TABLE ONLY gestao_escolar.school_guardians
    ADD CONSTRAINT school_guardians_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_incident_types
    ADD CONSTRAINT school_incident_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_incident_types
    ADD CONSTRAINT school_incident_types_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_levels
    ADD CONSTRAINT school_levels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_levels
    ADD CONSTRAINT school_levels_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_library_loans
    ADD CONSTRAINT school_library_loans_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_messages
    ADD CONSTRAINT school_messages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_payments
    ADD CONSTRAINT school_payments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_payments
    ADD CONSTRAINT school_payments_tenant_id_external_id_key UNIQUE NULLS NOT DISTINCT (tenant_id, external_id);
ALTER TABLE ONLY gestao_escolar.school_sanction_types
    ADD CONSTRAINT school_sanction_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_sanction_types
    ADD CONSTRAINT school_sanction_types_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_series
    ADD CONSTRAINT school_series_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_series
    ADD CONSTRAINT school_series_tenant_id_level_id_codigo_key UNIQUE (tenant_id, level_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_student_fee_discounts
    ADD CONSTRAINT school_student_fee_discounts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_student_incidents
    ADD CONSTRAINT school_student_incidents_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_student_merits
    ADD CONSTRAINT school_student_merits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_student_roles
    ADD CONSTRAINT school_student_roles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_student_sanctions
    ADD CONSTRAINT school_student_sanctions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_students
    ADD CONSTRAINT school_students_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_subjects
    ADD CONSTRAINT school_subjects_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_subjects
    ADD CONSTRAINT school_subjects_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_tasks
    ADD CONSTRAINT school_tasks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_tenant_id_class_id_subject_id_te_key UNIQUE (tenant_id, class_id, subject_id, teacher_id, data_inicio);
ALTER TABLE ONLY gestao_escolar.school_teacher_roles
    ADD CONSTRAINT school_teacher_roles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_teachers
    ADD CONSTRAINT school_teachers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_teachers
    ADD CONSTRAINT school_teachers_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_terms
    ADD CONSTRAINT school_terms_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_terms
    ADD CONSTRAINT school_terms_tenant_id_school_year_id_codigo_key UNIQUE (tenant_id, school_year_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_time_slots
    ADD CONSTRAINT school_time_slots_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_time_slots
    ADD CONSTRAINT school_time_slots_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_timetable_entries
    ADD CONSTRAINT school_timetable_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_timetable_entries
    ADD CONSTRAINT school_timetable_entries_tenant_id_school_year_id_class_id__key UNIQUE (tenant_id, school_year_id, class_id, dia_semana, time_slot_id);
ALTER TABLE ONLY gestao_escolar.school_transcript_subjects
    ADD CONSTRAINT school_transcript_subjects_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_years
    ADD CONSTRAINT school_years_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gestao_escolar.school_years
    ADD CONSTRAINT school_years_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT uq_school_enrollments UNIQUE (tenant_id, numero);
ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT uq_school_fees UNIQUE (tenant_id, numero);
ALTER TABLE ONLY gestao_escolar.school_students
    ADD CONSTRAINT uq_school_students UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY impostos.tax_certificates
    ADD CONSTRAINT tax_certificates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_exemptions
    ADD CONSTRAINT tax_exemptions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_groups
    ADD CONSTRAINT tax_groups_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_regimes
    ADD CONSTRAINT tax_regimes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_return_lines
    ADD CONSTRAINT tax_return_lines_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_returns
    ADD CONSTRAINT tax_returns_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_rules
    ADD CONSTRAINT tax_rules_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_transactions
    ADD CONSTRAINT tax_transactions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_certificates
    ADD CONSTRAINT uq_tax_certificates UNIQUE (tenant_id, numero);
ALTER TABLE ONLY impostos.tax_groups
    ADD CONSTRAINT uq_tax_groups UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY impostos.tax_regimes
    ADD CONSTRAINT uq_tax_regimes UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY impostos.taxes
    ADD CONSTRAINT uq_taxes UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY impostos.withholding_taxes
    ADD CONSTRAINT uq_withholding_taxes UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY impostos.withholding_tax_transactions
    ADD CONSTRAINT withholding_tax_transactions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.withholding_taxes
    ADD CONSTRAINT withholding_taxes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY logistica.logistics_drivers
    ADD CONSTRAINT logistics_drivers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY logistica.logistics_routes
    ADD CONSTRAINT logistics_routes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT logistics_shipments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY logistica.logistics_tracking_events
    ADD CONSTRAINT logistics_tracking_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY logistica.logistics_vehicles
    ADD CONSTRAINT logistics_vehicles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY logistica.logistics_drivers
    ADD CONSTRAINT uq_logistics_drivers UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY logistica.logistics_routes
    ADD CONSTRAINT uq_logistics_routes UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT uq_logistics_shipments UNIQUE (tenant_id, numero);
ALTER TABLE ONLY logistica.logistics_vehicles
    ADD CONSTRAINT uq_logistics_vehicles_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY logistica.logistics_vehicles
    ADD CONSTRAINT uq_logistics_vehicles_matricula UNIQUE (tenant_id, matricula);
ALTER TABLE ONLY multi_moeda.currencies
    ADD CONSTRAINT currencies_code_key UNIQUE (code);
ALTER TABLE ONLY multi_moeda.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY multi_moeda.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY multi_moeda.tenant_currencies
    ADD CONSTRAINT tenant_currencies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY multi_moeda.exchange_rates
    ADD CONSTRAINT uq_exchange_rates UNIQUE (tenant_id, base_currency_id, quote_currency_id, effective_date, source);
ALTER TABLE ONLY multi_moeda.tenant_currencies
    ADD CONSTRAINT uq_tenant_currencies UNIQUE (tenant_id, currency_id);
ALTER TABLE ONLY notifications.notification_channels
    ADD CONSTRAINT notification_channels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY notifications.notification_messages
    ADD CONSTRAINT notification_messages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY notifications.notification_templates
    ADD CONSTRAINT notification_templates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY notifications.push_tokens
    ADD CONSTRAINT push_tokens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY notifications.notification_channels
    ADD CONSTRAINT uq_notification_channels UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY notifications.notification_templates
    ADD CONSTRAINT uq_notification_templates UNIQUE (tenant_id, codigo, canal_tipo);
ALTER TABLE ONLY notifications.push_tokens
    ADD CONSTRAINT uq_push_tokens_token UNIQUE (token);
ALTER TABLE ONLY pessoas.pessoa_contatos
    ADD CONSTRAINT pessoa_contatos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pessoas.pessoa_enderecos
    ADD CONSTRAINT pessoa_enderecos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pessoas.pessoa_relacoes
    ADD CONSTRAINT pessoa_relacoes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pessoas.pessoas
    ADD CONSTRAINT pessoas_codigo_key UNIQUE (codigo);
ALTER TABLE ONLY pessoas.pessoas
    ADD CONSTRAINT pessoas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pessoas.pessoa_relacoes
    ADD CONSTRAINT uq_pessoa_relacao UNIQUE (tenant_id, pessoa_id, pessoa_relacionada_id, tipo_relacao, data_inicio);
ALTER TABLE ONLY pessoas.pessoas
    ADD CONSTRAINT uq_pessoas_documento UNIQUE (tipo_documento, numero_documento);
ALTER TABLE ONLY pos.pos_catalog_items
    ADD CONSTRAINT pos_catalog_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pos.pos_sale_items
    ADD CONSTRAINT pos_sale_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pos.pos_sale_payments
    ADD CONSTRAINT pos_sale_payments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pos.pos_sales
    ADD CONSTRAINT pos_sales_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pos.pos_sessions
    ADD CONSTRAINT pos_sessions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pos.pos_terminals
    ADD CONSTRAINT pos_terminals_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pos.pos_catalog_items
    ADD CONSTRAINT uq_pos_catalog_items UNIQUE NULLS NOT DISTINCT (tenant_id, product_id, product_variant_id);
ALTER TABLE ONLY pos.pos_sales
    ADD CONSTRAINT uq_pos_sales UNIQUE (tenant_id, numero);
ALTER TABLE ONLY pos.pos_terminals
    ADD CONSTRAINT uq_pos_terminals UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY produtos.product_attribute_values
    ADD CONSTRAINT product_attribute_values_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_attributes
    ADD CONSTRAINT product_attributes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_barcodes
    ADD CONSTRAINT product_barcodes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_brands
    ADD CONSTRAINT product_brands_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_discounts
    ADD CONSTRAINT product_discounts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_images
    ADD CONSTRAINT product_images_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_kit_items
    ADD CONSTRAINT product_kit_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_kits
    ADD CONSTRAINT product_kits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_prices
    ADD CONSTRAINT product_prices_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_subcategories
    ADD CONSTRAINT product_subcategories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_tag_links
    ADD CONSTRAINT product_tag_links_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_tags
    ADD CONSTRAINT product_tags_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_units
    ADD CONSTRAINT product_units_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_variants
    ADD CONSTRAINT product_variants_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);
ALTER TABLE ONLY produtos.product_attributes
    ADD CONSTRAINT uq_product_attributes UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);
ALTER TABLE ONLY produtos.product_barcodes
    ADD CONSTRAINT uq_product_barcodes UNIQUE (barcode);
ALTER TABLE ONLY produtos.product_brands
    ADD CONSTRAINT uq_product_brands UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);
ALTER TABLE ONLY produtos.product_categories
    ADD CONSTRAINT uq_product_categories UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);
ALTER TABLE ONLY produtos.product_kits
    ADD CONSTRAINT uq_product_kits UNIQUE NULLS NOT DISTINCT (product_id, codigo);
ALTER TABLE ONLY produtos.product_subcategories
    ADD CONSTRAINT uq_product_subcategories UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);
ALTER TABLE ONLY produtos.product_tag_links
    ADD CONSTRAINT uq_product_tag_links UNIQUE (product_id, product_tag_id);
ALTER TABLE ONLY produtos.product_tags
    ADD CONSTRAINT uq_product_tags UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);
ALTER TABLE ONLY produtos.product_units
    ADD CONSTRAINT uq_product_units UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY produtos.product_variants
    ADD CONSTRAINT uq_product_variants UNIQUE NULLS NOT DISTINCT (product_id, codigo);
ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT uq_products UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY produtos.warehouses
    ADD CONSTRAINT uq_warehouses UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY produtos.warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.chat_conversas
    ADD CONSTRAINT chat_conversas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.chat_mensagens
    ADD CONSTRAINT chat_mensagens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.chat_participantes
    ADD CONSTRAINT chat_participantes_pkey PRIMARY KEY (conversa_id, user_id);
ALTER TABLE ONLY public.comunicados_lidos
    ADD CONSTRAINT comunicados_lidos_pkey PRIMARY KEY (comunicado_id, user_id);
ALTER TABLE ONLY public.comunicados
    ADD CONSTRAINT comunicados_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.notif_colaborador
    ADD CONSTRAINT notif_colaborador_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.candidato_sessions
    ADD CONSTRAINT candidato_sessions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.candidato_sessions
    ADD CONSTRAINT candidato_sessions_token_hash_key UNIQUE (token_hash);
ALTER TABLE ONLY recrutamento.candidatos
    ADD CONSTRAINT candidatos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.candidatos
    ADD CONSTRAINT candidatos_tenant_id_email_key UNIQUE (tenant_id, email);
ALTER TABLE ONLY recrutamento.candidatura_campos_custom
    ADD CONSTRAINT candidatura_campos_custom_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.candidatura_campos_custom
    ADD CONSTRAINT candidatura_campos_custom_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY recrutamento.candidatura_notas
    ADD CONSTRAINT candidatura_notas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.candidatura_respostas_vaga
    ADD CONSTRAINT candidatura_respostas_vaga_candidatura_id_campo_id_key UNIQUE (candidatura_id, campo_id);
ALTER TABLE ONLY recrutamento.candidatura_respostas_vaga
    ADD CONSTRAINT candidatura_respostas_vaga_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.candidatura_valores_custom
    ADD CONSTRAINT candidatura_valores_custom_candidatura_id_campo_id_key UNIQUE (candidatura_id, campo_id);
ALTER TABLE ONLY recrutamento.candidatura_valores_custom
    ADD CONSTRAINT candidatura_valores_custom_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.candidaturas
    ADD CONSTRAINT candidaturas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.config_notificacoes
    ADD CONSTRAINT config_notificacoes_pkey PRIMARY KEY (tenant_id);
ALTER TABLE ONLY recrutamento.contactos
    ADD CONSTRAINT contactos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.candidaturas
    ADD CONSTRAINT uq_candidaturas_codigo_acompanhamento UNIQUE (codigo_acompanhamento);
ALTER TABLE ONLY recrutamento.vaga_campos
    ADD CONSTRAINT vaga_campos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recrutamento.vaga_campos
    ADD CONSTRAINT vaga_campos_vaga_id_codigo_key UNIQUE (vaga_id, codigo);
ALTER TABLE ONLY recrutamento.vagas
    ADD CONSTRAINT vagas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.adiantamentos
    ADD CONSTRAINT adiantamentos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.auditoria_assiduidade
    ADD CONSTRAINT auditoria_assiduidade_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.ausencias
    ADD CONSTRAINT ausencias_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.avaliacao_criterios
    ADD CONSTRAINT avaliacao_criterios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.avaliacoes
    ADD CONSTRAINT avaliacoes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.beneficios
    ADD CONSTRAINT beneficios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.cargos
    ADD CONSTRAINT cargos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.componentes_salariais
    ADD CONSTRAINT componentes_salariais_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.config_contabilidade_folha
    ADD CONSTRAINT config_contabilidade_folha_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.contactos_emergencia
    ADD CONSTRAINT contactos_emergencia_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.contratos
    ADD CONSTRAINT contratos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.correcoes_evento
    ADD CONSTRAINT correcoes_evento_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.criterios_avaliacao
    ADD CONSTRAINT criterios_avaliacao_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.unidades_organizacionais
    ADD CONSTRAINT departamentos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.documentos_funcionario
    ADD CONSTRAINT documentos_funcionario_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.emprestimos
    ADD CONSTRAINT emprestimos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.eventos_assiduidade
    ADD CONSTRAINT eventos_assiduidade_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.folhas_pagamento
    ADD CONSTRAINT folhas_pagamento_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.formacoes
    ADD CONSTRAINT formacoes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.funcionario_beneficios
    ADD CONSTRAINT funcionario_beneficios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.funcionario_componentes_salariais
    ADD CONSTRAINT funcionario_componentes_salariais_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.funcionario_formacoes
    ADD CONSTRAINT funcionario_formacoes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.funcionario_horarios
    ADD CONSTRAINT funcionario_horarios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT funcionarios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.historico_salarial
    ADD CONSTRAINT historico_salarial_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.horarios_dias
    ADD CONSTRAINT horarios_dias_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.horarios_trabalho
    ADD CONSTRAINT horarios_trabalho_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.irps_escaloes
    ADD CONSTRAINT irps_escaloes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.justificacoes
    ADD CONSTRAINT justificacoes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.metodos_marcacao
    ADD CONSTRAINT metodos_marcacao_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.periodos_avaliacao
    ADD CONSTRAINT periodos_avaliacao_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.presencas
    ADD CONSTRAINT presencas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.processos_disciplinares
    ADD CONSTRAINT processos_disciplinares_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.recibo_vencimento_itens
    ADD CONSTRAINT recibo_vencimento_itens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.recibos_vencimento
    ADD CONSTRAINT recibos_vencimento_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.regras_assiduidade
    ADD CONSTRAINT regras_assiduidade_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.resultados_diarios
    ADD CONSTRAINT resultados_diarios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.resultados_periodos
    ADD CONSTRAINT resultados_periodos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.saldos_ausencia
    ADD CONSTRAINT saldos_ausencia_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.tipos_ausencia
    ADD CONSTRAINT tipos_ausencia_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.tipos_evento
    ADD CONSTRAINT tipos_evento_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.tipos_regra
    ADD CONSTRAINT tipos_regra_codigo_key UNIQUE (codigo);
ALTER TABLE ONLY rh.tipos_regra
    ADD CONSTRAINT tipos_regra_pkey PRIMARY KEY (id);
ALTER TABLE ONLY rh.avaliacao_criterios
    ADD CONSTRAINT uq_avaliacao_criterios UNIQUE (avaliacao_id, criterio_id);
ALTER TABLE ONLY rh.beneficios
    ADD CONSTRAINT uq_beneficios_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY rh.cargos
    ADD CONSTRAINT uq_cargos_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY rh.componentes_salariais
    ADD CONSTRAINT uq_componentes_salariais_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY rh.config_contabilidade_folha
    ADD CONSTRAINT uq_config_contabilidade_folha_tenant UNIQUE (tenant_id);
ALTER TABLE ONLY rh.criterios_avaliacao
    ADD CONSTRAINT uq_criterios_avaliacao_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY rh.folhas_pagamento
    ADD CONSTRAINT uq_folhas_pagamento_tenant_ano_mes UNIQUE (tenant_id, ano, mes);
ALTER TABLE ONLY rh.formacoes
    ADD CONSTRAINT uq_formacoes_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY rh.funcionario_beneficios
    ADD CONSTRAINT uq_funcionario_beneficio UNIQUE (funcionario_id, beneficio_id);
ALTER TABLE ONLY rh.funcionario_componentes_salariais
    ADD CONSTRAINT uq_funcionario_componente UNIQUE (funcionario_id, componente_id);
ALTER TABLE ONLY rh.funcionario_horarios
    ADD CONSTRAINT uq_funcionario_horarios_tenant_func_inicio UNIQUE (tenant_id, funcionario_id, data_inicio);
ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT uq_funcionarios_user_id UNIQUE (user_id);
ALTER TABLE ONLY rh.horarios_dias
    ADD CONSTRAINT uq_horarios_dias_horario_dia_ordem UNIQUE (horario_id, dia_semana, data_especifica, ordem);
ALTER TABLE ONLY rh.horarios_trabalho
    ADD CONSTRAINT uq_horarios_trabalho_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY rh.irps_escaloes
    ADD CONSTRAINT uq_irps_escaloes_tenant_ano_inf UNIQUE (tenant_id, ano_fiscal, limite_inf);
ALTER TABLE ONLY rh.metodos_marcacao
    ADD CONSTRAINT uq_metodos_marcacao_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY rh.periodos_avaliacao
    ADD CONSTRAINT uq_periodos_avaliacao_tenant_nome UNIQUE (tenant_id, nome);
ALTER TABLE ONLY rh.presencas
    ADD CONSTRAINT uq_presencas_funcionario_data UNIQUE (funcionario_id, data);
ALTER TABLE ONLY rh.recibos_vencimento
    ADD CONSTRAINT uq_recibos_vencimento_folha_funcionario UNIQUE (folha_id, funcionario_id);
ALTER TABLE ONLY rh.regras_assiduidade
    ADD CONSTRAINT uq_regras_assiduidade_tenant_tipo_ambito_entidade_inicio UNIQUE (tenant_id, tipo_regra_id, ambito, entidade_id, data_inicio);
ALTER TABLE ONLY rh.resultados_diarios
    ADD CONSTRAINT uq_resultados_diarios_tenant_func_data UNIQUE (tenant_id, funcionario_id, data_referencia);
ALTER TABLE ONLY rh.resultados_periodos
    ADD CONSTRAINT uq_resultados_periodos_tenant_func_tipo_ano_num UNIQUE (tenant_id, funcionario_id, tipo_periodo, ano, numero);
ALTER TABLE ONLY rh.saldos_ausencia
    ADD CONSTRAINT uq_saldos_ausencia UNIQUE (funcionario_id, tipo_ausencia_id, ano);
ALTER TABLE ONLY rh.tipos_ausencia
    ADD CONSTRAINT uq_tipos_ausencia_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY rh.tipos_evento
    ADD CONSTRAINT uq_tipos_evento_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY rh.unidades_organizacionais
    ADD CONSTRAINT uq_unidades_organizacionais_tenant_codigo UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY saas.approval_decisions
    ADD CONSTRAINT approval_decisions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY saas.approval_flows
    ADD CONSTRAINT approval_flows_pkey PRIMARY KEY (id);
ALTER TABLE ONLY saas.approval_flows
    ADD CONSTRAINT approval_flows_tenant_id_feature_nome_key UNIQUE (tenant_id, feature, nome);
ALTER TABLE ONLY saas.approval_requests
    ADD CONSTRAINT approval_requests_pkey PRIMARY KEY (id);
ALTER TABLE ONLY saas.feature_catalog
    ADD CONSTRAINT feature_catalog_pkey PRIMARY KEY (key);
ALTER TABLE ONLY saas.global_settings
    ADD CONSTRAINT global_settings_pkey PRIMARY KEY (chave);
ALTER TABLE ONLY saas.module_catalog
    ADD CONSTRAINT module_catalog_pkey PRIMARY KEY (key);
ALTER TABLE ONLY saas.module_dependencies
    ADD CONSTRAINT module_dependencies_pkey PRIMARY KEY (modulo, requires);
ALTER TABLE ONLY saas.plan_modules
    ADD CONSTRAINT plan_modules_pkey PRIMARY KEY (plan_id, modulo);
ALTER TABLE ONLY saas.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);
ALTER TABLE ONLY saas.tenant_dominios
    ADD CONSTRAINT tenant_dominios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY saas.tenant_modules
    ADD CONSTRAINT tenant_modules_pkey PRIMARY KEY (tenant_id, modulo);
ALTER TABLE ONLY saas.tenant_subscriptions
    ADD CONSTRAINT tenant_subscriptions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY saas.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);
ALTER TABLE ONLY saas.plans
    ADD CONSTRAINT uq_plans_codigo UNIQUE (codigo);
ALTER TABLE ONLY saas.tenant_dominios
    ADD CONSTRAINT uq_tenant_dominios_dominio UNIQUE (dominio);
ALTER TABLE ONLY saas.tenants
    ADD CONSTRAINT uq_tenants_codigo UNIQUE (codigo);
ALTER TABLE ONLY seguranca.security_ip_allowlist
    ADD CONSTRAINT security_ip_allowlist_pkey PRIMARY KEY (id);
ALTER TABLE ONLY seguranca.security_mfa_enrollments
    ADD CONSTRAINT security_mfa_enrollments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY seguranca.security_policies
    ADD CONSTRAINT security_policies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY seguranca.security_ip_allowlist
    ADD CONSTRAINT uq_security_ip_allowlist UNIQUE (tenant_id, ip_or_cidr);
ALTER TABLE ONLY seguranca.security_mfa_enrollments
    ADD CONSTRAINT uq_security_mfa_user_method UNIQUE (tenant_id, user_id, metodo);
ALTER TABLE ONLY seguranca.security_policies
    ADD CONSTRAINT uq_security_policies UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY sistema_configuracao.api_logs
    ADD CONSTRAINT api_logs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.cities
    ADD CONSTRAINT cities_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.sms_templates
    ADD CONSTRAINT sms_templates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.system_logs
    ADD CONSTRAINT system_logs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.tenant_branding
    ADD CONSTRAINT tenant_branding_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.tenant_branding
    ADD CONSTRAINT tenant_branding_tenant_id_key UNIQUE (tenant_id);
ALTER TABLE ONLY sistema_configuracao.tenant_defaults
    ADD CONSTRAINT tenant_defaults_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.tenant_document_settings
    ADD CONSTRAINT tenant_document_settings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.tenant_feature_flags
    ADD CONSTRAINT tenant_feature_flags_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.tenant_integrations
    ADD CONSTRAINT tenant_integrations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sistema_configuracao.countries
    ADD CONSTRAINT uq_countries UNIQUE (codigo);
ALTER TABLE ONLY sistema_configuracao.currencies
    ADD CONSTRAINT uq_currencies UNIQUE (codigo);
ALTER TABLE ONLY sistema_configuracao.languages
    ADD CONSTRAINT uq_languages UNIQUE (codigo);
ALTER TABLE ONLY sistema_configuracao.tenant_defaults
    ADD CONSTRAINT uq_tenant_defaults UNIQUE (tenant_id, chave);
ALTER TABLE ONLY sistema_configuracao.tenant_document_settings
    ADD CONSTRAINT uq_tenant_document_settings UNIQUE (tenant_id, modulo, tipo_documento);
ALTER TABLE ONLY sistema_configuracao.tenant_feature_flags
    ADD CONSTRAINT uq_tenant_feature_flags UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY sistema_configuracao.tenant_integrations
    ADD CONSTRAINT uq_tenant_integrations UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY stock.stock_adjustments
    ADD CONSTRAINT stock_adjustments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_alerts
    ADD CONSTRAINT stock_alerts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_batches
    ADD CONSTRAINT stock_batches_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_count_items
    ADD CONSTRAINT stock_count_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_counts
    ADD CONSTRAINT stock_counts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_items
    ADD CONSTRAINT stock_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_logs
    ADD CONSTRAINT stock_logs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_reservations
    ADD CONSTRAINT stock_reservations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_serial_numbers
    ADD CONSTRAINT stock_serial_numbers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_transfer_items
    ADD CONSTRAINT stock_transfer_items_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_transfers
    ADD CONSTRAINT stock_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY stock.stock_batches
    ADD CONSTRAINT uq_stock_batches UNIQUE (stock_item_id, batch_number);
ALTER TABLE ONLY stock.stock_counts
    ADD CONSTRAINT uq_stock_counts UNIQUE (tenant_id, numero);
ALTER TABLE ONLY stock.stock_items
    ADD CONSTRAINT uq_stock_items UNIQUE NULLS NOT DISTINCT (tenant_id, product_id, product_variant_id, warehouse_id);
ALTER TABLE ONLY stock.stock_serial_numbers
    ADD CONSTRAINT uq_stock_serial_numbers UNIQUE (serial_number);
ALTER TABLE ONLY stock.stock_transfers
    ADD CONSTRAINT uq_stock_transfers UNIQUE (tenant_id, numero);
ALTER TABLE ONLY stock.warehouse_locations
    ADD CONSTRAINT uq_warehouse_locations UNIQUE (warehouse_id, codigo);
ALTER TABLE ONLY stock.warehouse_locations
    ADD CONSTRAINT warehouse_locations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tarefas.cartoes
    ADD CONSTRAINT cartoes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tarefas.listas
    ADD CONSTRAINT listas_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tarefas.quadros
    ADD CONSTRAINT quadros_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tesouraria.bank_accounts
    ADD CONSTRAINT bank_accounts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tesouraria.bank_accounts
    ADD CONSTRAINT bank_accounts_tenant_id_banco_numero_conta_key UNIQUE (tenant_id, banco, numero_conta);
ALTER TABLE ONLY tesouraria.bank_accounts
    ADD CONSTRAINT bank_accounts_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY tesouraria.cash_registers
    ADD CONSTRAINT cash_registers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tesouraria.cash_registers
    ADD CONSTRAINT cash_registers_tenant_id_codigo_key UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY tesouraria.movements
    ADD CONSTRAINT movements_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tesouraria.reconciliations
    ADD CONSTRAINT reconciliations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tesouraria.reconciliations
    ADD CONSTRAINT reconciliations_tenant_id_bank_account_id_periodo_inicio_pe_key UNIQUE (tenant_id, bank_account_id, periodo_inicio, periodo_fim);
ALTER TABLE ONLY utilizadores.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY utilizadores.profiles
    ADD CONSTRAINT uq_profiles_user UNIQUE (user_id);
ALTER TABLE ONLY utilizadores.user_avatar
    ADD CONSTRAINT uq_user_avatar UNIQUE (user_id);
ALTER TABLE ONLY utilizadores.user_devices
    ADD CONSTRAINT uq_user_devices UNIQUE (user_id, device_id);
ALTER TABLE ONLY utilizadores.user_preferences
    ADD CONSTRAINT uq_user_preferences UNIQUE (user_id, chave);
ALTER TABLE ONLY utilizadores.user_settings
    ADD CONSTRAINT uq_user_settings UNIQUE (user_id, chave);
ALTER TABLE ONLY utilizadores.user_activity
    ADD CONSTRAINT user_activity_pkey PRIMARY KEY (id);
ALTER TABLE ONLY utilizadores.user_avatar
    ADD CONSTRAINT user_avatar_pkey PRIMARY KEY (id);
ALTER TABLE ONLY utilizadores.user_devices
    ADD CONSTRAINT user_devices_pkey PRIMARY KEY (id);
ALTER TABLE ONLY utilizadores.user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (id);
ALTER TABLE ONLY utilizadores.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);
ALTER TABLE ONLY utilizadores.user_security_logs
    ADD CONSTRAINT user_security_logs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY utilizadores.user_settings
    ADD CONSTRAINT user_settings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY utilizadores.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);
CREATE INDEX IF NOT EXISTS idx_documentos_status ON assinatura_digital.documentos USING btree (status);
CREATE INDEX IF NOT EXISTS idx_documentos_tenant ON assinatura_digital.documentos USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_logs_documento ON assinatura_digital.logs USING btree (documento_id);
CREATE INDEX IF NOT EXISTS idx_signatarios_documento ON assinatura_digital.signatarios USING btree (documento_id);
CREATE INDEX IF NOT EXISTS idx_signatarios_pessoa ON assinatura_digital.signatarios USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_signatarios_tenant ON assinatura_digital.signatarios USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_versoes_documento ON assinatura_digital.versoes_assinadas USING btree (documento_id);
CREATE INDEX IF NOT EXISTS idx_subscription_invoices_tenant_status ON assinaturas.subscription_invoices USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_tenant ON assinaturas.subscription_plans USING btree (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_tenant_periodo ON assinaturas.subscription_usage USING btree (tenant_id, periodo);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_status ON assinaturas.subscriptions USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_created ON auditoria.audit_events USING btree (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_entity ON auditoria.audit_events USING btree (tenant_id, entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_service ON auditoria.audit_events USING btree (tenant_id, service_name, module_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON auditoria.audit_logs USING btree (created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_modulo ON auditoria.audit_logs USING btree (modulo);
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_id ON auditoria.audit_logs USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON auditoria.audit_logs USING btree (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_audit_events_hash ON auditoria.audit_events USING btree (event_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_key_prefix ON auth.api_keys USING btree (key_prefix);
CREATE INDEX IF NOT EXISTS idx_api_keys_tenant_id ON auth.api_keys USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_acao ON auth.audit_logs USING btree (acao);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON auth.audit_logs USING btree (created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_id ON auth.audit_logs USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON auth.audit_logs USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_cargos_tenant_id ON auth.cargos USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_login_history_tenant_id ON auth.login_history USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_login_history_user_id ON auth.login_history USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_tenant_id ON auth.memberships USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_password_resets_user_id ON auth.password_resets USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_permissoes_cargo_cargo_id ON auth.permissoes_cargo USING btree (cargo_id);
CREATE INDEX IF NOT EXISTS idx_permissoes_diretas_tenant_id ON auth.permissoes_diretas USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_permissoes_diretas_user_id ON auth.permissoes_diretas USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_permissoes_tipo_tipo ON auth.permissoes_tipo USING btree (tipo);
CREATE INDEX IF NOT EXISTS idx_sessions_ativa ON auth.sessions USING btree (ativa);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON auth.sessions USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_superadmin_ip_allowlist_ativo ON auth.superadmin_ip_allowlist USING btree (ativo);
CREATE INDEX IF NOT EXISTS idx_users_pessoa_id ON auth.users USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON autorizacao.role_permissions USING btree (role_id);
CREATE INDEX IF NOT EXISTS idx_roles_tenant_id ON autorizacao.roles USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON autorizacao.user_roles USING btree (role_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON autorizacao.user_roles USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_cost_center_allocations_source ON centros_custo.cost_center_allocations USING btree (tenant_id, source_service, source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_cost_center_allocations_tenant ON centros_custo.cost_center_allocations USING btree (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cost_center_budgets_tenant ON centros_custo.cost_center_budgets USING btree (tenant_id, ano, mes);
CREATE INDEX IF NOT EXISTS idx_cost_centers_tenant ON centros_custo.cost_centers USING btree (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_id ON clientes.customer_addresses USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_contacts_customer_id ON clientes.customer_contacts USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_contacts_pessoa ON clientes.customer_contacts USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_customer_discounts_customer_id ON clientes.customer_discounts USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_documents_customer_id ON clientes.customer_documents USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_groups_tenant_id ON clientes.customer_groups USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_customer_history_customer_created ON clientes.customer_history USING btree (customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_history_customer_id ON clientes.customer_history USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_notes_customer_id ON clientes.customer_notes USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_payments_customer_id ON clientes.customer_payments USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_payments_tenant_pago_em ON clientes.customer_payments USING btree (tenant_id, pago_em DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tag_links_customer_id ON clientes.customer_tag_links USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_customers_group_id ON clientes.customers USING btree (customer_group_id);
CREATE INDEX IF NOT EXISTS idx_customers_pessoa ON clientes.customers USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant_estado ON clientes.customers USING btree (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_customers_tenant_id ON clientes.customers USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipt_items_receipt ON compras.goods_receipt_items USING btree (goods_receipt_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_tenant_date ON compras.goods_receipts USING btree (tenant_id, receipt_date);
CREATE INDEX IF NOT EXISTS idx_purchase_invoice_items_invoice ON compras.purchase_invoice_items USING btree (purchase_invoice_id);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_tenant_status ON compras.purchase_invoices USING btree (tenant_id, status, due_date);
CREATE INDEX IF NOT EXISTS idx_purchase_order_items_order ON compras.purchase_order_items USING btree (purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier ON compras.purchase_orders USING btree (supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_tenant_status ON compras.purchase_orders USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_purchase_payment_items_payment ON compras.purchase_payment_items USING btree (purchase_payment_id);
CREATE INDEX IF NOT EXISTS idx_purchase_payments_tenant_date ON compras.purchase_payments USING btree (tenant_id, payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_request_items_request ON compras.purchase_request_items USING btree (purchase_request_id);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_tenant_status ON compras.purchase_requests USING btree (tenant_id, status, request_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_return_items_return ON compras.purchase_return_items USING btree (purchase_return_id);
CREATE INDEX IF NOT EXISTS idx_purchase_returns_tenant_date ON compras.purchase_returns USING btree (tenant_id, return_date);
CREATE INDEX IF NOT EXISTS idx_supplier_groups_tenant ON compras.supplier_groups USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_tenant ON compras.suppliers USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_accounting_budgets_account ON contabilidade.accounting_budgets USING btree (chart_account_id);
CREATE INDEX IF NOT EXISTS idx_accounting_budgets_tenant ON contabilidade.accounting_budgets USING btree (tenant_id, fiscal_year_id);
CREATE INDEX IF NOT EXISTS idx_accounting_journals_tenant ON contabilidade.accounting_journals USING btree (tenant_id, codigo);
CREATE INDEX IF NOT EXISTS idx_accounting_periods_tenant ON contabilidade.fiscal_periods USING btree (tenant_id, ano, mes);
CREATE INDEX IF NOT EXISTS idx_accounting_reports_tenant ON contabilidade.accounting_reports USING btree (tenant_id, tipo, gerado_em DESC);
CREATE INDEX IF NOT EXISTS idx_chart_of_accounts_account_type ON contabilidade.chart_of_accounts USING btree (tenant_id, account_type_id);
CREATE INDEX IF NOT EXISTS idx_chart_of_accounts_tenant ON contabilidade.chart_of_accounts USING btree (tenant_id, codigo);
CREATE INDEX IF NOT EXISTS idx_depreciation_entries_asset ON contabilidade.depreciation_entries USING btree (fixed_asset_id);
CREATE INDEX IF NOT EXISTS idx_depreciation_entries_journal ON contabilidade.depreciation_entries USING btree (journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_depreciation_entries_period ON contabilidade.depreciation_entries USING btree (fiscal_period_id);
CREATE INDEX IF NOT EXISTS idx_depreciation_entries_tenant ON contabilidade.depreciation_entries USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_fiscal_periods_fiscal_year ON contabilidade.fiscal_periods USING btree (fiscal_year_id);
CREATE INDEX IF NOT EXISTS idx_fixed_assets_account ON contabilidade.fixed_assets USING btree (chart_account_id);
CREATE INDEX IF NOT EXISTS idx_fixed_assets_tenant ON contabilidade.fixed_assets USING btree (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_journal_entries_fiscal_period ON contabilidade.journal_entries USING btree (tenant_id, fiscal_period_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_status ON contabilidade.journal_entries USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_journal_entries_tenant_date ON contabilidade.journal_entries USING btree (tenant_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_journal_entry_lines_account ON contabilidade.journal_entry_lines USING btree (account_id);
CREATE INDEX IF NOT EXISTS idx_journal_entry_lines_entry ON contabilidade.journal_entry_lines USING btree (journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_period_closing_checks_closing ON contabilidade.period_closing_checks USING btree (period_closing_id);
CREATE INDEX IF NOT EXISTS idx_period_closings_status ON contabilidade.period_closings USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_period_closings_tenant ON contabilidade.period_closings USING btree (tenant_id, fiscal_period_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_accounting_budgets_anual ON contabilidade.accounting_budgets USING btree (tenant_id, chart_account_id, fiscal_year_id) WHERE (mes IS NULL);
CREATE INDEX IF NOT EXISTS idx_atividades_concluida ON crm.atividades USING btree (concluida);
CREATE INDEX IF NOT EXISTS idx_atividades_data ON crm.atividades USING btree (data_atividade);
CREATE INDEX IF NOT EXISTS idx_atividades_lead_id ON crm.atividades USING btree (lead_id);
CREATE INDEX IF NOT EXISTS idx_atividades_oportunidade_id ON crm.atividades USING btree (oportunidade_id);
CREATE INDEX IF NOT EXISTS idx_atividades_tenant_id ON crm.atividades USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_atividades_tipo ON crm.atividades USING btree (tipo);
CREATE INDEX IF NOT EXISTS idx_crm_leads_responsavel_id ON crm.leads USING btree (responsavel_id);
CREATE INDEX IF NOT EXISTS idx_crm_oportunidades_responsavel_id ON crm.oportunidades USING btree (responsavel_id);
CREATE INDEX IF NOT EXISTS idx_leads_email ON crm.leads USING btree (email);
CREATE INDEX IF NOT EXISTS idx_leads_estado ON crm.leads USING btree (estado);
CREATE INDEX IF NOT EXISTS idx_leads_responsavel ON crm.leads USING btree (responsavel);
CREATE INDEX IF NOT EXISTS idx_leads_tenant_id ON crm.leads USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_oportunidades_cliente_id ON crm.oportunidades USING btree (cliente_id);
CREATE INDEX IF NOT EXISTS idx_oportunidades_estagio ON crm.oportunidades USING btree (estagio);
CREATE INDEX IF NOT EXISTS idx_oportunidades_lead_id ON crm.oportunidades USING btree (lead_id);
CREATE INDEX IF NOT EXISTS idx_oportunidades_responsavel ON crm.oportunidades USING btree (responsavel);
CREATE INDEX IF NOT EXISTS idx_oportunidades_tenant_id ON crm.oportunidades USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_companies_tenant_id ON empresas.companies USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_company_addresses_company_id ON empresas.company_addresses USING btree (company_id);
CREATE INDEX IF NOT EXISTS idx_company_banks_company_id ON empresas.company_banks USING btree (company_id);
CREATE INDEX IF NOT EXISTS idx_company_branches_company_id ON empresas.company_branches USING btree (company_id);
CREATE INDEX IF NOT EXISTS idx_company_contacts_company_id ON empresas.company_contacts USING btree (company_id);
CREATE INDEX IF NOT EXISTS idx_company_contacts_pessoa ON empresas.company_contacts USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_company_documents_company_id ON empresas.company_documents USING btree (company_id);
CREATE INDEX IF NOT EXISTS idx_company_licenses_company_id ON empresas.company_licenses USING btree (company_id);
CREATE INDEX IF NOT EXISTS idx_company_settings_company_id ON empresas.company_settings USING btree (company_id);
CREATE INDEX IF NOT EXISTS idx_company_users_company_id ON empresas.company_users USING btree (company_id);
CREATE INDEX IF NOT EXISTS idx_company_users_user_id ON empresas.company_users USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_credit_notes_invoice ON faturacao.credit_notes USING btree (invoice_id);
CREATE INDEX IF NOT EXISTS idx_credit_notes_tenant ON faturacao.credit_notes USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_invoice_receipts_invoice ON faturacao.invoice_receipts USING btree (invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_series_tenant ON faturacao.invoice_series USING btree (tenant_id, tipo, ano);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON faturacao.invoices USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON faturacao.invoices USING btree (due_date) WHERE ((status)::text <> ALL (ARRAY[('paga'::character varying)::text, ('cancelada'::character varying)::text]));
CREATE INDEX IF NOT EXISTS idx_invoices_order ON faturacao.invoices USING btree (sales_order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant ON faturacao.invoices USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_receipts_invoice ON faturacao.invoice_receipts USING btree (invoice_id);
CREATE INDEX IF NOT EXISTS idx_sales_deliveries_order ON faturacao.sales_deliveries USING btree (sales_order_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_customer ON faturacao.sales_orders USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_quote ON faturacao.sales_orders USING btree (sales_quote_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_tenant ON faturacao.sales_orders USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_sales_quotes_customer ON faturacao.sales_quotes USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_quotes_tenant ON faturacao.sales_quotes USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_sales_returns_invoice ON faturacao.sales_returns USING btree (invoice_id);
CREATE INDEX IF NOT EXISTS idx_ap_tenant_status ON financeiro.accounts_payable USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_ap_vencimento ON financeiro.accounts_payable USING btree (data_vencimento);
CREATE INDEX IF NOT EXISTS idx_ar_customer ON financeiro.accounts_receivable USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_ar_tenant_status ON financeiro.accounts_receivable USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_ar_vencimento ON financeiro.accounts_receivable USING btree (data_vencimento);
CREATE INDEX IF NOT EXISTS idx_budgets_tenant ON financeiro.financial_budgets USING btree (tenant_id, ano);
CREATE INDEX IF NOT EXISTS idx_cashflow_tenant_data ON financeiro.cash_flow_entries USING btree (tenant_id, data);
CREATE INDEX IF NOT EXISTS idx_financial_categories_tenant ON financeiro.financial_categories USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_tenant ON financeiro.payment_methods USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_data ON financeiro.payments USING btree (tenant_id, data_pagamento);
CREATE INDEX IF NOT EXISTS idx_payments_referencia ON financeiro.payments USING btree (referencia_tipo, referencia_id);
CREATE INDEX IF NOT EXISTS idx_payments_tenant ON financeiro.payments USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_tenant ON gestao_escolar.school_calendar_events USING btree (tenant_id, data_inicio);
CREATE INDEX IF NOT EXISTS idx_calendar_events_year ON gestao_escolar.school_calendar_events USING btree (tenant_id, school_year_id, data_inicio);
CREATE INDEX IF NOT EXISTS idx_cst_course_subject ON gestao_escolar.school_course_subject_terms USING btree (course_subject_id);
CREATE INDEX IF NOT EXISTS idx_cst_term ON gestao_escolar.school_course_subject_terms USING btree (tenant_id, term_id);
CREATE INDEX IF NOT EXISTS idx_fee_generations ON gestao_escolar.school_fee_generations USING btree (tenant_id, fee_plan_id, periodo_referencia);
CREATE INDEX IF NOT EXISTS idx_grade_formulas_tenant ON gestao_escolar.school_grade_formulas USING btree (tenant_id, level_id, course_id);
CREATE INDEX IF NOT EXISTS idx_grade_items_subject ON gestao_escolar.school_grade_items USING btree (tenant_id, subject_id);
CREATE INDEX IF NOT EXISTS idx_grade_items_tenant ON gestao_escolar.school_grade_items USING btree (tenant_id, class_id, term_id);
CREATE INDEX IF NOT EXISTS idx_guardian_sessions_email_tenant ON gestao_escolar.guardian_portal_sessions USING btree (guardian_email, tenant_id) WHERE (ativa = true);
CREATE INDEX IF NOT EXISTS idx_incidents_student ON gestao_escolar.school_student_incidents USING btree (tenant_id, student_id, data_ocorrencia);
CREATE INDEX IF NOT EXISTS idx_incidents_year ON gestao_escolar.school_student_incidents USING btree (tenant_id, school_year_id, status);
CREATE INDEX IF NOT EXISTS idx_library_loans_tenant ON gestao_escolar.school_library_loans USING btree (tenant_id, student_id, status);
CREATE INDEX IF NOT EXISTS idx_merits_student ON gestao_escolar.school_student_merits USING btree (tenant_id, student_id);
CREATE INDEX IF NOT EXISTS idx_portal_sessions_tenant ON gestao_escolar.portal_sessions USING btree (tenant_id, student_id);
CREATE INDEX IF NOT EXISTS idx_sanctions_incident ON gestao_escolar.school_student_sanctions USING btree (tenant_id, incident_id);
CREATE INDEX IF NOT EXISTS idx_school_assignments_class ON gestao_escolar.school_teacher_assignments USING btree (class_id, subject_id);
CREATE INDEX IF NOT EXISTS idx_school_attendance_date ON gestao_escolar.school_attendance USING btree (tenant_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_school_attendance_filters ON gestao_escolar.school_attendance USING btree (tenant_id, class_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_school_attendance_tenant ON gestao_escolar.school_attendance USING btree (tenant_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_school_cargo_permissoes_lookup ON gestao_escolar.school_cargo_permissoes USING btree (tenant_id, class_id, cargo, permissao);
CREATE INDEX IF NOT EXISTS idx_school_classes_level ON gestao_escolar.school_classes USING btree (tenant_id, level_id);
CREATE INDEX IF NOT EXISTS idx_school_classes_tenant_year ON gestao_escolar.school_classes USING btree (tenant_id, school_year_id);
CREATE INDEX IF NOT EXISTS idx_school_classes_year ON gestao_escolar.school_classes USING btree (tenant_id, school_year_id);
CREATE INDEX IF NOT EXISTS idx_school_enrollments_class ON gestao_escolar.school_enrollments USING btree (tenant_id, class_id);
CREATE INDEX IF NOT EXISTS idx_school_enrollments_tenant ON gestao_escolar.school_enrollments USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_enrollments_tenant_year ON gestao_escolar.school_enrollments USING btree (tenant_id, school_year_id, status);
CREATE INDEX IF NOT EXISTS idx_school_enrollments_year ON gestao_escolar.school_enrollments USING btree (tenant_id, school_year_id);
CREATE INDEX IF NOT EXISTS idx_school_fees_filters ON gestao_escolar.school_fees USING btree (tenant_id, student_id, status, data_vencimento);
CREATE INDEX IF NOT EXISTS idx_school_fees_status ON gestao_escolar.school_fees USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_fees_tenant ON gestao_escolar.school_fees USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_grades_student ON gestao_escolar.school_grades USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_school_guardians_client ON gestao_escolar.school_guardians USING btree (tenant_id, client_id) WHERE (client_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_school_guardians_pessoa_id ON gestao_escolar.school_guardians USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_school_guardians_student ON gestao_escolar.school_guardians USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_school_guardians_user_id ON gestao_escolar.school_guardians USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_school_loans_status ON gestao_escolar.school_library_loans USING btree (tenant_id, status, devolucao_prevista);
CREATE INDEX IF NOT EXISTS idx_school_messages_tenant_status ON gestao_escolar.school_messages USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_payments_external ON gestao_escolar.school_payments USING btree (tenant_id, external_id) WHERE (external_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_school_payments_fee ON gestao_escolar.school_payments USING btree (school_fee_id, status);
CREATE INDEX IF NOT EXISTS idx_school_students_client ON gestao_escolar.school_students USING btree (tenant_id, client_id) WHERE (client_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_school_students_pessoa_id ON gestao_escolar.school_students USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_school_students_tenant ON gestao_escolar.school_students USING btree (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_school_students_tenant_estado ON gestao_escolar.school_students USING btree (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_school_students_user_id ON gestao_escolar.school_students USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_school_tasks_class ON gestao_escolar.school_tasks USING btree (tenant_id, class_id, status);
CREATE INDEX IF NOT EXISTS idx_school_tasks_dates ON gestao_escolar.school_tasks USING btree (tenant_id, data_fim);
CREATE INDEX IF NOT EXISTS idx_school_tasks_teacher ON gestao_escolar.school_tasks USING btree (tenant_id, teacher_id, status);
CREATE INDEX IF NOT EXISTS idx_school_tasks_tenant ON gestao_escolar.school_tasks USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_teachers_pessoa_id ON gestao_escolar.school_teachers USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_school_teachers_rh_employee ON gestao_escolar.school_teachers USING btree (tenant_id, rh_employee_id) WHERE (rh_employee_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_school_teachers_status ON gestao_escolar.school_teachers USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_terms_level ON gestao_escolar.school_terms USING btree (level_id);
CREATE INDEX IF NOT EXISTS idx_school_terms_year ON gestao_escolar.school_terms USING btree (school_year_id);
CREATE INDEX IF NOT EXISTS idx_school_years_tenant ON gestao_escolar.school_years USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_student_discounts ON gestao_escolar.school_student_fee_discounts USING btree (tenant_id, student_id, activo);
CREATE INDEX IF NOT EXISTS idx_student_fee_discounts_tenant ON gestao_escolar.school_student_fee_discounts USING btree (tenant_id, student_id);
CREATE INDEX IF NOT EXISTS idx_student_merits_tenant ON gestao_escolar.school_student_merits USING btree (tenant_id, student_id);
CREATE INDEX IF NOT EXISTS idx_student_roles_tenant ON gestao_escolar.school_student_roles USING btree (tenant_id, student_id);
CREATE INDEX IF NOT EXISTS idx_student_sanctions_tenant ON gestao_escolar.school_student_sanctions USING btree (tenant_id, incident_id);
CREATE INDEX IF NOT EXISTS idx_teacher_roles_tenant ON gestao_escolar.school_teacher_roles USING btree (tenant_id, teacher_id);
CREATE INDEX IF NOT EXISTS idx_timetable_class ON gestao_escolar.school_timetable_entries USING btree (tenant_id, class_id, activo);
CREATE INDEX IF NOT EXISTS idx_timetable_room ON gestao_escolar.school_timetable_entries USING btree (tenant_id, sala, dia_semana, time_slot_id);
CREATE INDEX IF NOT EXISTS idx_timetable_teacher ON gestao_escolar.school_timetable_entries USING btree (tenant_id, teacher_id, activo);
CREATE INDEX IF NOT EXISTS idx_transcript_subjects ON gestao_escolar.school_transcript_subjects USING btree (transcript_id, subject_id);
CREATE INDEX IF NOT EXISTS idx_transcript_subjects_tenant ON gestao_escolar.school_transcript_subjects USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_transcripts_student ON gestao_escolar.school_academic_transcripts USING btree (tenant_id, student_id);
CREATE INDEX IF NOT EXISTS portal_sessions_expira_em_idx ON gestao_escolar.portal_sessions USING btree (expira_em);
CREATE INDEX IF NOT EXISTS portal_sessions_student_id_idx ON gestao_escolar.portal_sessions USING btree (student_id);
CREATE INDEX IF NOT EXISTS portal_sessions_token_hash_idx ON gestao_escolar.portal_sessions USING btree (token_hash);
CREATE UNIQUE INDEX IF NOT EXISTS school_guardians_portal_email_tenant_uidx ON gestao_escolar.school_guardians USING btree (tenant_id, portal_email) WHERE (portal_email IS NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS school_students_portal_email_tenant_uidx ON gestao_escolar.school_students USING btree (tenant_id, portal_email) WHERE (portal_email IS NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS uq_school_attendance_entry ON gestao_escolar.school_attendance USING btree (tenant_id, class_id, student_id, attendance_date, COALESCE(subject_id, (0)::bigint));
CREATE UNIQUE INDEX IF NOT EXISTS uq_school_student_class_year ON gestao_escolar.school_enrollments USING btree (student_id, class_id, COALESCE(school_year_id, (0)::bigint));
CREATE INDEX IF NOT EXISTS idx_tax_certificates_entity ON impostos.tax_certificates USING btree (tenant_id, entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_tax_certificates_validade ON impostos.tax_certificates USING btree (tenant_id, validade) WHERE ativo;
CREATE INDEX IF NOT EXISTS idx_tax_exemptions_active ON impostos.tax_exemptions USING btree (tenant_id, entity_type, entity_id, data_inicio, validade) WHERE ativo;
CREATE INDEX IF NOT EXISTS idx_tax_exemptions_entity ON impostos.tax_exemptions USING btree (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_tax_exemptions_tenant ON impostos.tax_exemptions USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_regimes_tenant ON impostos.tax_regimes USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_return_lines_reference ON impostos.tax_return_lines USING btree (referencia_tipo, referencia_id);
CREATE INDEX IF NOT EXISTS idx_tax_return_lines_return ON impostos.tax_return_lines USING btree (tax_return_id);
CREATE INDEX IF NOT EXISTS idx_tax_returns_tenant ON impostos.tax_returns USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_rules_tax ON impostos.tax_rules USING btree (tax_id, valor_minimo);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_period ON impostos.tax_transactions USING btree (fiscal_period_id);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_ref ON impostos.tax_transactions USING btree (referencia_tipo, referencia_id);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_tax ON impostos.tax_transactions USING btree (tax_id);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_tenant ON impostos.tax_transactions USING btree (tenant_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_group ON impostos.taxes USING btree (tenant_id, tax_group_id);
CREATE INDEX IF NOT EXISTS idx_taxes_tenant ON impostos.taxes USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_wtt_tenant ON impostos.withholding_tax_transactions USING btree (tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_tax_regime_principal ON impostos.tax_regimes USING btree (tenant_id) WHERE (principal AND ativo);
CREATE UNIQUE INDEX IF NOT EXISTS uq_tax_returns_original ON impostos.tax_returns USING btree (tenant_id, periodo, tipo) WHERE (substitui_id IS NULL);
CREATE UNIQUE INDEX IF NOT EXISTS uq_tax_returns_substituicao ON impostos.tax_returns USING btree (substitui_id) WHERE (substitui_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_logistics_drivers_tenant ON logistica.logistics_drivers USING btree (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_logistics_routes_tenant ON logistica.logistics_routes USING btree (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_logistics_shipments_tenant_status ON logistica.logistics_shipments USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_logistics_tracking_events_tenant ON logistica.logistics_tracking_events USING btree (tenant_id, event_time DESC);
CREATE INDEX IF NOT EXISTS idx_logistics_vehicles_tenant ON logistica.logistics_vehicles USING btree (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_pair ON multi_moeda.exchange_rates USING btree (tenant_id, base_currency_id, quote_currency_id, effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_tenant_date ON multi_moeda.exchange_rates USING btree (tenant_id, effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_tenant_currencies_tenant ON multi_moeda.tenant_currencies USING btree (tenant_id, is_base);
CREATE INDEX IF NOT EXISTS idx_notification_channels_tenant ON notifications.notification_channels USING btree (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_notification_messages_tenant_status ON notifications.notification_messages USING btree (tenant_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_templates_tenant ON notifications.notification_templates USING btree (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON notifications.push_tokens USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_pessoa_contatos_pessoa ON pessoas.pessoa_contatos USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_pessoa_enderecos_pessoa ON pessoas.pessoa_enderecos USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_pessoa_relacoes_pessoa ON pessoas.pessoa_relacoes USING btree (tenant_id, pessoa_id);
CREATE INDEX IF NOT EXISTS idx_pessoa_relacoes_relacionada ON pessoas.pessoa_relacoes USING btree (tenant_id, pessoa_relacionada_id);
CREATE INDEX IF NOT EXISTS idx_pos_catalog_items_tenant ON pos.pos_catalog_items USING btree (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_pos_sale_items_sale ON pos.pos_sale_items USING btree (pos_sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_sale_payments_sale ON pos.pos_sale_payments USING btree (pos_sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_sales_session ON pos.pos_sales USING btree (pos_session_id);
CREATE INDEX IF NOT EXISTS idx_pos_sales_tenant ON pos.pos_sales USING btree (tenant_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pos_sessions_tenant ON pos.pos_sessions USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_pos_terminals_tenant ON pos.pos_terminals USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_attribute_values_product_id ON produtos.product_attribute_values USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_barcodes_product ON produtos.product_barcodes USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_barcodes_product_id ON produtos.product_barcodes USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_brands_tenant ON produtos.product_brands USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_brands_tenant_id ON produtos.product_brands USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_parent ON produtos.product_categories USING btree (tenant_id, parent_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_tenant ON produtos.product_categories USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_tenant_id ON produtos.product_categories USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_discounts_product_active ON produtos.product_discounts USING btree (product_id, ativo);
CREATE INDEX IF NOT EXISTS idx_product_discounts_product_id ON produtos.product_discounts USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_images_product_id ON produtos.product_images USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_kit_items_kit_id ON produtos.product_kit_items USING btree (product_kit_id);
CREATE INDEX IF NOT EXISTS idx_product_kits_product_id ON produtos.product_kits USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_prices_product ON produtos.product_prices USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_prices_product_active ON produtos.product_prices USING btree (product_id, ativo);
CREATE INDEX IF NOT EXISTS idx_product_prices_product_id ON produtos.product_prices USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_subcategories_category_id ON produtos.product_subcategories USING btree (product_category_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_links_product_id ON produtos.product_tag_links USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_units_tenant ON produtos.product_units USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_units_tenant_id ON produtos.product_units USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product ON produtos.product_variants USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON produtos.product_variants USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product_sku ON produtos.product_variants USING btree (product_id, sku);
CREATE INDEX IF NOT EXISTS idx_products_tenant ON produtos.products USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_products_tenant_id ON produtos.products USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_tenant ON produtos.warehouses USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_tenant_id ON produtos.warehouses USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversas_tenant ON public.chat_conversas USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_chat_msg_autor ON public.chat_mensagens USING btree (autor_id);
CREATE INDEX IF NOT EXISTS idx_chat_msg_conversa ON public.chat_mensagens USING btree (conversa_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_part_user ON public.chat_participantes USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_comunicados_tenant ON public.comunicados USING btree (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notif_colab_nao_lida ON public.notif_colaborador USING btree (user_id) WHERE (NOT lida);
CREATE INDEX IF NOT EXISTS idx_notif_colab_user ON public.notif_colaborador USING btree (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_candidato_sessions_candidato ON recrutamento.candidato_sessions USING btree (candidato_id);
CREATE INDEX IF NOT EXISTS idx_candidato_sessions_token ON recrutamento.candidato_sessions USING btree (token_hash);
CREATE INDEX IF NOT EXISTS idx_candidatos_pessoa_id ON recrutamento.candidatos USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_candidatos_tenant_id ON recrutamento.candidatos USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_candidatos_user_id ON recrutamento.candidatos USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_candidatura_campos_custom_tenant ON recrutamento.candidatura_campos_custom USING btree (tenant_id, ativo, ordem);
CREATE INDEX IF NOT EXISTS idx_candidatura_notas_candidatura_id ON recrutamento.candidatura_notas USING btree (candidatura_id);
CREATE INDEX IF NOT EXISTS idx_candidatura_respostas_campo ON recrutamento.candidatura_respostas_vaga USING btree (campo_id);
CREATE INDEX IF NOT EXISTS idx_candidatura_respostas_vaga ON recrutamento.candidatura_respostas_vaga USING btree (candidatura_id);
CREATE INDEX IF NOT EXISTS idx_candidatura_valores_campo ON recrutamento.candidatura_valores_custom USING btree (campo_id);
CREATE INDEX IF NOT EXISTS idx_candidatura_valores_candidatura ON recrutamento.candidatura_valores_custom USING btree (candidatura_id);
CREATE INDEX IF NOT EXISTS idx_candidaturas_candidato_id ON recrutamento.candidaturas USING btree (candidato_id);
CREATE INDEX IF NOT EXISTS idx_candidaturas_codigo_acompanhamento ON recrutamento.candidaturas USING btree (codigo_acompanhamento);
CREATE INDEX IF NOT EXISTS idx_candidaturas_email ON recrutamento.candidaturas USING btree (email);
CREATE INDEX IF NOT EXISTS idx_candidaturas_estado ON recrutamento.candidaturas USING btree (estado);
CREATE INDEX IF NOT EXISTS idx_candidaturas_rh_funcionario_id ON recrutamento.candidaturas USING btree (rh_funcionario_id);
CREATE INDEX IF NOT EXISTS idx_candidaturas_tenant_id ON recrutamento.candidaturas USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_candidaturas_vaga_id ON recrutamento.candidaturas USING btree (vaga_id);
CREATE INDEX IF NOT EXISTS idx_contactos_lido ON recrutamento.contactos USING btree (lido);
CREATE INDEX IF NOT EXISTS idx_contactos_tenant_id ON recrutamento.contactos USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_vaga_campos_tenant ON recrutamento.vaga_campos USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_vaga_campos_vaga ON recrutamento.vaga_campos USING btree (vaga_id, ativo, ordem);
CREATE INDEX IF NOT EXISTS idx_vagas_ativa ON recrutamento.vagas USING btree (ativa);
CREATE INDEX IF NOT EXISTS idx_vagas_cargo_id ON recrutamento.vagas USING btree (cargo_id);
CREATE INDEX IF NOT EXISTS idx_vagas_tenant_id ON recrutamento.vagas USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_adiantamentos_funcionario ON rh.adiantamentos USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_adiantamentos_tenant ON rh.adiantamentos USING btree (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_auditoria_assiduidade_operacao ON rh.auditoria_assiduidade USING btree (operacao);
CREATE INDEX IF NOT EXISTS idx_auditoria_assiduidade_registo ON rh.auditoria_assiduidade USING btree (tabela, registo_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_assiduidade_tenant_data ON rh.auditoria_assiduidade USING btree (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_ausencias_estado ON rh.ausencias USING btree (estado);
CREATE INDEX IF NOT EXISTS idx_ausencias_funcionario_id ON rh.ausencias USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_ausencias_tenant_id ON rh.ausencias USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_ausencias_tipo_id ON rh.ausencias USING btree (tipo_id);
CREATE INDEX IF NOT EXISTS idx_avaliacao_criterios_avaliacao_id ON rh.avaliacao_criterios USING btree (avaliacao_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_funcionario_id ON rh.avaliacoes USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_periodo_id ON rh.avaliacoes USING btree (periodo_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_tenant_id ON rh.avaliacoes USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_beneficios_tenant_id ON rh.beneficios USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_cargos_tenant_id ON rh.cargos USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_componentes_salariais_tenant_id ON rh.componentes_salariais USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_contactos_emergencia_funcionario_id ON rh.contactos_emergencia USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_contactos_emergencia_pessoa_id ON rh.contactos_emergencia USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_contratos_funcionario_id ON rh.contratos USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_contratos_tenant_id ON rh.contratos USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_correcoes_evento_evento_id ON rh.correcoes_evento USING btree (evento_id);
CREATE INDEX IF NOT EXISTS idx_correcoes_evento_funcionario ON rh.correcoes_evento USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_correcoes_evento_tenant_estado ON rh.correcoes_evento USING btree (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_criterios_avaliacao_tenant_id ON rh.criterios_avaliacao USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_documentos_funcionario_funcionario_id ON rh.documentos_funcionario USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_emprestimos_funcionario ON rh.emprestimos USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_emprestimos_tenant ON rh.emprestimos USING btree (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_estado ON rh.eventos_assiduidade USING btree (estado);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_func_data ON rh.eventos_assiduidade USING btree (funcionario_id, data_referencia, ocorrido_em);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_metodo ON rh.eventos_assiduidade USING btree (metodo_id);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_origem ON rh.eventos_assiduidade USING btree (origem);
CREATE INDEX IF NOT EXISTS idx_eventos_assiduidade_tenant_data ON rh.eventos_assiduidade USING btree (tenant_id, data_referencia);
CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_bank_account ON rh.folhas_pagamento USING btree (tenant_id, bank_account_id);
CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_cash_register ON rh.folhas_pagamento USING btree (tenant_id, cash_register_id);
CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_journal_entry ON rh.folhas_pagamento USING btree (tenant_id, journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_movement ON rh.folhas_pagamento USING btree (tenant_id, movement_id);
CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_tenant_id ON rh.folhas_pagamento USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_formacoes_tenant_id ON rh.formacoes USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_funcionario_beneficios_funcionario_id ON rh.funcionario_beneficios USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_funcionario_componentes_funcionario_id ON rh.funcionario_componentes_salariais USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_funcionario_formacoes_formacao_id ON rh.funcionario_formacoes USING btree (formacao_id);
CREATE INDEX IF NOT EXISTS idx_funcionario_formacoes_funcionario_id ON rh.funcionario_formacoes USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_funcionario_horarios_funcionario_id ON rh.funcionario_horarios USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_funcionario_horarios_horario_id ON rh.funcionario_horarios USING btree (horario_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_cargo_id ON rh.funcionarios USING btree (cargo_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_centro_custo ON rh.funcionarios USING btree (tenant_id, centro_custo_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_horario_id ON rh.funcionarios USING btree (horario_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_pessoa_id ON rh.funcionarios USING btree (pessoa_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_tenant_id ON rh.funcionarios USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_unit_id ON rh.funcionarios USING btree (unit_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_user_id ON rh.funcionarios USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_historico_salarial_funcionario_id ON rh.historico_salarial USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_horarios_dias_horario_id ON rh.horarios_dias USING btree (horario_id);
CREATE INDEX IF NOT EXISTS idx_horarios_trabalho_tenant_id ON rh.horarios_trabalho USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_irps_escaloes_tenant ON rh.irps_escaloes USING btree (tenant_id, ano_fiscal);
CREATE INDEX IF NOT EXISTS idx_justif_funcionario ON rh.justificacoes USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_justif_tenant_estado ON rh.justificacoes USING btree (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_metodos_marcacao_tenant_id ON rh.metodos_marcacao USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_periodos_avaliacao_tenant_id ON rh.periodos_avaliacao USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_presencas_funcionario_id ON rh.presencas USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_presencas_tenant_data ON rh.presencas USING btree (tenant_id, data);
CREATE INDEX IF NOT EXISTS idx_processos_disciplinares_estado ON rh.processos_disciplinares USING btree (estado);
CREATE INDEX IF NOT EXISTS idx_processos_disciplinares_funcionario_id ON rh.processos_disciplinares USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_processos_disciplinares_tenant_id ON rh.processos_disciplinares USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_recibo_vencimento_itens_recibo_id ON rh.recibo_vencimento_itens USING btree (recibo_id);
CREATE INDEX IF NOT EXISTS idx_recibos_centro_custo ON rh.recibos_vencimento USING btree (tenant_id, centro_custo_id);
CREATE INDEX IF NOT EXISTS idx_recibos_vencimento_folha_id ON rh.recibos_vencimento USING btree (folha_id);
CREATE INDEX IF NOT EXISTS idx_recibos_vencimento_funcionario_id ON rh.recibos_vencimento USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_recibos_vencimento_tenant_id ON rh.recibos_vencimento USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_regras_assiduidade_ambito_entidade ON rh.regras_assiduidade USING btree (ambito, entidade_id);
CREATE INDEX IF NOT EXISTS idx_regras_assiduidade_tenant_tipo ON rh.regras_assiduidade USING btree (tenant_id, tipo_regra_id);
CREATE INDEX IF NOT EXISTS idx_resultados_diarios_func_data ON rh.resultados_diarios USING btree (funcionario_id, data_referencia);
CREATE INDEX IF NOT EXISTS idx_resultados_diarios_tenant_data ON rh.resultados_diarios USING btree (tenant_id, data_referencia);
CREATE INDEX IF NOT EXISTS idx_resultados_periodos_func_ano ON rh.resultados_periodos USING btree (funcionario_id, ano, numero);
CREATE INDEX IF NOT EXISTS idx_saldos_ausencia_funcionario_id ON rh.saldos_ausencia USING btree (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_tipos_ausencia_tenant_id ON rh.tipos_ausencia USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tipos_evento_tenant_id ON rh.tipos_evento USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_unidades_organizacionais_parent_id ON rh.unidades_organizacionais USING btree (parent_id);
CREATE INDEX IF NOT EXISTS idx_unidades_organizacionais_tenant_id ON rh.unidades_organizacionais USING btree (tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_funcionarios_tenant_numero ON rh.funcionarios USING btree (tenant_id, numero_funcionario) WHERE ((numero_funcionario IS NOT NULL) AND ((numero_funcionario)::text <> ''::text));
CREATE INDEX IF NOT EXISTS idx_approval_decisions_request ON saas.approval_decisions USING btree (request_id);
CREATE INDEX IF NOT EXISTS idx_approval_flows_tenant_feature ON saas.approval_flows USING btree (tenant_id, feature) WHERE (ativo = true);
CREATE INDEX IF NOT EXISTS idx_approval_requests_entidade ON saas.approval_requests USING btree (entidade, entidade_id);
CREATE INDEX IF NOT EXISTS idx_approval_requests_flow ON saas.approval_requests USING btree (flow_id);
CREATE INDEX IF NOT EXISTS idx_approval_requests_tenant_estado ON saas.approval_requests USING btree (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_tenant_dominios_tenant_id ON saas.tenant_dominios USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_modules_tenant_id ON saas.tenant_modules USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_status ON saas.tenant_subscriptions USING btree (status);
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_tenant_id ON saas.tenant_subscriptions USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenants_company_id ON saas.tenants USING btree (company_id);
CREATE INDEX IF NOT EXISTS idx_tenants_plano_id ON saas.tenants USING btree (plano_id);
CREATE INDEX IF NOT EXISTS idx_tenants_status ON saas.tenants USING btree (status);
CREATE UNIQUE INDEX IF NOT EXISTS uq_tenant_dominios_canonico ON saas.tenant_dominios USING btree (tenant_id) WHERE canonico;
CREATE INDEX IF NOT EXISTS idx_security_ip_allowlist_tenant ON seguranca.security_ip_allowlist USING btree (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_security_mfa_enrollments_tenant ON seguranca.security_mfa_enrollments USING btree (tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_security_policies_tenant ON seguranca.security_policies USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_defaults_tenant ON sistema_configuracao.tenant_defaults USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_document_settings_tenant ON sistema_configuracao.tenant_document_settings USING btree (tenant_id, modulo);
CREATE INDEX IF NOT EXISTS idx_tenant_feature_flags_tenant ON sistema_configuracao.tenant_feature_flags USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_integrations_tenant ON sistema_configuracao.tenant_integrations USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_alerts_tenant ON stock.stock_alerts USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_alerts_tenant_status ON stock.stock_alerts USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_stock_batches_expiry ON stock.stock_batches USING btree (expiry_date);
CREATE INDEX IF NOT EXISTS idx_stock_counts_tenant_status ON stock.stock_counts USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_stock_items_product ON stock.stock_items USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_stock_items_product_warehouse ON stock.stock_items USING btree (tenant_id, product_id, warehouse_id);
CREATE INDEX IF NOT EXISTS idx_stock_items_tenant ON stock.stock_items USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_date ON stock.stock_movements USING btree (tenant_id, movement_date);
CREATE INDEX IF NOT EXISTS idx_stock_movements_item ON stock.stock_movements USING btree (stock_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_tenant ON stock.stock_movements USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_reservations_tenant_status ON stock.stock_reservations USING btree (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_stock_transfers_tenant ON stock.stock_transfers USING btree (tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_stock_count_items ON stock.stock_count_items USING btree (stock_count_id, stock_item_id);
CREATE INDEX IF NOT EXISTS idx_tarefas_cartoes_lista ON tarefas.cartoes USING btree (lista_id, posicao);
CREATE INDEX IF NOT EXISTS idx_tarefas_listas_quadro ON tarefas.listas USING btree (quadro_id, posicao);
CREATE INDEX IF NOT EXISTS idx_tarefas_quadros_tenant ON tarefas.quadros USING btree (tenant_id, arquivado);
CREATE INDEX IF NOT EXISTS idx_treasury_movements_tenant_date ON tesouraria.movements USING btree (tenant_id, data_movimento DESC);
CREATE INDEX IF NOT EXISTS idx_treasury_reconciliations_tenant_status ON tesouraria.reconciliations USING btree (tenant_id, status, periodo_fim DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON utilizadores.profiles USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_user_id ON utilizadores.user_activity USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_avatar_user_id ON utilizadores.user_avatar USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON utilizadores.user_devices USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_lida ON utilizadores.user_notifications USING btree (lida);
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON utilizadores.user_notifications USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_security_logs_user_id ON utilizadores.user_security_logs USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON utilizadores.user_settings USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_tokens_user_id ON utilizadores.user_tokens USING btree (user_id);
DROP TRIGGER IF EXISTS trg_remove_user_from_cartoes ON auth.users;
CREATE TRIGGER trg_remove_user_from_cartoes BEFORE DELETE ON auth.users FOR EACH ROW EXECUTE FUNCTION tarefas.fn_remove_user_from_cartoes();
DROP TRIGGER IF EXISTS tax_return_lines_immutable ON impostos.tax_return_lines;
CREATE TRIGGER tax_return_lines_immutable BEFORE INSERT OR DELETE OR UPDATE ON impostos.tax_return_lines FOR EACH ROW EXECUTE FUNCTION impostos.trg_tax_return_lines_immutable();
DROP TRIGGER IF EXISTS tax_returns_immutable ON impostos.tax_returns;
CREATE TRIGGER tax_returns_immutable BEFORE DELETE OR UPDATE ON impostos.tax_returns FOR EACH ROW EXECUTE FUNCTION impostos.trg_tax_return_immutable();
ALTER TABLE ONLY assinatura_digital.logs
    ADD CONSTRAINT logs_documento_id_fkey FOREIGN KEY (documento_id) REFERENCES assinatura_digital.documentos(id) ON DELETE CASCADE;
ALTER TABLE ONLY assinatura_digital.logs
    ADD CONSTRAINT logs_signatario_id_fkey FOREIGN KEY (signatario_id) REFERENCES assinatura_digital.signatarios(id);
ALTER TABLE ONLY assinatura_digital.signatarios
    ADD CONSTRAINT signatarios_documento_id_fkey FOREIGN KEY (documento_id) REFERENCES assinatura_digital.documentos(id) ON DELETE CASCADE;
ALTER TABLE ONLY assinatura_digital.signatarios
    ADD CONSTRAINT signatarios_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY assinatura_digital.versoes_assinadas
    ADD CONSTRAINT versoes_assinadas_documento_id_fkey FOREIGN KEY (documento_id) REFERENCES assinatura_digital.documentos(id) ON DELETE CASCADE;
ALTER TABLE ONLY assinatura_digital.versoes_assinadas
    ADD CONSTRAINT versoes_assinadas_signatario_id_fkey FOREIGN KEY (signatario_id) REFERENCES assinatura_digital.signatarios(id);
ALTER TABLE ONLY assinaturas.subscription_invoices
    ADD CONSTRAINT fk_subscription_invoices_subscription FOREIGN KEY (subscription_id) REFERENCES assinaturas.subscriptions(id) ON DELETE CASCADE;
ALTER TABLE ONLY assinaturas.subscription_usage
    ADD CONSTRAINT fk_subscription_usage_subscription FOREIGN KEY (subscription_id) REFERENCES assinaturas.subscriptions(id) ON DELETE CASCADE;
ALTER TABLE ONLY assinaturas.subscriptions
    ADD CONSTRAINT fk_subscriptions_plan FOREIGN KEY (plan_id) REFERENCES assinaturas.subscription_plans(id) ON DELETE RESTRICT;
ALTER TABLE ONLY auth.audit_logs
    ADD CONSTRAINT audit_logs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE SET NULL;
ALTER TABLE ONLY auth.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY auth.api_keys
    ADD CONSTRAINT fk_api_keys_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY auth.api_keys
    ADD CONSTRAINT fk_api_keys_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY auth.cargos
    ADD CONSTRAINT fk_cargos_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY auth.email_verifications
    ADD CONSTRAINT fk_email_verifications_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY auth.login_history
    ADD CONSTRAINT fk_login_history_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY auth.password_resets
    ADD CONSTRAINT fk_password_resets_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY auth.memberships
    ADD CONSTRAINT memberships_cargo_id_fkey FOREIGN KEY (cargo_id) REFERENCES auth.cargos(id) ON DELETE SET NULL;
ALTER TABLE ONLY auth.memberships
    ADD CONSTRAINT memberships_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY auth.memberships
    ADD CONSTRAINT memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY auth.permissoes_diretas
    ADD CONSTRAINT permissoes_diretas_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY auth.permissoes_diretas
    ADD CONSTRAINT permissoes_diretas_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY auth.superadmin_ip_allowlist
    ADD CONSTRAINT superadmin_ip_allowlist_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY auth.superadmin_security_settings
    ADD CONSTRAINT superadmin_security_settings_atualizado_por_fkey FOREIGN KEY (atualizado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES autorizacao.permissions(id) ON DELETE CASCADE;
ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES autorizacao.roles(id) ON DELETE CASCADE;
ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES autorizacao.roles(id) ON DELETE CASCADE;
ALTER TABLE ONLY centros_custo.cost_center_allocations
    ADD CONSTRAINT fk_cost_center_allocations_center FOREIGN KEY (cost_center_id) REFERENCES centros_custo.cost_centers(id) ON DELETE RESTRICT;
ALTER TABLE ONLY centros_custo.cost_center_budgets
    ADD CONSTRAINT fk_cost_center_budgets_center FOREIGN KEY (cost_center_id) REFERENCES centros_custo.cost_centers(id) ON DELETE CASCADE;
ALTER TABLE ONLY centros_custo.cost_centers
    ADD CONSTRAINT fk_cost_centers_parent FOREIGN KEY (parent_id) REFERENCES centros_custo.cost_centers(id) ON DELETE SET NULL;
ALTER TABLE ONLY clientes.customer_contacts
    ADD CONSTRAINT customer_contacts_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY clientes.customers
    ADD CONSTRAINT customers_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY clientes.customer_addresses
    ADD CONSTRAINT fk_customer_addresses_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_balances
    ADD CONSTRAINT fk_customer_balances_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_contacts
    ADD CONSTRAINT fk_customer_contacts_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_credit_limits
    ADD CONSTRAINT fk_customer_credit_limits_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_discounts
    ADD CONSTRAINT fk_customer_discounts_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_documents
    ADD CONSTRAINT fk_customer_documents_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_history
    ADD CONSTRAINT fk_customer_history_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_notes
    ADD CONSTRAINT fk_customer_notes_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_payments
    ADD CONSTRAINT fk_customer_payments_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_tag_links
    ADD CONSTRAINT fk_customer_tag_links_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customer_tag_links
    ADD CONSTRAINT fk_customer_tag_links_tag FOREIGN KEY (customer_tag_id) REFERENCES clientes.customer_tags(id) ON DELETE CASCADE;
ALTER TABLE ONLY clientes.customers
    ADD CONSTRAINT fk_customers_group FOREIGN KEY (customer_group_id) REFERENCES clientes.customer_groups(id) ON DELETE SET NULL;
ALTER TABLE ONLY compras.goods_receipt_items
    ADD CONSTRAINT fk_goods_receipt_items_order_item FOREIGN KEY (purchase_order_item_id) REFERENCES compras.purchase_order_items(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.goods_receipt_items
    ADD CONSTRAINT fk_goods_receipt_items_receipt FOREIGN KEY (goods_receipt_id) REFERENCES compras.goods_receipts(id) ON DELETE CASCADE;
ALTER TABLE ONLY compras.goods_receipts
    ADD CONSTRAINT fk_goods_receipts_order FOREIGN KEY (purchase_order_id) REFERENCES compras.purchase_orders(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.goods_receipts
    ADD CONSTRAINT fk_goods_receipts_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_order_items
    ADD CONSTRAINT fk_purchase_order_items_order FOREIGN KEY (purchase_order_id) REFERENCES compras.purchase_orders(id) ON DELETE CASCADE;
ALTER TABLE ONLY compras.purchase_orders
    ADD CONSTRAINT fk_purchase_orders_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_receipt_item FOREIGN KEY (goods_receipt_item_id) REFERENCES compras.goods_receipt_items(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_return FOREIGN KEY (purchase_return_id) REFERENCES compras.purchase_returns(id) ON DELETE CASCADE;
ALTER TABLE ONLY compras.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_receipt FOREIGN KEY (goods_receipt_id) REFERENCES compras.goods_receipts(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.supplier_addresses
    ADD CONSTRAINT fk_supplier_addresses_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE CASCADE;
ALTER TABLE ONLY compras.supplier_contacts
    ADD CONSTRAINT fk_supplier_contacts_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE CASCADE;
ALTER TABLE ONLY compras.suppliers
    ADD CONSTRAINT fk_suppliers_group FOREIGN KEY (supplier_group_id) REFERENCES compras.supplier_groups(id) ON DELETE SET NULL;
ALTER TABLE ONLY compras.purchase_invoice_items
    ADD CONSTRAINT purchase_invoice_items_purchase_invoice_id_fkey FOREIGN KEY (purchase_invoice_id) REFERENCES compras.purchase_invoices(id) ON DELETE CASCADE;
ALTER TABLE ONLY compras.purchase_invoice_items
    ADD CONSTRAINT purchase_invoice_items_purchase_order_item_id_fkey FOREIGN KEY (purchase_order_item_id) REFERENCES compras.purchase_order_items(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_goods_receipt_id_fkey FOREIGN KEY (goods_receipt_id) REFERENCES compras.goods_receipts(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES compras.purchase_orders(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_orders
    ADD CONSTRAINT purchase_orders_purchase_request_id_fkey FOREIGN KEY (purchase_request_id) REFERENCES compras.purchase_requests(id);
ALTER TABLE ONLY compras.purchase_payment_items
    ADD CONSTRAINT purchase_payment_items_purchase_invoice_id_fkey FOREIGN KEY (purchase_invoice_id) REFERENCES compras.purchase_invoices(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_payment_items
    ADD CONSTRAINT purchase_payment_items_purchase_payment_id_fkey FOREIGN KEY (purchase_payment_id) REFERENCES compras.purchase_payments(id) ON DELETE CASCADE;
ALTER TABLE ONLY compras.purchase_payments
    ADD CONSTRAINT purchase_payments_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;
ALTER TABLE ONLY compras.purchase_request_items
    ADD CONSTRAINT purchase_request_items_purchase_request_id_fkey FOREIGN KEY (purchase_request_id) REFERENCES compras.purchase_requests(id) ON DELETE CASCADE;
ALTER TABLE ONLY contabilidade.chart_of_accounts
    ADD CONSTRAINT chart_of_accounts_account_type_id_fkey FOREIGN KEY (account_type_id) REFERENCES contabilidade.account_types(id);
ALTER TABLE ONLY contabilidade.fiscal_periods
    ADD CONSTRAINT fiscal_periods_fiscal_year_id_fkey FOREIGN KEY (fiscal_year_id) REFERENCES contabilidade.fiscal_years(id);
ALTER TABLE ONLY contabilidade.accounting_budgets
    ADD CONSTRAINT fk_accounting_budgets_account FOREIGN KEY (chart_account_id) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY contabilidade.accounting_budgets
    ADD CONSTRAINT fk_accounting_budgets_year FOREIGN KEY (fiscal_year_id) REFERENCES contabilidade.fiscal_years(id);
ALTER TABLE ONLY contabilidade.chart_of_accounts
    ADD CONSTRAINT fk_chart_parent FOREIGN KEY (parent_id) REFERENCES contabilidade.chart_of_accounts(id) ON DELETE SET NULL;
ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT fk_depreciation_entries_asset FOREIGN KEY (fixed_asset_id) REFERENCES contabilidade.fixed_assets(id);
ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT fk_depreciation_entries_journal FOREIGN KEY (journal_entry_id) REFERENCES contabilidade.journal_entries(id);
ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT fk_depreciation_entries_period FOREIGN KEY (fiscal_period_id) REFERENCES contabilidade.fiscal_periods(id);
ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT fk_fixed_assets_account FOREIGN KEY (chart_account_id) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT fk_fixed_assets_accum_account FOREIGN KEY (accumulated_depreciation_account_id) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT fk_fixed_assets_depr_account FOREIGN KEY (depreciation_account_id) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY contabilidade.journal_entries
    ADD CONSTRAINT fk_journal_entries_journal FOREIGN KEY (accounting_journal_id) REFERENCES contabilidade.accounting_journals(id) ON DELETE RESTRICT;
ALTER TABLE ONLY contabilidade.journal_entries
    ADD CONSTRAINT fk_journal_entries_period FOREIGN KEY (fiscal_period_id) REFERENCES contabilidade.fiscal_periods(id) ON DELETE RESTRICT;
ALTER TABLE ONLY contabilidade.journal_entry_lines
    ADD CONSTRAINT fk_journal_entry_lines_account FOREIGN KEY (account_id) REFERENCES contabilidade.chart_of_accounts(id) ON DELETE RESTRICT;
ALTER TABLE ONLY contabilidade.journal_entry_lines
    ADD CONSTRAINT fk_journal_entry_lines_entry FOREIGN KEY (journal_entry_id) REFERENCES contabilidade.journal_entries(id) ON DELETE CASCADE;
ALTER TABLE ONLY contabilidade.period_closing_checks
    ADD CONSTRAINT fk_period_closing_checks_closing FOREIGN KEY (period_closing_id) REFERENCES contabilidade.period_closings(id) ON DELETE CASCADE;
ALTER TABLE ONLY contabilidade.period_closings
    ADD CONSTRAINT fk_period_closings_period FOREIGN KEY (fiscal_period_id) REFERENCES contabilidade.fiscal_periods(id);
ALTER TABLE ONLY contabilidade.journal_entry_sequences
    ADD CONSTRAINT journal_entry_sequences_accounting_journal_id_fkey FOREIGN KEY (accounting_journal_id) REFERENCES contabilidade.accounting_journals(id) ON DELETE CASCADE;
ALTER TABLE ONLY crm.atividades
    ADD CONSTRAINT fk_atividades_lead FOREIGN KEY (lead_id) REFERENCES crm.leads(id) ON DELETE CASCADE;
ALTER TABLE ONLY crm.atividades
    ADD CONSTRAINT fk_atividades_oportunidade FOREIGN KEY (oportunidade_id) REFERENCES crm.oportunidades(id) ON DELETE CASCADE;
ALTER TABLE ONLY crm.oportunidades
    ADD CONSTRAINT fk_oportunidades_lead FOREIGN KEY (lead_id) REFERENCES crm.leads(id) ON DELETE SET NULL;
ALTER TABLE ONLY crm.leads
    ADD CONSTRAINT leads_responsavel_id_fkey FOREIGN KEY (responsavel_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY crm.oportunidades
    ADD CONSTRAINT oportunidades_responsavel_id_fkey FOREIGN KEY (responsavel_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY empresas.company_contacts
    ADD CONSTRAINT company_contacts_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY empresas.companies
    ADD CONSTRAINT fk_companies_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE RESTRICT;
ALTER TABLE ONLY empresas.company_addresses
    ADD CONSTRAINT fk_company_addresses_branch FOREIGN KEY (branch_id) REFERENCES empresas.company_branches(id) ON DELETE SET NULL;
ALTER TABLE ONLY empresas.company_addresses
    ADD CONSTRAINT fk_company_addresses_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;
ALTER TABLE ONLY empresas.company_banks
    ADD CONSTRAINT fk_company_banks_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;
ALTER TABLE ONLY empresas.company_branches
    ADD CONSTRAINT fk_company_branches_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;
ALTER TABLE ONLY empresas.company_contacts
    ADD CONSTRAINT fk_company_contacts_branch FOREIGN KEY (branch_id) REFERENCES empresas.company_branches(id) ON DELETE SET NULL;
ALTER TABLE ONLY empresas.company_contacts
    ADD CONSTRAINT fk_company_contacts_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;
ALTER TABLE ONLY empresas.company_documents
    ADD CONSTRAINT fk_company_documents_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;
ALTER TABLE ONLY empresas.company_licenses
    ADD CONSTRAINT fk_company_licenses_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;
ALTER TABLE ONLY empresas.company_settings
    ADD CONSTRAINT fk_company_settings_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;
ALTER TABLE ONLY empresas.company_tax_info
    ADD CONSTRAINT fk_company_tax_info_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;
ALTER TABLE ONLY empresas.company_users
    ADD CONSTRAINT fk_company_users_branch FOREIGN KEY (branch_id) REFERENCES empresas.company_branches(id) ON DELETE SET NULL;
ALTER TABLE ONLY empresas.company_users
    ADD CONSTRAINT fk_company_users_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;
ALTER TABLE ONLY empresas.company_users
    ADD CONSTRAINT fk_company_users_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY faturacao.credit_note_items
    ADD CONSTRAINT fk_credit_note_items_nc FOREIGN KEY (credit_note_id) REFERENCES faturacao.credit_notes(id) ON DELETE CASCADE;
ALTER TABLE ONLY faturacao.credit_notes
    ADD CONSTRAINT fk_credit_notes_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.credit_notes
    ADD CONSTRAINT fk_credit_notes_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.sales_deliveries
    ADD CONSTRAINT fk_deliveries_order FOREIGN KEY (sales_order_id) REFERENCES faturacao.sales_orders(id);
ALTER TABLE ONLY faturacao.sales_deliveries
    ADD CONSTRAINT fk_deliveries_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.sales_delivery_items
    ADD CONSTRAINT fk_delivery_items_delivery FOREIGN KEY (sales_delivery_id) REFERENCES faturacao.sales_deliveries(id) ON DELETE CASCADE;
ALTER TABLE ONLY faturacao.invoice_discounts
    ADD CONSTRAINT fk_invoice_discounts_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE CASCADE;
ALTER TABLE ONLY faturacao.invoice_items
    ADD CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE CASCADE;
ALTER TABLE ONLY faturacao.invoice_items
    ADD CONSTRAINT fk_invoice_items_tax_exemption FOREIGN KEY (tax_exemption_id) REFERENCES impostos.tax_exemptions(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.invoice_taxes
    ADD CONSTRAINT fk_invoice_taxes_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE CASCADE;
ALTER TABLE ONLY faturacao.invoices
    ADD CONSTRAINT fk_invoices_order FOREIGN KEY (sales_order_id) REFERENCES faturacao.sales_orders(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.invoices
    ADD CONSTRAINT fk_invoices_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.sales_order_items
    ADD CONSTRAINT fk_order_items_order FOREIGN KEY (sales_order_id) REFERENCES faturacao.sales_orders(id) ON DELETE CASCADE;
ALTER TABLE ONLY faturacao.sales_orders
    ADD CONSTRAINT fk_orders_quote FOREIGN KEY (sales_quote_id) REFERENCES faturacao.sales_quotes(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.sales_orders
    ADD CONSTRAINT fk_orders_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.sales_quote_items
    ADD CONSTRAINT fk_quote_items_quote FOREIGN KEY (sales_quote_id) REFERENCES faturacao.sales_quotes(id) ON DELETE CASCADE;
ALTER TABLE ONLY faturacao.sales_quotes
    ADD CONSTRAINT fk_quotes_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.invoice_receipts
    ADD CONSTRAINT fk_receipts_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id);
ALTER TABLE ONLY faturacao.invoice_receipts
    ADD CONSTRAINT fk_receipts_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.sales_return_items
    ADD CONSTRAINT fk_return_items_return FOREIGN KEY (sales_return_id) REFERENCES faturacao.sales_returns(id) ON DELETE CASCADE;
ALTER TABLE ONLY faturacao.sales_returns
    ADD CONSTRAINT fk_returns_cn FOREIGN KEY (credit_note_id) REFERENCES faturacao.credit_notes(id) ON DELETE SET NULL;
ALTER TABLE ONLY faturacao.sales_returns
    ADD CONSTRAINT fk_returns_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE SET NULL;
ALTER TABLE ONLY financeiro.accounts_payable
    ADD CONSTRAINT fk_ap_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;
ALTER TABLE ONLY financeiro.accounts_payable_payments
    ADD CONSTRAINT fk_ap_payments_ap FOREIGN KEY (accounts_payable_id) REFERENCES financeiro.accounts_payable(id) ON DELETE CASCADE;
ALTER TABLE ONLY financeiro.accounts_payable_payments
    ADD CONSTRAINT fk_ap_payments_payment FOREIGN KEY (payment_id) REFERENCES financeiro.payments(id);
ALTER TABLE ONLY financeiro.accounts_receivable
    ADD CONSTRAINT fk_ar_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;
ALTER TABLE ONLY financeiro.accounts_receivable_payments
    ADD CONSTRAINT fk_ar_payments_ar FOREIGN KEY (accounts_receivable_id) REFERENCES financeiro.accounts_receivable(id) ON DELETE CASCADE;
ALTER TABLE ONLY financeiro.accounts_receivable_payments
    ADD CONSTRAINT fk_ar_payments_payment FOREIGN KEY (payment_id) REFERENCES financeiro.payments(id);
ALTER TABLE ONLY financeiro.financial_budgets
    ADD CONSTRAINT fk_budgets_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE CASCADE;
ALTER TABLE ONLY financeiro.cash_flow_entries
    ADD CONSTRAINT fk_cashflow_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;
ALTER TABLE ONLY financeiro.financial_categories
    ADD CONSTRAINT fk_financial_categories_parent FOREIGN KEY (parent_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;
ALTER TABLE ONLY financeiro.payments
    ADD CONSTRAINT fk_payments_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;
ALTER TABLE ONLY financeiro.payments
    ADD CONSTRAINT fk_payments_method FOREIGN KEY (payment_method_id) REFERENCES financeiro.payment_methods(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_guardians
    ADD CONSTRAINT fk_guardian_client FOREIGN KEY (client_id) REFERENCES clientes.customers(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT fk_school_attendance_class FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT fk_school_attendance_student FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT fk_school_enrollments_class FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT fk_school_enrollments_student FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT fk_school_fees_enrollment FOREIGN KEY (enrollment_id) REFERENCES gestao_escolar.school_enrollments(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_financial_config
    ADD CONSTRAINT fk_school_fin_config_bank_account FOREIGN KEY (conta_bancaria_id) REFERENCES tesouraria.bank_accounts(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_financial_config
    ADD CONSTRAINT fk_school_fin_config_centro_custo FOREIGN KEY (centro_custo_id) REFERENCES centros_custo.cost_centers(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_guardians
    ADD CONSTRAINT fk_school_guardians_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_messages
    ADD CONSTRAINT fk_school_messages_created_by FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_students
    ADD CONSTRAINT fk_school_students_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT fk_school_teacher_assignments_teacher FOREIGN KEY (teacher_id) REFERENCES gestao_escolar.school_teachers(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_students
    ADD CONSTRAINT fk_student_client FOREIGN KEY (client_id) REFERENCES clientes.customers(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_teachers
    ADD CONSTRAINT fk_teacher_rh_employee FOREIGN KEY (rh_employee_id) REFERENCES rh.funcionarios(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.portal_sessions
    ADD CONSTRAINT portal_sessions_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_academic_config
    ADD CONSTRAINT school_academic_config_level_id_fkey FOREIGN KEY (level_id) REFERENCES gestao_escolar.school_levels(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_academic_transcripts
    ADD CONSTRAINT school_academic_transcripts_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_academic_transcripts
    ADD CONSTRAINT school_academic_transcripts_course_id_fkey FOREIGN KEY (course_id) REFERENCES gestao_escolar.school_courses(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_academic_transcripts
    ADD CONSTRAINT school_academic_transcripts_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES gestao_escolar.school_enrollments(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_academic_transcripts
    ADD CONSTRAINT school_academic_transcripts_level_id_fkey FOREIGN KEY (level_id) REFERENCES gestao_escolar.school_levels(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_academic_transcripts
    ADD CONSTRAINT school_academic_transcripts_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_academic_transcripts
    ADD CONSTRAINT school_academic_transcripts_series_id_fkey FOREIGN KEY (series_id) REFERENCES gestao_escolar.school_series(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_academic_transcripts
    ADD CONSTRAINT school_academic_transcripts_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT school_attendance_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES gestao_escolar.school_enrollments(id);
ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT school_attendance_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id);
ALTER TABLE ONLY gestao_escolar.school_calendar_events
    ADD CONSTRAINT school_calendar_events_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_calendar_events
    ADD CONSTRAINT school_calendar_events_event_type_id_fkey FOREIGN KEY (event_type_id) REFERENCES gestao_escolar.school_calendar_event_types(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_calendar_events
    ADD CONSTRAINT school_calendar_events_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_cargo_permissoes
    ADD CONSTRAINT school_cargo_permissoes_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_cargo_permissoes
    ADD CONSTRAINT school_cargo_permissoes_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_classes
    ADD CONSTRAINT school_classes_course_id_fkey FOREIGN KEY (course_id) REFERENCES gestao_escolar.school_courses(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_classes
    ADD CONSTRAINT school_classes_level_id_fkey FOREIGN KEY (level_id) REFERENCES gestao_escolar.school_levels(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_classes
    ADD CONSTRAINT school_classes_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);
ALTER TABLE ONLY gestao_escolar.school_classes
    ADD CONSTRAINT school_classes_series_id_fkey FOREIGN KEY (series_id) REFERENCES gestao_escolar.school_series(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_course_subject_terms
    ADD CONSTRAINT school_course_subject_terms_course_subject_id_fkey FOREIGN KEY (course_subject_id) REFERENCES gestao_escolar.school_course_subjects(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_course_subject_terms
    ADD CONSTRAINT school_course_subject_terms_term_id_fkey FOREIGN KEY (term_id) REFERENCES gestao_escolar.school_terms(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_course_subjects
    ADD CONSTRAINT school_course_subjects_course_id_fkey FOREIGN KEY (course_id) REFERENCES gestao_escolar.school_courses(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_course_subjects
    ADD CONSTRAINT school_course_subjects_level_id_fkey FOREIGN KEY (level_id) REFERENCES gestao_escolar.school_levels(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_course_subjects
    ADD CONSTRAINT school_course_subjects_series_id_fkey FOREIGN KEY (series_id) REFERENCES gestao_escolar.school_series(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_course_subjects
    ADD CONSTRAINT school_course_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_courses
    ADD CONSTRAINT school_courses_level_id_fkey FOREIGN KEY (level_id) REFERENCES gestao_escolar.school_levels(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_cycles
    ADD CONSTRAINT school_cycles_level_id_fkey FOREIGN KEY (level_id) REFERENCES gestao_escolar.school_levels(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT school_enrollments_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);
ALTER TABLE ONLY gestao_escolar.school_fee_generations
    ADD CONSTRAINT school_fee_generations_fee_plan_id_fkey FOREIGN KEY (fee_plan_id) REFERENCES gestao_escolar.school_fee_plans(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_fee_generations
    ADD CONSTRAINT school_fee_generations_gerado_por_fkey FOREIGN KEY (gerado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_fee_generations
    ADD CONSTRAINT school_fee_generations_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_fee_plans
    ADD CONSTRAINT school_fee_plans_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_fee_plans
    ADD CONSTRAINT school_fee_plans_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);
ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT school_fees_cancelado_por_fkey FOREIGN KEY (cancelado_por) REFERENCES auth.users(id);
ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT school_fees_fee_plan_id_fkey FOREIGN KEY (fee_plan_id) REFERENCES gestao_escolar.school_fee_plans(id);
ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT school_fees_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id);
ALTER TABLE ONLY gestao_escolar.school_grade_formulas
    ADD CONSTRAINT school_grade_formulas_course_id_fkey FOREIGN KEY (course_id) REFERENCES gestao_escolar.school_courses(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_grade_formulas
    ADD CONSTRAINT school_grade_formulas_level_id_fkey FOREIGN KEY (level_id) REFERENCES gestao_escolar.school_levels(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_grade_items
    ADD CONSTRAINT school_grade_items_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_grade_items
    ADD CONSTRAINT school_grade_items_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id);
ALTER TABLE ONLY gestao_escolar.school_grade_items
    ADD CONSTRAINT school_grade_items_term_id_fkey FOREIGN KEY (term_id) REFERENCES gestao_escolar.school_terms(id);
ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES gestao_escolar.school_enrollments(id);
ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_grade_item_id_fkey FOREIGN KEY (grade_item_id) REFERENCES gestao_escolar.school_grade_items(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_guardians
    ADD CONSTRAINT school_guardians_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_guardians
    ADD CONSTRAINT school_guardians_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_library_loans
    ADD CONSTRAINT school_library_loans_book_id_fkey FOREIGN KEY (book_id) REFERENCES gestao_escolar.school_books(id);
ALTER TABLE ONLY gestao_escolar.school_library_loans
    ADD CONSTRAINT school_library_loans_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id);
ALTER TABLE ONLY gestao_escolar.school_payments
    ADD CONSTRAINT school_payments_school_fee_id_fkey FOREIGN KEY (school_fee_id) REFERENCES gestao_escolar.school_fees(id);
ALTER TABLE ONLY gestao_escolar.school_payments
    ADD CONSTRAINT school_payments_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id);
ALTER TABLE ONLY gestao_escolar.school_series
    ADD CONSTRAINT school_series_cycle_id_fkey FOREIGN KEY (cycle_id) REFERENCES gestao_escolar.school_cycles(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_series
    ADD CONSTRAINT school_series_level_id_fkey FOREIGN KEY (level_id) REFERENCES gestao_escolar.school_levels(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_student_fee_discounts
    ADD CONSTRAINT school_student_fee_discounts_aprovado_por_fkey FOREIGN KEY (aprovado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_student_fee_discounts
    ADD CONSTRAINT school_student_fee_discounts_fee_plan_id_fkey FOREIGN KEY (fee_plan_id) REFERENCES gestao_escolar.school_fee_plans(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_student_fee_discounts
    ADD CONSTRAINT school_student_fee_discounts_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_student_incidents
    ADD CONSTRAINT school_student_incidents_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES gestao_escolar.school_enrollments(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_student_incidents
    ADD CONSTRAINT school_student_incidents_incident_type_id_fkey FOREIGN KEY (incident_type_id) REFERENCES gestao_escolar.school_incident_types(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_student_incidents
    ADD CONSTRAINT school_student_incidents_reported_by_fkey FOREIGN KEY (reported_by) REFERENCES auth.users(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_student_incidents
    ADD CONSTRAINT school_student_incidents_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_student_incidents
    ADD CONSTRAINT school_student_incidents_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_student_merits
    ADD CONSTRAINT school_student_merits_atribuido_por_fkey FOREIGN KEY (atribuido_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_student_merits
    ADD CONSTRAINT school_student_merits_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES gestao_escolar.school_enrollments(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_student_merits
    ADD CONSTRAINT school_student_merits_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_student_merits
    ADD CONSTRAINT school_student_merits_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_student_roles
    ADD CONSTRAINT school_student_roles_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_student_roles
    ADD CONSTRAINT school_student_roles_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_student_sanctions
    ADD CONSTRAINT school_student_sanctions_aplicado_por_fkey FOREIGN KEY (aplicado_por) REFERENCES auth.users(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_student_sanctions
    ADD CONSTRAINT school_student_sanctions_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES gestao_escolar.school_student_incidents(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_student_sanctions
    ADD CONSTRAINT school_student_sanctions_sanction_type_id_fkey FOREIGN KEY (sanction_type_id) REFERENCES gestao_escolar.school_sanction_types(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_students
    ADD CONSTRAINT school_students_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_subjects
    ADD CONSTRAINT school_subjects_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_tasks
    ADD CONSTRAINT school_tasks_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_tasks
    ADD CONSTRAINT school_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_tasks
    ADD CONSTRAINT school_tasks_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_tasks
    ADD CONSTRAINT school_tasks_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_tasks
    ADD CONSTRAINT school_tasks_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES gestao_escolar.school_teachers(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);
ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id);
ALTER TABLE ONLY gestao_escolar.school_teacher_roles
    ADD CONSTRAINT school_teacher_roles_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);
ALTER TABLE ONLY gestao_escolar.school_teachers
    ADD CONSTRAINT school_teachers_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_teachers
    ADD CONSTRAINT school_teachers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_terms
    ADD CONSTRAINT school_terms_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_terms
    ADD CONSTRAINT school_terms_level_id_fkey FOREIGN KEY (level_id) REFERENCES gestao_escolar.school_levels(id) ON DELETE SET NULL;
ALTER TABLE ONLY gestao_escolar.school_terms
    ADD CONSTRAINT school_terms_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_timetable_entries
    ADD CONSTRAINT school_timetable_entries_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_timetable_entries
    ADD CONSTRAINT school_timetable_entries_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_timetable_entries
    ADD CONSTRAINT school_timetable_entries_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_timetable_entries
    ADD CONSTRAINT school_timetable_entries_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES gestao_escolar.school_teachers(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_timetable_entries
    ADD CONSTRAINT school_timetable_entries_time_slot_id_fkey FOREIGN KEY (time_slot_id) REFERENCES gestao_escolar.school_time_slots(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_transcript_subjects
    ADD CONSTRAINT school_transcript_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id) ON DELETE RESTRICT;
ALTER TABLE ONLY gestao_escolar.school_transcript_subjects
    ADD CONSTRAINT school_transcript_subjects_transcript_id_fkey FOREIGN KEY (transcript_id) REFERENCES gestao_escolar.school_academic_transcripts(id) ON DELETE CASCADE;
ALTER TABLE ONLY gestao_escolar.school_years
    ADD CONSTRAINT school_years_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY impostos.tax_exemptions
    ADD CONSTRAINT fk_tax_exemptions_tax FOREIGN KEY (tax_id) REFERENCES impostos.taxes(id) ON DELETE CASCADE;
ALTER TABLE ONLY impostos.tax_return_lines
    ADD CONSTRAINT fk_tax_return_lines_return FOREIGN KEY (tax_return_id) REFERENCES impostos.tax_returns(id) ON DELETE CASCADE;
ALTER TABLE ONLY impostos.tax_returns
    ADD CONSTRAINT fk_tax_returns_substitui FOREIGN KEY (substitui_id) REFERENCES impostos.tax_returns(id) ON DELETE RESTRICT;
ALTER TABLE ONLY impostos.tax_rules
    ADD CONSTRAINT fk_tax_rules_tax FOREIGN KEY (tax_id) REFERENCES impostos.taxes(id) ON DELETE CASCADE;
ALTER TABLE ONLY impostos.tax_transactions
    ADD CONSTRAINT fk_tax_transactions_period FOREIGN KEY (fiscal_period_id) REFERENCES contabilidade.fiscal_periods(id);
ALTER TABLE ONLY impostos.tax_transactions
    ADD CONSTRAINT fk_tax_transactions_tax FOREIGN KEY (tax_id) REFERENCES impostos.taxes(id);
ALTER TABLE ONLY impostos.withholding_tax_transactions
    ADD CONSTRAINT fk_wtt_wt FOREIGN KEY (withholding_tax_id) REFERENCES impostos.withholding_taxes(id);
ALTER TABLE ONLY impostos.taxes
    ADD CONSTRAINT taxes_tax_group_id_fkey FOREIGN KEY (tax_group_id) REFERENCES impostos.tax_groups(id);
ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT fk_logistics_shipments_driver FOREIGN KEY (driver_id) REFERENCES logistica.logistics_drivers(id) ON DELETE SET NULL;
ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT fk_logistics_shipments_route FOREIGN KEY (logistics_route_id) REFERENCES logistica.logistics_routes(id) ON DELETE SET NULL;
ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT fk_logistics_shipments_vehicle FOREIGN KEY (vehicle_id) REFERENCES logistica.logistics_vehicles(id) ON DELETE SET NULL;
ALTER TABLE ONLY logistica.logistics_tracking_events
    ADD CONSTRAINT fk_logistics_tracking_events_shipment FOREIGN KEY (shipment_id) REFERENCES logistica.logistics_shipments(id) ON DELETE CASCADE;
ALTER TABLE ONLY multi_moeda.exchange_rates
    ADD CONSTRAINT fk_exchange_rates_base FOREIGN KEY (base_currency_id) REFERENCES multi_moeda.currencies(id) ON DELETE RESTRICT;
ALTER TABLE ONLY multi_moeda.exchange_rates
    ADD CONSTRAINT fk_exchange_rates_quote FOREIGN KEY (quote_currency_id) REFERENCES multi_moeda.currencies(id) ON DELETE RESTRICT;
ALTER TABLE ONLY multi_moeda.tenant_currencies
    ADD CONSTRAINT fk_tenant_currencies_currency FOREIGN KEY (currency_id) REFERENCES multi_moeda.currencies(id) ON DELETE RESTRICT;
ALTER TABLE ONLY notifications.notification_messages
    ADD CONSTRAINT fk_notification_messages_channel FOREIGN KEY (channel_id) REFERENCES notifications.notification_channels(id) ON DELETE SET NULL;
ALTER TABLE ONLY notifications.notification_messages
    ADD CONSTRAINT fk_notification_messages_template FOREIGN KEY (template_id) REFERENCES notifications.notification_templates(id) ON DELETE SET NULL;
ALTER TABLE ONLY notifications.push_tokens
    ADD CONSTRAINT fk_push_tokens_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY pessoas.pessoa_contatos
    ADD CONSTRAINT pessoa_contatos_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE CASCADE;
ALTER TABLE ONLY pessoas.pessoa_enderecos
    ADD CONSTRAINT pessoa_enderecos_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE CASCADE;
ALTER TABLE ONLY pessoas.pessoa_relacoes
    ADD CONSTRAINT pessoa_relacoes_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE CASCADE;
ALTER TABLE ONLY pessoas.pessoa_relacoes
    ADD CONSTRAINT pessoa_relacoes_pessoa_relacionada_id_fkey FOREIGN KEY (pessoa_relacionada_id) REFERENCES pessoas.pessoas(id) ON DELETE CASCADE;
ALTER TABLE ONLY pessoas.pessoa_relacoes
    ADD CONSTRAINT pessoa_relacoes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY pos.pos_catalog_items
    ADD CONSTRAINT fk_pos_catalog_items_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;
ALTER TABLE ONLY pos.pos_catalog_items
    ADD CONSTRAINT fk_pos_catalog_items_variant FOREIGN KEY (product_variant_id) REFERENCES produtos.product_variants(id) ON DELETE SET NULL;
ALTER TABLE ONLY pos.pos_sale_items
    ADD CONSTRAINT fk_pos_sale_items_sale FOREIGN KEY (pos_sale_id) REFERENCES pos.pos_sales(id) ON DELETE CASCADE;
ALTER TABLE ONLY pos.pos_sale_payments
    ADD CONSTRAINT fk_pos_sale_payments_sale FOREIGN KEY (pos_sale_id) REFERENCES pos.pos_sales(id) ON DELETE CASCADE;
ALTER TABLE ONLY pos.pos_sales
    ADD CONSTRAINT fk_pos_sales_session FOREIGN KEY (pos_session_id) REFERENCES pos.pos_sessions(id) ON DELETE RESTRICT;
ALTER TABLE ONLY pos.pos_sales
    ADD CONSTRAINT fk_pos_sales_terminal FOREIGN KEY (terminal_id) REFERENCES pos.pos_terminals(id) ON DELETE RESTRICT;
ALTER TABLE ONLY pos.pos_sessions
    ADD CONSTRAINT fk_pos_sessions_terminal FOREIGN KEY (terminal_id) REFERENCES pos.pos_terminals(id) ON DELETE RESTRICT;
ALTER TABLE ONLY pos.pos_terminals
    ADD CONSTRAINT fk_pos_terminals_caixa FOREIGN KEY (caixa_id) REFERENCES tesouraria.cash_registers(id) ON DELETE SET NULL;
ALTER TABLE ONLY pos.pos_terminals
    ADD CONSTRAINT fk_pos_terminals_warehouse FOREIGN KEY (warehouse_id) REFERENCES produtos.warehouses(id) ON DELETE SET NULL;
ALTER TABLE ONLY produtos.product_attribute_values
    ADD CONSTRAINT fk_product_attribute_values_attribute FOREIGN KEY (product_attribute_id) REFERENCES produtos.product_attributes(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_attribute_values
    ADD CONSTRAINT fk_product_attribute_values_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_attribute_values
    ADD CONSTRAINT fk_product_attribute_values_variant FOREIGN KEY (product_variant_id) REFERENCES produtos.product_variants(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_barcodes
    ADD CONSTRAINT fk_product_barcodes_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_categories
    ADD CONSTRAINT fk_product_categories_parent FOREIGN KEY (parent_id) REFERENCES produtos.product_categories(id) ON DELETE SET NULL;
ALTER TABLE ONLY produtos.product_discounts
    ADD CONSTRAINT fk_product_discounts_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_discounts
    ADD CONSTRAINT fk_product_discounts_variant FOREIGN KEY (product_variant_id) REFERENCES produtos.product_variants(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_images
    ADD CONSTRAINT fk_product_images_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_kit_items
    ADD CONSTRAINT fk_product_kit_items_kit FOREIGN KEY (product_kit_id) REFERENCES produtos.product_kits(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_kit_items
    ADD CONSTRAINT fk_product_kit_items_product FOREIGN KEY (item_product_id) REFERENCES produtos.products(id) ON DELETE RESTRICT;
ALTER TABLE ONLY produtos.product_kit_items
    ADD CONSTRAINT fk_product_kit_items_variant FOREIGN KEY (item_variant_id) REFERENCES produtos.product_variants(id) ON DELETE RESTRICT;
ALTER TABLE ONLY produtos.product_kits
    ADD CONSTRAINT fk_product_kits_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_prices
    ADD CONSTRAINT fk_product_prices_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_prices
    ADD CONSTRAINT fk_product_prices_variant FOREIGN KEY (product_variant_id) REFERENCES produtos.product_variants(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_subcategories
    ADD CONSTRAINT fk_product_subcategories_category FOREIGN KEY (product_category_id) REFERENCES produtos.product_categories(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_tag_links
    ADD CONSTRAINT fk_product_tag_links_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_tag_links
    ADD CONSTRAINT fk_product_tag_links_tag FOREIGN KEY (product_tag_id) REFERENCES produtos.product_tags(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.product_variants
    ADD CONSTRAINT fk_product_variants_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;
ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_brand FOREIGN KEY (product_brand_id) REFERENCES produtos.product_brands(id) ON DELETE SET NULL;
ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_category FOREIGN KEY (product_category_id) REFERENCES produtos.product_categories(id) ON DELETE SET NULL;
ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_subcategory FOREIGN KEY (product_subcategory_id) REFERENCES produtos.product_subcategories(id) ON DELETE SET NULL;
ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_unit FOREIGN KEY (product_unit_id) REFERENCES produtos.product_units(id) ON DELETE SET NULL;
ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_warehouse FOREIGN KEY (warehouse_default_id) REFERENCES produtos.warehouses(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.chat_conversas
    ADD CONSTRAINT chat_conversas_criado_por_fkey FOREIGN KEY (criado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.chat_mensagens
    ADD CONSTRAINT chat_mensagens_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.chat_mensagens
    ADD CONSTRAINT chat_mensagens_conversa_id_fkey FOREIGN KEY (conversa_id) REFERENCES public.chat_conversas(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.chat_participantes
    ADD CONSTRAINT chat_participantes_conversa_id_fkey FOREIGN KEY (conversa_id) REFERENCES public.chat_conversas(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.chat_participantes
    ADD CONSTRAINT chat_participantes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.comunicados
    ADD CONSTRAINT comunicados_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.comunicados_lidos
    ADD CONSTRAINT comunicados_lidos_comunicado_id_fkey FOREIGN KEY (comunicado_id) REFERENCES public.comunicados(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.comunicados_lidos
    ADD CONSTRAINT comunicados_lidos_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.notif_colaborador
    ADD CONSTRAINT notif_colaborador_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY recrutamento.candidato_sessions
    ADD CONSTRAINT candidato_sessions_candidato_id_fkey FOREIGN KEY (candidato_id) REFERENCES recrutamento.candidatos(id) ON DELETE CASCADE;
ALTER TABLE ONLY recrutamento.candidatos
    ADD CONSTRAINT candidatos_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY recrutamento.candidatura_respostas_vaga
    ADD CONSTRAINT candidatura_respostas_vaga_campo_id_fkey FOREIGN KEY (campo_id) REFERENCES recrutamento.vaga_campos(id) ON DELETE CASCADE;
ALTER TABLE ONLY recrutamento.candidatura_respostas_vaga
    ADD CONSTRAINT candidatura_respostas_vaga_candidatura_id_fkey FOREIGN KEY (candidatura_id) REFERENCES recrutamento.candidaturas(id) ON DELETE CASCADE;
ALTER TABLE ONLY recrutamento.candidatos
    ADD CONSTRAINT fk_candidatos_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY recrutamento.candidaturas
    ADD CONSTRAINT fk_candidaturas_candidato FOREIGN KEY (candidato_id) REFERENCES recrutamento.candidatos(id) ON DELETE SET NULL;
ALTER TABLE ONLY recrutamento.candidaturas
    ADD CONSTRAINT fk_candidaturas_rh_funcionario FOREIGN KEY (rh_funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE SET NULL;
ALTER TABLE ONLY recrutamento.candidaturas
    ADD CONSTRAINT fk_candidaturas_vaga FOREIGN KEY (vaga_id) REFERENCES recrutamento.vagas(id) ON DELETE SET NULL;
ALTER TABLE ONLY recrutamento.config_notificacoes
    ADD CONSTRAINT fk_config_notificacoes_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY recrutamento.vagas
    ADD CONSTRAINT fk_vagas_cargo FOREIGN KEY (cargo_id) REFERENCES rh.cargos(id) ON DELETE SET NULL;
ALTER TABLE ONLY recrutamento.vaga_campos
    ADD CONSTRAINT vaga_campos_vaga_id_fkey FOREIGN KEY (vaga_id) REFERENCES recrutamento.vagas(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.adiantamentos
    ADD CONSTRAINT adiantamentos_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.auditoria_assiduidade
    ADD CONSTRAINT auditoria_assiduidade_alterado_por_fkey FOREIGN KEY (alterado_por) REFERENCES auth.users(id);
ALTER TABLE ONLY rh.ausencias
    ADD CONSTRAINT ausencias_tipo_id_fkey FOREIGN KEY (tipo_id) REFERENCES rh.tipos_ausencia(id) ON DELETE RESTRICT;
ALTER TABLE ONLY rh.avaliacao_criterios
    ADD CONSTRAINT avaliacao_criterios_avaliacao_id_fkey FOREIGN KEY (avaliacao_id) REFERENCES rh.avaliacoes(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.avaliacao_criterios
    ADD CONSTRAINT avaliacao_criterios_criterio_id_fkey FOREIGN KEY (criterio_id) REFERENCES rh.criterios_avaliacao(id) ON DELETE RESTRICT;
ALTER TABLE ONLY rh.config_contabilidade_folha
    ADD CONSTRAINT config_contabilidade_folha_accounting_journal_id_fkey FOREIGN KEY (accounting_journal_id) REFERENCES contabilidade.accounting_journals(id);
ALTER TABLE ONLY rh.config_contabilidade_folha
    ADD CONSTRAINT config_contabilidade_folha_conta_adiantamentos_fkey FOREIGN KEY (conta_adiantamentos) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY rh.config_contabilidade_folha
    ADD CONSTRAINT config_contabilidade_folha_conta_despesa_salarios_fkey FOREIGN KEY (conta_despesa_salarios) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY rh.config_contabilidade_folha
    ADD CONSTRAINT config_contabilidade_folha_conta_inss_patronal_fkey FOREIGN KEY (conta_inss_patronal) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY rh.config_contabilidade_folha
    ADD CONSTRAINT config_contabilidade_folha_conta_inss_trabalhador_fkey FOREIGN KEY (conta_inss_trabalhador) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY rh.config_contabilidade_folha
    ADD CONSTRAINT config_contabilidade_folha_conta_irps_fkey FOREIGN KEY (conta_irps) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY rh.config_contabilidade_folha
    ADD CONSTRAINT config_contabilidade_folha_conta_salarios_a_pagar_fkey FOREIGN KEY (conta_salarios_a_pagar) REFERENCES contabilidade.chart_of_accounts(id);
ALTER TABLE ONLY rh.contactos_emergencia
    ADD CONSTRAINT contactos_emergencia_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.contactos_emergencia
    ADD CONSTRAINT contactos_emergencia_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY rh.correcoes_evento
    ADD CONSTRAINT correcoes_evento_decidido_por_fkey FOREIGN KEY (decidido_por) REFERENCES auth.users(id);
ALTER TABLE ONLY rh.correcoes_evento
    ADD CONSTRAINT correcoes_evento_evento_gerado_id_fkey FOREIGN KEY (evento_gerado_id) REFERENCES rh.eventos_assiduidade(id);
ALTER TABLE ONLY rh.correcoes_evento
    ADD CONSTRAINT correcoes_evento_evento_id_fkey FOREIGN KEY (evento_id) REFERENCES rh.eventos_assiduidade(id);
ALTER TABLE ONLY rh.correcoes_evento
    ADD CONSTRAINT correcoes_evento_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.correcoes_evento
    ADD CONSTRAINT correcoes_evento_solicitado_por_fkey FOREIGN KEY (solicitado_por) REFERENCES auth.users(id);
ALTER TABLE ONLY rh.correcoes_evento
    ADD CONSTRAINT correcoes_evento_tipo_evento_id_fkey FOREIGN KEY (tipo_evento_id) REFERENCES rh.tipos_evento(id);
ALTER TABLE ONLY rh.documentos_funcionario
    ADD CONSTRAINT documentos_funcionario_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.emprestimos
    ADD CONSTRAINT emprestimos_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.eventos_assiduidade
    ADD CONSTRAINT eventos_assiduidade_duplicado_de_id_fkey FOREIGN KEY (duplicado_de_id) REFERENCES rh.eventos_assiduidade(id);
ALTER TABLE ONLY rh.eventos_assiduidade
    ADD CONSTRAINT eventos_assiduidade_evento_pai_id_fkey FOREIGN KEY (evento_pai_id) REFERENCES rh.eventos_assiduidade(id);
ALTER TABLE ONLY rh.eventos_assiduidade
    ADD CONSTRAINT eventos_assiduidade_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.eventos_assiduidade
    ADD CONSTRAINT eventos_assiduidade_metodo_id_fkey FOREIGN KEY (metodo_id) REFERENCES rh.metodos_marcacao(id);
ALTER TABLE ONLY rh.eventos_assiduidade
    ADD CONSTRAINT eventos_assiduidade_registado_por_fkey FOREIGN KEY (registado_por) REFERENCES auth.users(id);
ALTER TABLE ONLY rh.eventos_assiduidade
    ADD CONSTRAINT eventos_assiduidade_tipo_evento_id_fkey FOREIGN KEY (tipo_evento_id) REFERENCES rh.tipos_evento(id);
ALTER TABLE ONLY rh.ausencias
    ADD CONSTRAINT fk_ausencias_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.avaliacoes
    ADD CONSTRAINT fk_avaliacoes_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.avaliacoes
    ADD CONSTRAINT fk_avaliacoes_periodo FOREIGN KEY (periodo_id) REFERENCES rh.periodos_avaliacao(id) ON DELETE SET NULL;
ALTER TABLE ONLY rh.contratos
    ADD CONSTRAINT fk_contratos_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT fk_funcionarios_unidade FOREIGN KEY (unit_id) REFERENCES rh.unidades_organizacionais(id) ON DELETE SET NULL;
ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT fk_funcionarios_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY rh.processos_disciplinares
    ADD CONSTRAINT fk_processos_disciplinares_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.recibo_vencimento_itens
    ADD CONSTRAINT fk_recibo_vencimento_itens_recibo FOREIGN KEY (recibo_id) REFERENCES rh.recibos_vencimento(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.recibos_vencimento
    ADD CONSTRAINT fk_recibos_vencimento_folha FOREIGN KEY (folha_id) REFERENCES rh.folhas_pagamento(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.recibos_vencimento
    ADD CONSTRAINT fk_recibos_vencimento_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.unidades_organizacionais
    ADD CONSTRAINT fk_unidades_organizacionais_parent FOREIGN KEY (parent_id) REFERENCES rh.unidades_organizacionais(id) ON DELETE SET NULL;
ALTER TABLE ONLY rh.unidades_organizacionais
    ADD CONSTRAINT fk_unidades_organizacionais_responsavel FOREIGN KEY (responsavel_id) REFERENCES rh.funcionarios(id) ON DELETE SET NULL;
ALTER TABLE ONLY rh.folhas_pagamento
    ADD CONSTRAINT folhas_pagamento_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES tesouraria.bank_accounts(id);
ALTER TABLE ONLY rh.folhas_pagamento
    ADD CONSTRAINT folhas_pagamento_cash_register_id_fkey FOREIGN KEY (cash_register_id) REFERENCES tesouraria.cash_registers(id);
ALTER TABLE ONLY rh.folhas_pagamento
    ADD CONSTRAINT folhas_pagamento_journal_entry_id_fkey FOREIGN KEY (journal_entry_id) REFERENCES contabilidade.journal_entries(id);
ALTER TABLE ONLY rh.folhas_pagamento
    ADD CONSTRAINT folhas_pagamento_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES tesouraria.movements(id);
ALTER TABLE ONLY rh.funcionario_beneficios
    ADD CONSTRAINT funcionario_beneficios_beneficio_id_fkey FOREIGN KEY (beneficio_id) REFERENCES rh.beneficios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.funcionario_beneficios
    ADD CONSTRAINT funcionario_beneficios_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.funcionario_componentes_salariais
    ADD CONSTRAINT funcionario_componentes_salariais_componente_id_fkey FOREIGN KEY (componente_id) REFERENCES rh.componentes_salariais(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.funcionario_componentes_salariais
    ADD CONSTRAINT funcionario_componentes_salariais_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.funcionario_formacoes
    ADD CONSTRAINT funcionario_formacoes_formacao_id_fkey FOREIGN KEY (formacao_id) REFERENCES rh.formacoes(id) ON DELETE RESTRICT;
ALTER TABLE ONLY rh.funcionario_formacoes
    ADD CONSTRAINT funcionario_formacoes_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.funcionario_horarios
    ADD CONSTRAINT funcionario_horarios_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.funcionario_horarios
    ADD CONSTRAINT funcionario_horarios_horario_id_fkey FOREIGN KEY (horario_id) REFERENCES rh.horarios_trabalho(id);
ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT funcionarios_cargo_id_fkey FOREIGN KEY (cargo_id) REFERENCES rh.cargos(id) ON DELETE SET NULL;
ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT funcionarios_centro_custo_id_fkey FOREIGN KEY (centro_custo_id) REFERENCES centros_custo.cost_centers(id);
ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT funcionarios_horario_id_fkey FOREIGN KEY (horario_id) REFERENCES rh.horarios_trabalho(id) ON DELETE SET NULL;
ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT funcionarios_pessoa_id_fkey FOREIGN KEY (pessoa_id) REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
ALTER TABLE ONLY rh.historico_salarial
    ADD CONSTRAINT historico_salarial_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.horarios_dias
    ADD CONSTRAINT horarios_dias_horario_id_fkey FOREIGN KEY (horario_id) REFERENCES rh.horarios_trabalho(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.justificacoes
    ADD CONSTRAINT justificacoes_aprovado_por_fkey FOREIGN KEY (aprovado_por) REFERENCES auth.users(id);
ALTER TABLE ONLY rh.justificacoes
    ADD CONSTRAINT justificacoes_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.presencas
    ADD CONSTRAINT presencas_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.regras_assiduidade
    ADD CONSTRAINT regras_assiduidade_tipo_regra_id_fkey FOREIGN KEY (tipo_regra_id) REFERENCES rh.tipos_regra(id);
ALTER TABLE ONLY rh.resultados_diarios
    ADD CONSTRAINT resultados_diarios_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.resultados_diarios
    ADD CONSTRAINT resultados_diarios_horario_id_fkey FOREIGN KEY (horario_id) REFERENCES rh.horarios_trabalho(id);
ALTER TABLE ONLY rh.resultados_periodos
    ADD CONSTRAINT resultados_periodos_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.saldos_ausencia
    ADD CONSTRAINT saldos_ausencia_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY rh.saldos_ausencia
    ADD CONSTRAINT saldos_ausencia_tipo_ausencia_id_fkey FOREIGN KEY (tipo_ausencia_id) REFERENCES rh.tipos_ausencia(id) ON DELETE CASCADE;
ALTER TABLE ONLY saas.approval_decisions
    ADD CONSTRAINT approval_decisions_aprovado_por_fkey FOREIGN KEY (aprovado_por) REFERENCES auth.users(id);
ALTER TABLE ONLY saas.approval_decisions
    ADD CONSTRAINT approval_decisions_request_id_fkey FOREIGN KEY (request_id) REFERENCES saas.approval_requests(id) ON DELETE CASCADE;
ALTER TABLE ONLY saas.approval_flows
    ADD CONSTRAINT approval_flows_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY saas.approval_requests
    ADD CONSTRAINT approval_requests_criado_por_fkey FOREIGN KEY (criado_por) REFERENCES auth.users(id);
ALTER TABLE ONLY saas.approval_requests
    ADD CONSTRAINT approval_requests_flow_id_fkey FOREIGN KEY (flow_id) REFERENCES saas.approval_flows(id);
ALTER TABLE ONLY saas.approval_requests
    ADD CONSTRAINT approval_requests_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY saas.feature_catalog
    ADD CONSTRAINT feature_catalog_modulo_fkey FOREIGN KEY (modulo) REFERENCES saas.module_catalog(key) ON DELETE CASCADE;
ALTER TABLE ONLY saas.tenant_dominios
    ADD CONSTRAINT fk_tenant_dominios_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY saas.tenant_modules
    ADD CONSTRAINT fk_tenant_modules_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY saas.tenant_subscriptions
    ADD CONSTRAINT fk_tenant_subscriptions_plano FOREIGN KEY (plano_id) REFERENCES saas.plans(id) ON DELETE RESTRICT;
ALTER TABLE ONLY saas.tenant_subscriptions
    ADD CONSTRAINT fk_tenant_subscriptions_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
ALTER TABLE ONLY saas.tenants
    ADD CONSTRAINT fk_tenants_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE SET NULL;
ALTER TABLE ONLY saas.tenants
    ADD CONSTRAINT fk_tenants_plano FOREIGN KEY (plano_id) REFERENCES saas.plans(id) ON DELETE SET NULL;
ALTER TABLE ONLY saas.module_dependencies
    ADD CONSTRAINT module_dependencies_modulo_fkey FOREIGN KEY (modulo) REFERENCES saas.module_catalog(key) ON DELETE CASCADE;
ALTER TABLE ONLY saas.module_dependencies
    ADD CONSTRAINT module_dependencies_requires_fkey FOREIGN KEY (requires) REFERENCES saas.module_catalog(key) ON DELETE CASCADE;
ALTER TABLE ONLY saas.plan_modules
    ADD CONSTRAINT plan_modules_modulo_fkey FOREIGN KEY (modulo) REFERENCES saas.module_catalog(key) ON DELETE CASCADE;
ALTER TABLE ONLY saas.plan_modules
    ADD CONSTRAINT plan_modules_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES saas.plans(id) ON DELETE CASCADE;
ALTER TABLE ONLY sistema_configuracao.cities
    ADD CONSTRAINT fk_cities_country FOREIGN KEY (country_id) REFERENCES sistema_configuracao.countries(id) ON DELETE SET NULL;
ALTER TABLE ONLY sistema_configuracao.exchange_rates
    ADD CONSTRAINT fk_exchange_rates_from_currency FOREIGN KEY (from_currency_id) REFERENCES sistema_configuracao.currencies(id) ON DELETE RESTRICT;
ALTER TABLE ONLY sistema_configuracao.exchange_rates
    ADD CONSTRAINT fk_exchange_rates_to_currency FOREIGN KEY (to_currency_id) REFERENCES sistema_configuracao.currencies(id) ON DELETE RESTRICT;
ALTER TABLE ONLY stock.stock_transfer_items
    ADD CONSTRAINT fk_sti_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id);
ALTER TABLE ONLY stock.stock_transfer_items
    ADD CONSTRAINT fk_sti_transfer FOREIGN KEY (stock_transfer_id) REFERENCES stock.stock_transfers(id) ON DELETE CASCADE;
ALTER TABLE ONLY stock.stock_adjustments
    ADD CONSTRAINT fk_stock_adjustments_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;
ALTER TABLE ONLY stock.stock_alerts
    ADD CONSTRAINT fk_stock_alerts_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;
ALTER TABLE ONLY stock.stock_batches
    ADD CONSTRAINT fk_stock_batches_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;
ALTER TABLE ONLY stock.stock_count_items
    ADD CONSTRAINT fk_stock_count_items_count FOREIGN KEY (stock_count_id) REFERENCES stock.stock_counts(id) ON DELETE CASCADE;
ALTER TABLE ONLY stock.stock_counts
    ADD CONSTRAINT fk_stock_counts_warehouse FOREIGN KEY (warehouse_id) REFERENCES produtos.warehouses(id) ON DELETE RESTRICT;
ALTER TABLE ONLY stock.stock_items
    ADD CONSTRAINT fk_stock_items_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE RESTRICT;
ALTER TABLE ONLY stock.stock_items
    ADD CONSTRAINT fk_stock_items_warehouse FOREIGN KEY (warehouse_id) REFERENCES produtos.warehouses(id) ON DELETE RESTRICT;
ALTER TABLE ONLY stock.stock_movements
    ADD CONSTRAINT fk_stock_movements_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;
ALTER TABLE ONLY stock.stock_reservations
    ADD CONSTRAINT fk_stock_reservations_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;
ALTER TABLE ONLY stock.stock_serial_numbers
    ADD CONSTRAINT fk_stock_serial_numbers_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;
ALTER TABLE ONLY stock.warehouse_locations
    ADD CONSTRAINT fk_warehouse_locations_warehouse FOREIGN KEY (warehouse_id) REFERENCES produtos.warehouses(id) ON DELETE CASCADE;
ALTER TABLE ONLY tarefas.cartoes
    ADD CONSTRAINT fk_cartoes_lista FOREIGN KEY (lista_id) REFERENCES tarefas.listas(id) ON DELETE CASCADE;
ALTER TABLE ONLY tarefas.listas
    ADD CONSTRAINT fk_listas_quadro FOREIGN KEY (quadro_id) REFERENCES tarefas.quadros(id) ON DELETE CASCADE;
ALTER TABLE ONLY tesouraria.movements
    ADD CONSTRAINT movements_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES tesouraria.bank_accounts(id);
ALTER TABLE ONLY tesouraria.movements
    ADD CONSTRAINT movements_cash_register_id_fkey FOREIGN KEY (cash_register_id) REFERENCES tesouraria.cash_registers(id);
ALTER TABLE ONLY tesouraria.reconciliations
    ADD CONSTRAINT reconciliations_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES tesouraria.bank_accounts(id);
ALTER TABLE ONLY utilizadores.profiles
    ADD CONSTRAINT fk_profiles_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY utilizadores.user_activity
    ADD CONSTRAINT fk_user_activity_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY utilizadores.user_avatar
    ADD CONSTRAINT fk_user_avatar_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY utilizadores.user_devices
    ADD CONSTRAINT fk_user_devices_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY utilizadores.user_notifications
    ADD CONSTRAINT fk_user_notifications_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY utilizadores.user_preferences
    ADD CONSTRAINT fk_user_preferences_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY utilizadores.user_security_logs
    ADD CONSTRAINT fk_user_security_logs_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY utilizadores.user_settings
    ADD CONSTRAINT fk_user_settings_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY utilizadores.user_tokens
    ADD CONSTRAINT fk_user_tokens_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
