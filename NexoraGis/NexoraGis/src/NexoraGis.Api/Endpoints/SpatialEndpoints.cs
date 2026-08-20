using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Spatial;

namespace NexoraGis.Api.Endpoints;

public static class SpatialEndpoints
{
    public static void MapSpatialEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/spatial")
            .WithTags("Spatial")
            .RequireAuthorization();

        group.MapPost("/affected-parcels", async (AffectedParcelsRequest request, SpatialAnalysisService service, CancellationToken ct) =>
                (await service.FindAffectedParcelsAsync(request, ct)).ToHttpResult())
            .RequirePermission("parcels", "read");

        group.MapGet("/projects/{projetoId:guid}/statistics", async (Guid projetoId, SpatialAnalysisService service, CancellationToken ct) =>
                (await service.GetProjectStatisticsAsync(projetoId, ct)).ToHttpResult())
            .RequirePermission("projects", "read");
    }
}
