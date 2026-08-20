using NetTopologySuite.Geometries;

namespace NexoraGis.Domain.Entities.Cadastro;

/// <summary>Ponto recolhido em campo (GNSS/RTK/estação total/drone/etc.), pendente de sincronização.</summary>
public class PontoLevantamento
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid LevantamentoId { get; set; }
    public Levantamento Levantamento { get; set; } = null!;

    public string? Codigo { get; set; }
    public Point Geometria { get; set; } = null!;
    public decimal? Altitude { get; set; }
    public decimal? PrecisaoHorizontal { get; set; }
    public decimal? PrecisaoVertical { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public string? SistemaReferencia { get; set; }
    public string? Operador { get; set; }
    public DateTimeOffset? DataHora { get; set; }
    public List<string> Fotografias { get; set; } = new();
    public string? Observacoes { get; set; }
    public bool Sincronizado { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
