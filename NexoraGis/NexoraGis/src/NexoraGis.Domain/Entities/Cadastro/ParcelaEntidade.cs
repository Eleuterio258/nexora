using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Cadastro;

public class ParcelaEntidade
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ParcelaId { get; set; }
    public Parcela Parcela { get; set; } = null!;

    public Guid EntidadeId { get; set; }
    public Entidade Entidade { get; set; } = null!;

    public TipoEntidade TipoRelacao { get; set; }
    public DateOnly? DataInicio { get; set; }
    public DateOnly? DataFim { get; set; }
    public bool Ativo { get; set; } = true;

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
