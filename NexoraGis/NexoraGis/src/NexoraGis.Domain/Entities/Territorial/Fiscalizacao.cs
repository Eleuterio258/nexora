using NetTopologySuite.Geometries;
using NexoraGis.Domain.Entities.Cadastro;

namespace NexoraGis.Domain.Entities.Territorial;

public class Fiscalizacao
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    public Guid? ParcelaId { get; set; }
    public Parcela? Parcela { get; set; }

    public Guid? FiscalId { get; set; }
    public Utilizador? Fiscal { get; set; }

    public DateTimeOffset DataOcorrencia { get; set; } = DateTimeOffset.UtcNow;
    public Point? Coordenadas { get; set; }
    public string Descricao { get; set; } = string.Empty;
    public List<string> Fotografias { get; set; } = new();
    public string Estado { get; set; } = "aberto";
    public string? AcaoNecessaria { get; set; }

    public Guid? Responsavel { get; set; }
    public Utilizador? ResponsavelUtilizador { get; set; }

    public DateTimeOffset? DataResolucao { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
