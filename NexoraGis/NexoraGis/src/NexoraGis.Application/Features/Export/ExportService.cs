using System.Globalization;
using System.Text;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Features;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Export;

/// <summary>
/// Exportação de dados cadastrais (backlog 9.1). GeoJSON/CSV cobertos aqui —
/// Shapefile/KML/GeoPackage/DXF/GeoTIFF ficam fora, pedem bibliotecas
/// especializadas que o projeto não tem ainda.
/// </summary>
public class ExportService(IRepository<Parcela> parcelas)
{
    public async Task<FeatureCollection> GetParcelasGeoJsonAsync(Guid? projetoId, CancellationToken ct = default)
    {
        var query = parcelas.Query();
        if (projetoId is not null) query = query.Where(p => p.ProjetoId == projetoId);

        var items = await query.OrderBy(p => p.CodigoCadastral).Take(5000).ToListAsync(ct);

        var collection = new FeatureCollection();
        foreach (var p in items)
        {
            var attributes = new AttributesTable
            {
                { "id", p.Id },
                { "codigoCadastral", p.CodigoCadastral },
                { "numeroParcela", p.NumeroParcela ?? "" },
                { "situacao", p.Situacao.ToString() },
                { "usoAtual", p.UsoAtual?.ToString() ?? "" },
                { "usoPrevisto", p.UsoPrevisto?.ToString() ?? "" },
                { "estado", p.Estado.ToString() },
                { "areaCalculadaM2", p.AreaCalculada ?? 0 }
            };
            collection.Add(new Feature(p.Geometria, attributes));
        }

        return collection;
    }

    public async Task<string> GetParcelasCsvAsync(Guid? projetoId, CancellationToken ct = default)
    {
        var query = parcelas.Query();
        if (projetoId is not null) query = query.Where(p => p.ProjetoId == projetoId);

        var items = await query.OrderBy(p => p.CodigoCadastral).Take(20000).ToListAsync(ct);

        var sb = new StringBuilder();
        sb.AppendLine("codigo_cadastral,numero_parcela,numero_talhao,situacao,uso_atual,uso_previsto,estado,area_calculada_m2,perimetro_m,created_at");
        foreach (var p in items)
        {
            sb.AppendLine(string.Join(',',
                CsvField(p.CodigoCadastral),
                CsvField(p.NumeroParcela),
                CsvField(p.NumeroTalhao),
                CsvField(p.Situacao.ToString()),
                CsvField(p.UsoAtual?.ToString()),
                CsvField(p.UsoPrevisto?.ToString()),
                CsvField(p.Estado.ToString()),
                (p.AreaCalculada ?? 0).ToString(CultureInfo.InvariantCulture),
                (p.Perimetro ?? 0).ToString(CultureInfo.InvariantCulture),
                p.CreatedAt.ToString("O", CultureInfo.InvariantCulture)));
        }

        return sb.ToString();
    }

    private static string CsvField(string? value)
    {
        if (string.IsNullOrEmpty(value)) return "";
        var escaped = value.Replace("\"", "\"\"");
        return value.Contains(',') || value.Contains('"') || value.Contains('\n') ? $"\"{escaped}\"" : escaped;
    }
}
