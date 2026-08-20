using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.AdministrativeDivisions;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

public static class AdministrativeDivisionEndpoints
{
    public static void MapAdministrativeDivisionEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/administrative-divisions")
            .WithTags("AdministrativeDivisions")
            .RequireAuthorization();

        group.MapGet("/", async (
                TipoDivisao? tipo, bool? zonaUrbana, Guid? parentId, bool? ativo,
                AdministrativeDivisionService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
            {
                var result = await service.ListAsync(tipo, zonaUrbana, parentId, ativo,
                    page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct);
                return Results.Ok(result);
            })
            .RequirePermission("divisions", "read");

        group.MapGet("/{id:guid}", async (Guid id, AdministrativeDivisionService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("divisions", "read");

        group.MapGet("/{id:guid}/children", async (Guid id, AdministrativeDivisionService service, CancellationToken ct) =>
                (await service.GetChildrenAsync(id, ct)).ToHttpResult())
            .RequirePermission("divisions", "read");

        group.MapGet("/{id:guid}/path", async (Guid id, AdministrativeDivisionService service, CancellationToken ct) =>
                (await service.GetPathAsync(id, ct)).ToHttpResult())
            .RequirePermission("divisions", "read");

        group.MapPost("/", async (CreateDivisaoAdministrativaRequest request, AdministrativeDivisionService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/administrative-divisions/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("divisions", "create");

        group.MapPut("/{id:guid}", async (Guid id, UpdateDivisaoAdministrativaRequest request, AdministrativeDivisionService service, CancellationToken ct) =>
                (await service.UpdateAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("divisions", "update");

        group.MapDelete("/{id:guid}", async (Guid id, AdministrativeDivisionService service, CancellationToken ct) =>
                (await service.DeactivateAsync(id, ct)).ToHttpResult())
            .RequirePermission("divisions", "update");
    }
}
