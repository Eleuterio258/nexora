using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Territorial;

public class Projeto
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid OrganizacaoId { get; set; }
    public Organizacao Organizacao { get; set; } = null!;

    public string Codigo { get; set; } = string.Empty;
    public string Designacao { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public string? Cliente { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public string? Localizacao { get; set; }

    public Guid? DivisaoAdministrativaId { get; set; }
    public DivisaoAdministrativa? DivisaoAdministrativa { get; set; }

    public MultiPolygon? AreaIntervencao { get; set; }
    public string SistemaReferencia { get; set; } = "WGS84 / UTM 36S / 37S";

    public Guid? ResponsavelTecnicoId { get; set; }
    public Utilizador? ResponsavelTecnico { get; set; }

    public DateOnly? DataInicio { get; set; }
    public DateOnly? DataPrevistaConclusao { get; set; }
    public ProjectStatus Status { get; set; } = ProjectStatus.Rascunho;

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    public Guid? CreatedBy { get; set; }
    public Utilizador? CreatedByUtilizador { get; set; }

    public ICollection<ProjetoEquipa> Equipa { get; set; } = new List<ProjetoEquipa>();
    public ICollection<Plano> Planos { get; set; } = new List<Plano>();
}
