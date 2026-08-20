using System.Globalization;
using System.Text;
using NetTopologySuite.Geometries;

namespace NexoraGis.Infrastructure.Services;

/// <summary>
/// Desenha geometrias NTS como SVG (a API Canvas/SKCanvas do QuestPDF foi
/// removida em runtime nas versões recentes — .Svg() é a substituição
/// recomendada). Reescala a área envolvente para caber no espaço disponível.
/// Puramente esquemático: não aplica nenhuma projeção cartográfica, só um
/// "fit to box" linear — correto o suficiente para dar noção de forma/
/// posição relativa numa parcela ou projecto pequeno, não para medições.
/// </summary>
internal static class GeometrySvg
{
    private const double Padding = 16;

    public static string RenderSingle(double width, double height, Geometry geometria, string hexColor) =>
        RenderMany(width, height, [(geometria, hexColor)]);

    public static string RenderMany(double width, double height, IReadOnlyList<(Geometry Geometria, string HexColor)> items)
    {
        var empty = $"""<svg xmlns="http://www.w3.org/2000/svg" width="{Fmt(width)}" height="{Fmt(height)}"></svg>""";
        if (items.Count == 0) return empty;

        var envelope = new Envelope();
        foreach (var (geometria, _) in items)
            envelope.ExpandToInclude(geometria.EnvelopeInternal);

        if (envelope.IsNull || envelope.Width == 0 || envelope.Height == 0)
            return empty;

        var availableWidth = width - 2 * Padding;
        var availableHeight = height - 2 * Padding;
        var scale = Math.Min(availableWidth / envelope.Width, availableHeight / envelope.Height);

        (double X, double Y) ToScreen(Coordinate c) =>
            (Padding + (c.X - envelope.MinX) * scale, Padding + (envelope.MaxY - c.Y) * scale);

        var sb = new StringBuilder();
        sb.Append($"""<svg xmlns="http://www.w3.org/2000/svg" width="{Fmt(width)}" height="{Fmt(height)}" viewBox="0 0 {Fmt(width)} {Fmt(height)}">""");

        foreach (var (geometria, hexColor) in items)
        {
            foreach (var polygon in ExtractPolygons(geometria))
            {
                var ring = polygon.ExteriorRing?.Coordinates;
                if (ring is null || ring.Length == 0) continue;

                var path = new StringBuilder("M ").Append(FmtPoint(ToScreen(ring[0])));
                for (var i = 1; i < ring.Length; i++)
                    path.Append(" L ").Append(FmtPoint(ToScreen(ring[i])));
                path.Append(" Z");

                sb.Append($"""<path d="{path}" fill="{hexColor}" fill-opacity="0.45" stroke="{hexColor}" stroke-width="1.5" />""");
            }
        }

        sb.Append("</svg>");
        return sb.ToString();
    }

    private static string Fmt(double v) => v.ToString(CultureInfo.InvariantCulture);
    private static string FmtPoint((double X, double Y) p) => $"{Fmt(p.X)},{Fmt(p.Y)}";

    private static IEnumerable<Polygon> ExtractPolygons(Geometry geometry)
    {
        switch (geometry)
        {
            case Polygon p:
                yield return p;
                break;
            case MultiPolygon mp:
                foreach (var g in mp.Geometries) yield return (Polygon)g;
                break;
            case GeometryCollection gc:
                foreach (var g in gc.Geometries)
                foreach (var p in ExtractPolygons(g))
                    yield return p;
                break;
        }
    }
}
