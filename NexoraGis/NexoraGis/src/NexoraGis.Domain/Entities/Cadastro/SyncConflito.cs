using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Cadastro;

/// <summary>
/// Conflito de sincronização (backlog 4.2.3): um ponto recebido com o mesmo
/// ClientId de um ponto já sincronizado, mas com dados diferentes. Nunca é
/// aplicado automaticamente — fica pendente até um técnico decidir manter o
/// ponto existente ou aplicar os dados novos.
/// </summary>
public class SyncConflito
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid LevantamentoId { get; set; }
    public Levantamento Levantamento { get; set; } = null!;

    /// <summary>Também o ClientId original — o Id de PontoLevantamento É o ClientId gerado em campo.</summary>
    public Guid PontoLevantamentoId { get; set; }
    public PontoLevantamento PontoLevantamento { get; set; } = null!;

    /// <summary>jsonb: SyncPontoItem recebido (dados novos, ainda não aplicados).</summary>
    public string DadosIncoming { get; set; } = string.Empty;

    public SyncConflitoStatus Status { get; set; } = SyncConflitoStatus.Pendente;

    public Guid? ResolvidoPor { get; set; }
    public DateTimeOffset? DataResolucao { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
