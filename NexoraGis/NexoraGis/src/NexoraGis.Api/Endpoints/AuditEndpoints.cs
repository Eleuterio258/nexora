using NexoraGis.Api.Authorization;
using NexoraGis.Application.Features.Audit;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

public static class AuditEndpoints
{
    public static void MapAuditEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/audit")
            .WithTags("Audit")
            .RequireAuthorization();

        group.MapGet("/", async (
                string? entidadeTipo, Guid? entidadeId, Guid? projetoId, Guid? utilizadorId, TipoOperacaoAuditoria? operacao,
                DateTimeOffset? dataInicio, DateTimeOffset? dataFim, AuditLogService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(
                    entidadeTipo, entidadeId, projetoId, utilizadorId, operacao, dataInicio, dataFim,
                    page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("audit", "read");
    }
}
