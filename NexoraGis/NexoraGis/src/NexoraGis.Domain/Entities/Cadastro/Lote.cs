using NetTopologySuite.Geometries;

namespace NexoraGis.Domain.Entities.Cadastro;

public class Lote
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ParcelaId { get; set; }
    public Parcela Parcela { get; set; } = null!;

    public string Codigo { get; set; } = string.Empty;
    public MultiPolygon Geometria { get; set; } = null!;

    /// <summary>Coluna gerada (STORED) na BD.</summary>
    public decimal? AreaCalculada { get; private set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
