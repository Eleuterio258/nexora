SET search_path TO auth, public;

-- Adiciona o tipo 'tenant_admin' ao CHECK constraint de auth.users
ALTER TABLE auth.users
    DROP CONSTRAINT IF EXISTS users_tipo_check;

ALTER TABLE auth.users
    ADD CONSTRAINT users_tipo_check CHECK (
        (tipo)::text = ANY (
            (ARRAY[
                'superadmin'::character varying,
                'tenant_admin'::character varying,
                'funcionario'::character varying
            ])::text[]
        )
    );

-- Permissões base para tenant_admin
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao)
VALUES
    ('tenant_admin', 'autorizacao', 'gerir_utilizadores'),
    ('tenant_admin', 'autorizacao', 'gerir_perfis'),
    ('tenant_admin', 'autorizacao', 'gerir_permissoes'),
    ('tenant_admin', 'empresa', 'ver'),
    ('tenant_admin', 'empresa', 'editar'),
    ('tenant_admin', 'sistema-configuracao', 'ver_configuracoes'),
    ('tenant_admin', 'sistema-configuracao', 'editar_configuracoes'),
    ('tenant_admin', 'auditoria', 'ver_logs'),
    ('tenant_admin', 'auth', 'ver_sessoes'),
    ('tenant_admin', 'home', 'ver_dashboard'),
    ('tenant_admin', 'perfil', 'ver_perfil'),
    ('tenant_admin', 'perfil', 'editar_perfil')
ON CONFLICT (tipo, modulo, acao) DO NOTHING;

-- Garante que superadmin também tenha as permissões de superadmin registradas
-- (mesmo com bypass, é útil para consistência da UI e audit logs)
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao)
VALUES
    ('superadmin', 'superadmin', 'ver_dashboard'),
    ('superadmin', 'superadmin', 'gerir_tenants'),
    ('superadmin', 'superadmin', 'gerir_planos'),
    ('superadmin', 'superadmin', 'gerir_modulos'),
    ('superadmin', 'superadmin', 'gerir_configuracoes_globais'),
    ('superadmin', 'superadmin', 'gerir_utilizadores_globais')
ON CONFLICT (tipo, modulo, acao) DO NOTHING;
