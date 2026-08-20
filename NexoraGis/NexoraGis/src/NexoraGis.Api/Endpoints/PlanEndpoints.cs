using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Plans;

namespace NexoraGis.Api.Endpoints;

public static class PlanEndpoints
{
    public static void MapPlanEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/plans")
            .WithTags("Plans")
            .RequireAuthorization();

        group.MapGet("/", async (
                Guid? projetoId, string? codigo, bool? ativo, PlanoService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(projetoId, codigo, ativo, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("plans", "read");

        group.MapGet("/{id:guid}", async (Guid id, PlanoService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("plans", "read");

        group.MapGet("/{id:guid}/versions", async (Guid id, PlanoService service, CancellationToken ct) =>
                (await service.ListVersionsAsync(id, ct)).ToHttpResult())
            .RequirePermission("plans", "read");

        group.MapPost("/", async (CreatePlanoRequest request, PlanoService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/plans/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("plans", "create");

        group.MapPut("/{id:guid}", async (Guid id, UpdatePlanoRequest request, PlanoService service, CancellationToken ct) =>
                (await service.UpdateAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("plans", "update");

        group.MapPost("/{id:guid}/versions", async (Guid id, CreatePlanoVersionRequest request, PlanoService service, CancellationToken ct) =>
            {
                var result = await service.CreateVersionAsync(id, request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/plans/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("plans", "update");
    }
}
