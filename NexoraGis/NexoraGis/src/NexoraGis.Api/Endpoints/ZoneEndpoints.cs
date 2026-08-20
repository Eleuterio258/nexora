using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Zoning;

namespace NexoraGis.Api.Endpoints;

public static class ZoneEndpoints
{
    public static void MapZoneEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/zones")
            .WithTags("Zones")
            .RequireAuthorization();

        group.MapGet("/", async (
                Guid? planoId, string? codigo, ZonaService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(planoId, codigo, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("zones", "read");

        group.MapGet("/{id:guid}", async (Guid id, ZonaService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("zones", "read");

        group.MapGet("/{id:guid}/affected-parcels", async (Guid id, ZonaService service, CancellationToken ct) =>
                (await service.ListParcelasAfetadasAsync(id, ct)).ToHttpResult())
            .RequirePermission("zones", "read");

        group.MapPost("/", async (UpsertZonaRequest request, ZonaService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/zones/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("zones", "create");

        group.MapPut("/{id:guid}", async (Guid id, UpsertZonaRequest request, ZonaService service, CancellationToken ct) =>
                (await service.UpdateAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("zones", "update");

        group.MapDelete("/{id:guid}", async (Guid id, ZonaService service, CancellationToken ct) =>
                (await service.DeleteAsync(id, ct)).ToHttpResult())
            .RequirePermission("zones", "update");
    }
}
