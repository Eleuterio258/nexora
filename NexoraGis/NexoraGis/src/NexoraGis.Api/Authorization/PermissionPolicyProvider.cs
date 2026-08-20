using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Options;

namespace NexoraGis.Api.Authorization;

/// <summary>
/// Gera políticas de autorização "Permission:{recurso}:{acao}" dinamicamente,
/// sem ser preciso registar uma política por cada combinação recurso/ação.
/// </summary>
public class PermissionPolicyProvider(IOptions<AuthorizationOptions> options) : IAuthorizationPolicyProvider
{
    public const string Prefix = "Permission:";

    private readonly DefaultAuthorizationPolicyProvider _fallback = new(options);

    public Task<AuthorizationPolicy> GetDefaultPolicyAsync() => _fallback.GetDefaultPolicyAsync();

    public Task<AuthorizationPolicy?> GetFallbackPolicyAsync() => _fallback.GetFallbackPolicyAsync();

    public Task<AuthorizationPolicy?> GetPolicyAsync(string policyName)
    {
        if (!policyName.StartsWith(Prefix, StringComparison.Ordinal))
            return _fallback.GetPolicyAsync(policyName);

        var parts = policyName[Prefix.Length..].Split(':', 2);
        if (parts.Length != 2)
            return Task.FromResult<AuthorizationPolicy?>(null);

        var policy = new AuthorizationPolicyBuilder()
            .RequireAuthenticatedUser()
            .AddRequirements(new PermissionRequirement(parts[0], parts[1]))
            .Build();

        return Task.FromResult<AuthorizationPolicy?>(policy);
    }
}
