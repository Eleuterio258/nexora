using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Territorial;

/// <summary>
/// Nó da hierarquia administrativa de Moçambique (país, província, distrito,
/// posto administrativo, bairro, aldeia, etc.), autorreferenciada via ParentId
/// para suportar profundidade e nomenclatura variável entre municípios.
/// </summary>
public class DivisaoAdministrativa
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid? ParentId { get; set; }
    public DivisaoAdministrativa? Parent { get; set; }
    public ICollection<DivisaoAdministrativa> Filhos { get; set; } = new List<DivisaoAdministrativa>();

    public TipoDivisao Tipo { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nome { get; set; } = string.Empty;
    public string? NomeNormalizado { get; set; }

    /// <summary>TRUE = urbano, FALSE = rural, NULL = misto/não aplicável.</summary>
    public bool? ZonaUrbana { get; set; }

    public int NivelHierarquico { get; set; }
    public string? EntidadeResponsavel { get; set; }
    public string? CodigoIne { get; set; }

    public MultiPolygon? Geometria { get; set; }

    /// <summary>Coluna gerada (STORED) na BD: hectares a partir de Geometria.</summary>
    public decimal? AreaCalculada { get; private set; }

    /// <summary>Coluna gerada (STORED) na BD: centroide de Geometria.</summary>
    public Point? Centroide { get; private set; }

    public bool Ativo { get; set; } = true;
    public string? Metadados { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public Guid? CreatedBy { get; set; }
    public Guid? UpdatedBy { get; set; }
}
