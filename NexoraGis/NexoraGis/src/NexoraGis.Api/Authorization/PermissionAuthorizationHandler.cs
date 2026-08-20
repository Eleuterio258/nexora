using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using NexoraGis.Infrastructure.Persistence;

namespace NexoraGis.Api.Authorization;

/// <summary>
/// Verifica em territorial.permissao se o perfil do utilizador autenticado tem
/// a ação pedida sobre o recurso pedido. '*' funciona como wildcard em
/// Perfil/Recurso/Acao (ex: administrador tem '*'/'*').
/// </summary>
public class PermissionAuthorizationHandler(AppDbContext dbContext) : AuthorizationHandler<PermissionRequirement>
{
    protected override async Task HandleRequirementAsync(AuthorizationHandlerContext context, PermissionRequirement requirement)
    {
        var perfil = context.User.FindFirst("perfil")?.Value;
        if (string.IsNullOrEmpty(perfil))
            return;

        var allowed = await dbContext.Permissoes.AnyAsync(p =>
            p.Ativo &&
            (p.Perfil == perfil || p.Perfil == "*") &&
            (p.Recurso == requirement.Resource || p.Recurso == "*") &&
            (p.Acao == requirement.Action || p.Acao == "*"));

        if (allowed)
            context.Succeed(requirement);
    }
}
