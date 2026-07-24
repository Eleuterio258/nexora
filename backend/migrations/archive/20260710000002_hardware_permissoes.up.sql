-- Permissões para gestão de dispositivos de acesso (hardware)
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao)
VALUES
    ('funcionario', 'hardware', 'ver_dispositivos'),
    ('funcionario', 'hardware', 'gerir_dispositivos'),
    ('funcionario', 'hardware', 'ver_eventos')
ON CONFLICT (tipo, modulo, acao) DO NOTHING;
