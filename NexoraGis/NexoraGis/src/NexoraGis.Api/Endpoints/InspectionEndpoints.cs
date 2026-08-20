using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Inspections;

namespace NexoraGis.Api.Endpoints;

public static class InspectionEndpoints
{
    public static void MapInspectionEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/inspections")
            .WithTags("Inspections")
            .RequireAuthorization();

        group.MapGet("/", async (
                Guid? projetoId, Guid? parcelaId, string? estado, FiscalizacaoService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(projetoId, parcelaId, estado, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("fiscalizacao", "read");

        group.MapGet("/{id:guid}", async (Guid id, FiscalizacaoService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("fiscalizacao", "read");

        group.MapPost("/", async (CreateFiscalizacaoRequest request, FiscalizacaoService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/inspections/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("fiscalizacao", "create");

        group.MapPost("/{id:guid}/status", async (Guid id, UpdateFiscalizacaoEstadoRequest request, FiscalizacaoService service, CancellationToken ct) =>
                (await service.UpdateEstadoAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("fiscalizacao", "update");
    }
}
