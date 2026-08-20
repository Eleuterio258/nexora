using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Cadastro;

public class Edificacao
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ParcelaId { get; set; }
    public Parcela Parcela { get; set; } = null!;

    public string Codigo { get; set; } = string.Empty;
    public string? Localizacao { get; set; }
    public MultiPolygon? Geometria { get; set; }
    public decimal? AreaConstruida { get; set; }
    public int? NumeroPisos { get; set; }
    public string? TipoConstrucao { get; set; }
    public UsoSolo? Finalidade { get; set; }
    public string? MaterialPredominante { get; set; }
    public string? EstadoConservacao { get; set; }
    public string? SituacaoOcupacao { get; set; }
    public List<string> Fotografias { get; set; } = new();
    public Point? Coordenadas { get; set; }
    public DateOnly? DataLevantamento { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
