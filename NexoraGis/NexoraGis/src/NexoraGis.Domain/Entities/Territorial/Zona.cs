using NetTopologySuite.Geometries;

namespace NexoraGis.Domain.Entities.Territorial;

public class Zona
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid PlanoId { get; set; }
    public Plano Plano { get; set; } = null!;

    /// <summary>Código de classificação: ZH, ZC, ZS, ZM, ZI, ZA, ZE, ZV, ZT, ZP, ZEX, etc.</summary>
    public string Codigo { get; set; } = string.Empty;
    public string Designacao { get; set; } = string.Empty;
    public string Cor { get; set; } = "#000000";

    public MultiPolygon? Geometria { get; set; }

    /// <summary>jsonb: altura máxima, pisos, ocupação, afastamentos, área mínima, etc.</summary>
    public string? Parametros { get; set; }

    public List<string> AtividadesPermitidas { get; set; } = new();
    public List<string> AtividadesCondicionadas { get; set; } = new();
    public List<string> AtividadesProibidas { get; set; } = new();

    /// <summary>Coluna gerada (STORED) na BD.</summary>
    public decimal? AreaCalculada { get; private set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
