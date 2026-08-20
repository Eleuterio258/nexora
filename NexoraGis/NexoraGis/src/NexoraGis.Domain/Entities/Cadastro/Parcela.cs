using NetTopologySuite.Geometries;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Cadastro;

public class Parcela
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    public string CodigoCadastral { get; set; } = string.Empty;
    public string? NumeroParcela { get; set; }
    public string? NumeroTalhao { get; set; }

    public Guid? DivisaoAdministrativaId { get; set; }
    public DivisaoAdministrativa? DivisaoAdministrativa { get; set; }

    public MultiPolygon Geometria { get; set; } = null!;

    /// <summary>Colunas geradas (STORED) na BD a partir de Geometria.</summary>
    public Point? Centroide { get; private set; }
    public decimal? AreaCalculada { get; private set; }
    public decimal? Perimetro { get; private set; }

    public string SistemaCoordenadas { get; set; } = "EPSG:4326";
    public decimal? PrecisaoLevantamento { get; set; }

    public SituacaoParcela Situacao { get; set; } = SituacaoParcela.Desocupada;
    public UsoSolo? UsoAtual { get; set; }
    public UsoSolo? UsoPrevisto { get; set; }
    public string? ClassificacaoPlano { get; set; }
    public string? ParametrosUrbanisticos { get; set; }
    public string? Restricoes { get; set; }
    public string? Condicionantes { get; set; }

    public ApprovalStatus Estado { get; set; } = ApprovalStatus.Rascunho;
    public int Versao { get; set; } = 1;

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public Guid? CreatedBy { get; set; }
    public Guid? UpdatedBy { get; set; }

    public ICollection<Lote> Lotes { get; set; } = new List<Lote>();
    public ICollection<Edificacao> Edificacoes { get; set; } = new List<Edificacao>();
    public ICollection<ParcelaEntidade> Entidades { get; set; } = new List<ParcelaEntidade>();
}
