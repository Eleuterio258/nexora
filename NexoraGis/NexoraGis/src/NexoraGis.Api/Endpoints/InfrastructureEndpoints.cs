using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Infrastructure;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

public static class InfrastructureEndpoints
{
    public static void MapInfrastructureEndpoints(this IEndpointRouteBuilder app)
    {
        var infra = app.MapGroup("/api/v1/infrastructure")
            .WithTags("Infrastructure")
            .RequireAuthorization();

        infra.MapGet("/", async (
                Guid? projetoId, TipoInfraestrutura? tipo, InfraestruturaService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(projetoId, tipo, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("infrastructure", "read");

        infra.MapGet("/{id:guid}", async (Guid id, InfraestruturaService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("infrastructure", "read");

        infra.MapPost("/", async (UpsertInfraestruturaRequest request, InfraestruturaService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/infrastructure/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("infrastructure", "create");

        infra.MapPut("/{id:guid}", async (Guid id, UpsertInfraestruturaRequest request, InfraestruturaService service, CancellationToken ct) =>
                (await service.UpdateAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("infrastructure", "update");

        infra.MapDelete("/{id:guid}", async (Guid id, InfraestruturaService service, CancellationToken ct) =>
                (await service.DeleteAsync(id, ct)).ToHttpResult())
            .RequirePermission("infrastructure", "update");

        var facilities = app.MapGroup("/api/v1/facilities")
            .WithTags("Facilities")
            .RequireAuthorization();

        facilities.MapGet("/", async (
                Guid? projetoId, string? tipo, EquipamentoService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(projetoId, tipo, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("facilities", "read");

        facilities.MapGet("/{id:guid}", async (Guid id, EquipamentoService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("facilities", "read");

        facilities.MapPost("/", async (UpsertEquipamentoRequest request, EquipamentoService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/facilities/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("facilities", "create");

        facilities.MapPut("/{id:guid}", async (Guid id, UpsertEquipamentoRequest request, EquipamentoService service, CancellationToken ct) =>
                (await service.UpdateAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("facilities", "update");

        facilities.MapDelete("/{id:guid}", async (Guid id, EquipamentoService service, CancellationToken ct) =>
                (await service.DeleteAsync(id, ct)).ToHttpResult())
            .RequirePermission("facilities", "update");
    }
}
