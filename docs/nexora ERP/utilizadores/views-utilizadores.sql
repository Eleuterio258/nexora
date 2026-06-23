-- Views do modulo de Utilizadores

CREATE OR REPLACE VIEW vw_user_profile_resumo AS
SELECT
    p.user_id,
    COALESCE(p.nome_exibicao, CONCAT_WS(' ', p.primeiro_nome, p.ultimo_nome)) AS nome,
    p.idioma,
    p.timezone,
    ua.ficheiro_url AS avatar_url
FROM profiles p
LEFT JOIN user_avatar ua ON ua.user_id = p.user_id;

CREATE OR REPLACE VIEW vw_user_notificacoes_pendentes AS
SELECT
    user_id,
    COUNT(*) AS total_pendentes
FROM user_notifications
WHERE lida = FALSE
GROUP BY user_id;
