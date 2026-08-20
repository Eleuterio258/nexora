using NetTopologySuite.Geometries;
using NexoraGis.Domain.Entities.Territorial;

namespace NexoraGis.Domain.Entities.Cadastro;

/// <summary>Restrição territorial: linha de água, zona inundável, encosta, servidão, etc.</summary>
public class Condicionante
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    public string Tipo { get; set; } = string.Empty;
    public string? Designacao { get; set; }
    public string? Descricao { get; set; }
    public Geometry? Geometria { get; set; }
    public decimal? BufferMetros { get; set; }
    public bool Restritivo { get; set; } = true;
    public string? Atributos { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
