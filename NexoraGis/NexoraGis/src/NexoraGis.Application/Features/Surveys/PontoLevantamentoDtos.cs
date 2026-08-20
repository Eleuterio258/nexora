using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Surveys;

public record PontoLevantamentoDto(
    Guid Id, Guid LevantamentoId, string? Codigo, Point Geometria, decimal? Altitude,
    decimal? PrecisaoHorizontal, decimal? PrecisaoVertical, decimal? Latitude, decimal? Longitude,
    string? SistemaReferencia, string? Operador, DateTimeOffset? DataHora, IReadOnlyList<string> Fotografias,
    string? Observacoes, bool Sincronizado, DateTimeOffset CreatedAt);

/// <summary>
/// Um ponto recolhido em campo (app móvel ou equipamento GNSS/RTK externo).
/// <paramref name="ClientId"/> é gerado no dispositivo/app de origem e funciona
/// como chave de idempotência: reenviar o mesmo ponto (retry após falha de
/// rede) nunca cria duplicados.
/// </summary>
public record SyncPontoItem(
    Guid ClientId,
    string? Codigo,
    Point Geometria,
    decimal? Altitude,
    decimal? PrecisaoHorizontal,
    decimal? PrecisaoVertical,
    string? SistemaReferencia,
    string? Operador,
    DateTimeOffset? DataHora,
    List<string>? Fotografias,
    string? Observacoes);

public record SyncPontosRequest(Guid LevantamentoId, IReadOnlyList<SyncPontoItem> Pontos);

/// <summary>Conflict = mesmo ClientId de um ponto já sincronizado, mas com dados diferentes (ver SyncConflito).</summary>
public enum SyncPontoStatus { Created, Duplicate, Rejected, Conflict }

public record SyncPontoResult(Guid ClientId, SyncPontoStatus Status, string? Error);

/// <summary>
/// Job de sincronização em fila (backlog 4.2.4): o pedido HTTP só persiste o
/// lote e devolve este estado inicial (Pendente) — o processamento real
/// acontece em segundo plano; o cliente consulta o resultado via GetJobAsync.
/// </summary>
public record SyncJobDto(
    Guid Id,
    Guid LevantamentoId,
    SyncJobStatus Status,
    int TotalPontos,
    int Processados,
    int Criados,
    int Duplicados,
    int EmConflito,
    int Rejeitados,
    string? ErroMensagem,
    IReadOnlyList<SyncPontoResult>? Resultados,
    DateTimeOffset CreatedAt,
    DateTimeOffset? StartedAt,
    DateTimeOffset? CompletedAt);

/// <summary>Conflito de sincronização pendente de resolução (backlog 4.2.3).</summary>
public record SyncConflitoDto(
    Guid Id,
    Guid LevantamentoId,
    Guid PontoLevantamentoId,
    SyncConflitoStatus Status,
    SyncPontoItem DadosIncoming,
    Guid? ResolvidoPor,
    DateTimeOffset? DataResolucao,
    DateTimeOffset CreatedAt);

/// <summary>AplicarNovo=true substitui o ponto existente pelos dados recebidos; false mantém o existente e descarta os novos.</summary>
public record ResolveSyncConflitoRequest(bool AplicarNovo);
