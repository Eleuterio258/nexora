using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Gis;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

public static class GisEndpoints
{
    public static void MapGisEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/layers")
            .WithTags("Layers")
            .RequireAuthorization();

        group.MapGet("/", async (
                Guid? projetoId, TipoCamada? tipo, CamadaService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(projetoId, tipo, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("layers", "read");

        group.MapGet("/{id:guid}", async (Guid id, CamadaService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("layers", "read");

        group.MapPost("/", async (UpsertCamadaRequest request, CamadaService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/layers/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("layers", "create");

        group.MapPut("/{id:guid}", async (Guid id, UpsertCamadaRequest request, CamadaService service, CancellationToken ct) =>
                (await service.UpdateAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("layers", "update");

        group.MapDelete("/{id:guid}", async (Guid id, CamadaService service, CancellationToken ct) =>
                (await service.DeleteAsync(id, ct)).ToHttpResult())
            .RequirePermission("layers", "update");

        // Publicação no GeoServer (backlog 7.1.2) — fica disponível via WMS/WFS/WMTS automaticamente.
        group.MapPost("/{id:guid}/publish", async (Guid id, string? corHex, CamadaService service, CancellationToken ct) =>
                (await service.PublishAsync(id, corHex, ct)).ToHttpResult())
            .RequirePermission("layers", "update");

        // Registo de produtos de drone (§11 / backlog 4.3.3) sobre o catálogo de camadas.
        group.MapPost("/drone-products", async (RegisterDroneProductRequest request, CamadaService service, CancellationToken ct) =>
            {
                var result = await service.RegisterDroneProductAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/layers/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("layers", "create");
    }
}
