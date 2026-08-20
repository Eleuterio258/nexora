using NetTopologySuite.Geometries;

namespace NexoraGis.Application.Tests.TestSupport;

public static class GeometryTestHelper
{
    private static readonly GeometryFactory Factory = new(new PrecisionModel(), 4326);

    /// <summary>Quadrado simples entre (minX,minY) e (maxX,maxY), como MultiPolygon de um único anel.</summary>
    public static MultiPolygon Square(double minX, double minY, double maxX, double maxY)
    {
        var ring = new LinearRing([
            new Coordinate(minX, minY),
            new Coordinate(maxX, minY),
            new Coordinate(maxX, maxY),
            new Coordinate(minX, maxY),
            new Coordinate(minX, minY)
        ]);
        var polygon = Factory.CreatePolygon(ring);
        return Factory.CreateMultiPolygon([polygon]);
    }

    public static Point CenterPoint(double minX, double minY, double maxX, double maxY) =>
        Factory.CreatePoint(new Coordinate((minX + maxX) / 2, (minY + maxY) / 2));
}
