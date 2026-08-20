using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Reports;

namespace NexoraGis.Api.Endpoints;

/// <summary>Relatórios PDF (backlog 8.2).</summary>
public static class ReportEndpoints
{
    public static void MapReportEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/reports")
            .WithTags("Reports")
            .RequireAuthorization();

        group.MapGet("/parcels/{parcelaId:guid}/ficha.pdf", async (Guid parcelaId, ReportService service, CancellationToken ct) =>
            {
                var result = await service.GenerateParcelaFichaAsync(parcelaId, ct);
                return result.IsSuccess
                    ? Results.File(result.Value, "application/pdf", $"ficha-{parcelaId}.pdf")
                    : result.ToHttpResult();
            })
            .RequirePermission("parcels", "read");

        group.MapGet("/projects/{projetoId:guid}/land-use-map.pdf", async (Guid projetoId, ReportService service, CancellationToken ct) =>
            {
                var result = await service.GenerateMapaUsoSoloAsync(projetoId, ct);
                return result.IsSuccess
                    ? Results.File(result.Value, "application/pdf", $"mapa-uso-solo-{projetoId}.pdf")
                    : result.ToHttpResult();
            })
            .RequirePermission("projects", "read");
    }
}
