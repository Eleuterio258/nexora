using NetTopologySuite.Geometries;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Cadastro;

public class Infraestrutura
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    public TipoInfraestrutura Tipo { get; set; }

    /// <summary>Subtipo livre: estrada, conduta, poste, torre, etc.</summary>
    public string Subtipo { get; set; } = string.Empty;
    public string? Codigo { get; set; }
    public string? Designacao { get; set; }

    /// <summary>Ponto, linha ou polígono conforme o tipo de infraestrutura.</summary>
    public Geometry? Geometria { get; set; }

    public string? Atributos { get; set; }
    public string? EstadoConservacao { get; set; }
    public DateOnly? DataLevantamento { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
