using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Surveys;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

/// <summary>
/// Sincronização de dados recolhidos offline (app de campo) ou por
/// equipamento GNSS/RTK externo (§9, §10; backlog 4.2). O lote é posto em
/// fila e processado em segundo plano (4.2.4); conflitos de dados ficam
/// pendentes de resolução manual (4.2.3).
/// </summary>
public static class SyncEndpoints
{
    public static void MapSyncEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/sync")
            .WithTags("Sync")
            .RequireAuthorization();

        group.MapPost("/points", async (SyncPontosRequest request, SyncService service, CancellationToken ct) =>
            {
                var result = await service.EnqueueAsync(request, ct);
                return result.IsSuccess
                    ? Results.Accepted($"/api/v1/sync/jobs/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("surveys", "sync");

        group.MapGet("/jobs", async (
                Guid? levantamentoId, SyncJobStatus? status, SyncService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListJobsAsync(levantamentoId, status, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("surveys", "read");

        group.MapGet("/jobs/{id:guid}", async (Guid id, SyncService service, CancellationToken ct) =>
                (await service.GetJobAsync(id, ct)).ToHttpResult())
            .RequirePermission("surveys", "read");

        group.MapGet("/conflicts", async (
                Guid? levantamentoId, SyncConflitoStatus? status, SyncService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListConflictsAsync(levantamentoId, status, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("surveys", "read");

        group.MapPost("/conflicts/{id:guid}/resolve", async (Guid id, ResolveSyncConflitoRequest request, SyncService service, CancellationToken ct) =>
                (await service.ResolveConflictAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("surveys", "update");
    }
}
