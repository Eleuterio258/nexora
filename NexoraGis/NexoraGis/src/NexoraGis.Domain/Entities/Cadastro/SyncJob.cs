using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Cadastro;

/// <summary>
/// Lote de sincronização submetido pelo dispositivo de campo, processado de
/// forma assíncrona em segundo plano (backlog 4.2.4) para não bloquear o
/// pedido HTTP em lotes grandes.
/// </summary>
public class SyncJob
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid LevantamentoId { get; set; }
    public Levantamento Levantamento { get; set; } = null!;

    public SyncJobStatus Status { get; set; } = SyncJobStatus.Pendente;

    /// <summary>jsonb: SyncPontosRequest original (lote submetido).</summary>
    public string Payload { get; set; } = string.Empty;

    /// <summary>jsonb: lista de SyncPontoResult, preenchida quando o job termina.</summary>
    public string? Resultados { get; set; }

    public int TotalPontos { get; set; }
    public int Processados { get; set; }
    public int Criados { get; set; }
    public int Duplicados { get; set; }
    public int EmConflito { get; set; }
    public int Rejeitados { get; set; }
    public string? ErroMensagem { get; set; }

    public Guid? CreatedBy { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? StartedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
}
