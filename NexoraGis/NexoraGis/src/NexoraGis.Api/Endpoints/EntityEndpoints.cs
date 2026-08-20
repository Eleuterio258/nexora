using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Entities;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

public static class EntityEndpoints
{
    public static void MapEntityEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/entities")
            .WithTags("Entities")
            .RequireAuthorization();

        group.MapGet("/", async (
                TipoEntidade? tipo, string? nome, EntidadeService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(tipo, nome, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("entities", "read");

        group.MapGet("/{id:guid}", async (Guid id, EntidadeService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("entities", "read");

        group.MapPost("/", async (UpsertEntidadeRequest request, EntidadeService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/entities/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("entities", "create");

        group.MapPut("/{id:guid}", async (Guid id, UpsertEntidadeRequest request, EntidadeService service, CancellationToken ct) =>
                (await service.UpdateAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("entities", "update");

        group.MapDelete("/{id:guid}", async (Guid id, EntidadeService service, CancellationToken ct) =>
                (await service.DeleteAsync(id, ct)).ToHttpResult())
            .RequirePermission("entities", "update");

        // Vista pública (WebGIS público — §6, §35): sem autenticação, sempre mascarada.
        app.MapGet("/api/v1/public/entities", async (EntidadeService service, CancellationToken ct, int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListPublicAsync(page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .WithTags("Public")
            .AllowAnonymous();
    }
}
