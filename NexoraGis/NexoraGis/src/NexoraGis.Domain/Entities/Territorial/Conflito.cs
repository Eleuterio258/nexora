using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Territorial;

public class Conflito
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    public TipoConflito Tipo { get; set; }
    public string Descricao { get; set; } = string.Empty;
    public string? EntidadeTipo { get; set; }
    public Guid? EntidadeId { get; set; }
    public Geometry? Geometria { get; set; }
    public string? Detalhes { get; set; }

    public bool Resolvido { get; set; }
    public DateTimeOffset DataDetecao { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? DataResolucao { get; set; }

    public Guid? ResolvidoPor { get; set; }
    public Utilizador? ResolvidoPorUtilizador { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
