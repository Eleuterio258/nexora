using NexoraGis.Application.Features.Auth;

namespace NexoraGis.Api.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/auth").WithTags("Auth");

        group.MapPost("/login", async (LoginRequest request, AuthService authService, CancellationToken ct) =>
        {
            var result = await authService.LoginAsync(request, ct);
            return result is null ? Results.Unauthorized() : Results.Ok(result);
        });

        group.MapPost("/refresh", async (RefreshRequest request, AuthService authService, CancellationToken ct) =>
        {
            var result = await authService.RefreshAsync(request, ct);
            return result is null ? Results.Unauthorized() : Results.Ok(result);
        });

        group.MapPost("/logout", async (RefreshRequest request, AuthService authService, CancellationToken ct) =>
        {
            await authService.LogoutAsync(request.RefreshToken, ct);
            return Results.NoContent();
        }).RequireAuthorization();
    }
}
