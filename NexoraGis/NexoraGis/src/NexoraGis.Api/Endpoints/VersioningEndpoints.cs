using NexoraGis.Api.Authorization;
using NexoraGis.Application.Features.Versioning;

namespace NexoraGis.Api.Endpoints;

public static class VersioningEndpoints
{
    public static void MapVersioningEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/geometry-history")
            .WithTags("Versioning")
            .RequireAuthorization();

        group.MapGet("/{entidadeTipo}/{entidadeId:guid}", async (string entidadeTipo, Guid entidadeId, VersioningService service, CancellationToken ct) =>
                Results.Ok(await service.GetHistoryAsync(entidadeTipo, entidadeId, ct)))
            .RequirePermission("parcels", "read");

        // Reconstrução histórica (backlog 6.2.2): geometria vigente numa data.
        group.MapGet("/{entidadeTipo}/{entidadeId:guid}/at", async (string entidadeTipo, Guid entidadeId, DateTimeOffset data, VersioningService service, CancellationToken ct) =>
                Results.Ok(await service.GetAtDateAsync(entidadeTipo, entidadeId, data, ct)))
            .RequirePermission("parcels", "read");
    }
}
