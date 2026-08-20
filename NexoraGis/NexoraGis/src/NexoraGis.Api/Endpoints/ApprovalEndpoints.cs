using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Approvals;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

public static class ApprovalEndpoints
{
    public static void MapApprovalEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/approvals")
            .WithTags("Approvals")
            .RequireAuthorization();

        group.MapGet("/", async (
                Guid? projetoId, string? entidadeTipo, ApprovalStatus? status, AprovacaoService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(projetoId, entidadeTipo, status, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("approvals", "read");

        // Dashboard de tarefas pendentes (backlog 6.1.3).
        group.MapGet("/pending", async (Guid? projetoId, AprovacaoService service, CancellationToken ct, int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListPendingAsync(projetoId, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("approvals", "read");

        group.MapGet("/{id:guid}", async (Guid id, AprovacaoService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("approvals", "read");

        group.MapPost("/", async (CreateAprovacaoRequest request, AprovacaoService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/approvals/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("approvals", "create");

        group.MapPost("/{id:guid}/submit", async (Guid id, AprovacaoService service, CancellationToken ct) =>
                (await service.SubmeterAsync(id, ct)).ToHttpResult())
            .RequirePermission("approvals", "update");

        group.MapPost("/{id:guid}/start-review", async (Guid id, AprovacaoService service, CancellationToken ct) =>
                (await service.IniciarAnaliseAsync(id, ct)).ToHttpResult())
            .RequirePermission("approvals", "update");

        group.MapPost("/{id:guid}/request-changes", async (Guid id, PedirCorrecaoRequest request, AprovacaoService service, CancellationToken ct) =>
                (await service.PedirCorrecaoAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("approvals", "update");

        group.MapPost("/{id:guid}/approve", async (Guid id, AprovacaoService service, CancellationToken ct) =>
                (await service.AprovarAsync(id, ct)).ToHttpResult())
            .RequirePermission("approvals", "approve");

        group.MapPost("/{id:guid}/reject", async (Guid id, RejeitarRequest request, AprovacaoService service, CancellationToken ct) =>
                (await service.RejeitarAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("approvals", "approve");

        group.MapPost("/{id:guid}/publish", async (Guid id, AprovacaoService service, CancellationToken ct) =>
                (await service.PublicarAsync(id, ct)).ToHttpResult())
            .RequirePermission("approvals", "approve");

        group.MapPost("/{id:guid}/reopen", async (Guid id, AprovacaoService service, CancellationToken ct) =>
                (await service.ReabrirAsync(id, ct)).ToHttpResult())
            .RequirePermission("approvals", "update");
    }
}
