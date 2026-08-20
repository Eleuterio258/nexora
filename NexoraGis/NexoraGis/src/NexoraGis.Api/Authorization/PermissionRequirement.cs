using Microsoft.AspNetCore.Authorization;

namespace NexoraGis.Api.Authorization;

/// <summary>Exige que o perfil do utilizador tenha permissão (Recurso, Acao) em territorial.permissao.</summary>
public class PermissionRequirement(string resource, string action) : IAuthorizationRequirement
{
    public string Resource { get; } = resource;
    public string Action { get; } = action;
}
