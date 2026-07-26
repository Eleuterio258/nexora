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
