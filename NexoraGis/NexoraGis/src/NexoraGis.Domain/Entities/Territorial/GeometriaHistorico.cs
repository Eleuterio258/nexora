using NetTopologySuite.Geometries;
using NexoraGis.Domain.Entities.Workflow;

namespace NexoraGis.Domain.Entities.Territorial;

/// <summary>Versionamento de geometrias: nunca sobrescrever, guardar anterior/nova.</summary>
public class GeometriaHistorico
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string EntidadeTipo { get; set; } = string.Empty;
    public Guid EntidadeId { get; set; }

    public Guid? ProjetoId { get; set; }
    public Projeto? Projeto { get; set; }

    public Geometry? GeometriaAnterior { get; set; }
    public Geometry? GeometriaNova { get; set; }

    public Guid? UtilizadorId { get; set; }
    public Utilizador? Utilizador { get; set; }

    public DateTimeOffset DataAlteracao { get; set; } = DateTimeOffset.UtcNow;
    public string? Motivo { get; set; }
    public int? VersaoAnterior { get; set; }
    public int? VersaoNova { get; set; }

    public Guid? AprovacaoId { get; set; }
    public Aprovacao? Aprovacao { get; set; }
}
