using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Conflicts;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

public static class ConflictEndpoints
{
    public static void MapConflictEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/conflicts")
            .WithTags("Conflicts")
            .RequireAuthorization();

        group.MapGet("/", async (
                Guid? projetoId, TipoConflito? tipo, bool? resolvido, ConflitoService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(projetoId, tipo, resolvido, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("conflicts", "read");

        group.MapGet("/{id:guid}", async (Guid id, ConflitoService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("conflicts", "read");

        group.MapPost("/", async (CreateConflitoRequest request, ConflitoService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/conflicts/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("conflicts", "create");

        group.MapPost("/{id:guid}/resolve", async (Guid id, ConflitoService service, CancellationToken ct) =>
                (await service.ResolveAsync(id, ct)).ToHttpResult())
            .RequirePermission("conflicts", "update");

        // Corre o motor de deteção automática (5.4.1 uso incompatível + 5.4.2 infração de condicionante) sobre o projeto.
        group.MapPost("/detect/{projetoId:guid}", async (Guid projetoId, ConflitoService service, CancellationToken ct) =>
                (await service.DetectAllAsync(projetoId, ct)).ToHttpResult())
            .RequirePermission("conflicts", "create");
    }
}
