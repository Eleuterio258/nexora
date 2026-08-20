namespace NexoraGis.Api.Authorization;

public static class RequirePermissionExtensions
{
    /// <summary>Ex: .RequirePermission("parcels", "create") exige perfil com essa permissão em territorial.permissao.</summary>
    public static RouteHandlerBuilder RequirePermission(this RouteHandlerBuilder builder, string resource, string action) =>
        builder.RequireAuthorization($"{PermissionPolicyProvider.Prefix}{resource}:{action}");
}
