using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Cadastro;

public class Levantamento
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    public string Codigo { get; set; } = string.Empty;
    public string? Designacao { get; set; }

    public Guid? ResponsavelId { get; set; }
    public Utilizador? Responsavel { get; set; }

    public TipoLevantamento Tipo { get; set; }
    public string? EquipamentoUtilizado { get; set; }
    public string? Metodo { get; set; }
    public DateTimeOffset? DataInicio { get; set; }
    public DateTimeOffset? DataFim { get; set; }
    public string Status { get; set; } = "em_curso";
    public string? Observacoes { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<PontoLevantamento> Pontos { get; set; } = new List<PontoLevantamento>();
}
