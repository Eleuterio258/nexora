using NexoraGis.Application.Common;

namespace NexoraGis.Api.Services;

public class CurrentUserService(IHttpContextAccessor httpContextAccessor) : ICurrentUserService
{
    private System.Security.Claims.ClaimsPrincipal? User => httpContextAccessor.HttpContext?.User;

    public bool IsAuthenticated => User?.Identity?.IsAuthenticated ?? false;

    public Guid? UtilizadorId =>
        Guid.TryParse(User?.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value, out var id)
            ? id
            : null;

    public Guid? OrganizacaoId =>
        Guid.TryParse(User?.FindFirst("organizacao_id")?.Value, out var id) ? id : null;

    public string? Perfil => User?.FindFirst("perfil")?.Value;
}
