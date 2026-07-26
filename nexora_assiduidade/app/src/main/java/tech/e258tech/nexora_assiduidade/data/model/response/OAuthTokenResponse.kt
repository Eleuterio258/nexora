package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta de POST /oauth/token no Nexora ERP (Authorization Server OAuth2,
 * grant_types "password" e "refresh_token" — ver
 * backend/internal/modules/auth/handlers/oauth_token.go). Formato RFC 6749
 * puro: ao contrário do antigo /api/auth/login (ErpLoginResponse), não
 * inclui `user`/`modulos` — quem chama busca isso à parte via
 * GET /api/auth/me (ver ErpMeResponse) e GET /api/auth/me/acesso (já
 * existia, ver ErpApiService.getMeuAcesso).
 *
 * `refresh_token` é sempre novo a cada chamada, mesmo em grant_type=refresh_token
 * — o ERP roda (invalida o anterior) a cada uso; quem chama TEM de persistir
 * o novo valor, nunca reutilizar o antigo (ver AuthAuthenticator).
 */
data class OAuthTokenResponse(
    val access_token: String,
    val refresh_token: String,
    val token_type: String,
    val expires_in: Int,
    val scope: String = ""
)
