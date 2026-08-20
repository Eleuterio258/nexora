using System.Text;
using NexoraGis.Api.Authorization;
using NexoraGis.Application.Features.Export;

namespace NexoraGis.Api.Endpoints;

/// <summary>Exportação de dados cadastrais (backlog 9.1) — GeoJSON e CSV.</summary>
public static class ExportEndpoints
{
    public static void MapExportEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/export")
            .WithTags("Export")
            .RequireAuthorization();

        group.MapGet("/parcels.geojson", async (Guid? projetoId, ExportService service, CancellationToken ct) =>
                Results.Json(await service.GetParcelasGeoJsonAsync(projetoId, ct), contentType: "application/geo+json"))
            .RequirePermission("parcels", "read");

        group.MapGet("/parcels.csv", async (Guid? projetoId, ExportService service, CancellationToken ct) =>
            {
                var csv = await service.GetParcelasCsvAsync(projetoId, ct);
                return Results.File(Encoding.UTF8.GetBytes(csv), "text/csv", "parcelas.csv");
            })
            .RequirePermission("parcels", "read");
    }
}
