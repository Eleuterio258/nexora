using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Surveys;

/// <summary>
/// Sincronização de pontos de levantamento recolhidos offline (app de campo)
/// ou recebidos de equipamento GNSS/RTK externo. Fluxo (§9 do documento
/// funcional; backlog 4.2): Dispositivo → API → fila → validação → PostGIS.
///
/// O pedido HTTP só valida e persiste o lote como <see cref="SyncJob"/>
/// (backlog 4.2.4) — o processamento pesado corre em segundo plano via
/// <see cref="ProcessNextPendingJobAsync"/>, para lotes grandes não
/// bloquearem o dispositivo de campo. Conflitos de dados (mesmo ClientId,
/// dados diferentes) ficam registados como <see cref="SyncConflito"/> em vez
/// de serem aplicados às cegas (backlog 4.2.3).
/// </summary>
public class SyncService(
    IRepository<PontoLevantamento> pontos,
    IRepository<Levantamento> levantamentos,
    IRepository<SyncJob> jobs,
    IRepository<SyncConflito> conflitos,
    ICurrentUserService currentUser,
    IUnitOfWork unitOfWork)
{
    private const int MaxBatchSize = 500;

    public async Task<Result<SyncJobDto>> EnqueueAsync(SyncPontosRequest request, CancellationToken ct = default)
    {
        if (request.Pontos.Count == 0)
            return Result.Failure<SyncJobDto>(Error.Validation("Sync.EmptyBatch", "O lote não contém pontos."));

        if (request.Pontos.Count > MaxBatchSize)
            return Result.Failure<SyncJobDto>(Error.Validation("Sync.BatchTooLarge", $"Máximo de {MaxBatchSize} pontos por lote."));

        if (!await levantamentos.ExistsAsync(request.LevantamentoId, ct))
            return Result.Failure<SyncJobDto>(Error.Validation("Sync.LevantamentoNotFound", "Levantamento indicado não existe."));

        var job = new SyncJob
        {
            LevantamentoId = request.LevantamentoId,
            Payload = JsonSerializer.Serialize(request, SyncJsonOptions.Default),
            TotalPontos = request.Pontos.Count,
            CreatedBy = currentUser.UtilizadorId
        };

        await jobs.AddAsync(job, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToJobDto(job);
    }

    public async Task<Result<SyncJobDto>> GetJobAsync(Guid id, CancellationToken ct = default)
    {
        var job = await jobs.GetByIdAsync(id, ct);
        return job is null ? Result.Failure<SyncJobDto>(JobNotFound(id)) : ToJobDto(job);
    }

    public async Task<PagedResult<SyncJobDto>> ListJobsAsync(
        Guid? levantamentoId, SyncJobStatus? status, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = jobs.Query();
        if (levantamentoId is not null) query = query.Where(j => j.LevantamentoId == levantamentoId);
        if (status is not null) query = query.Where(j => j.Status == status);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(j => j.CreatedAt).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<SyncJobDto>(items.Select(ToJobDto).ToList(), page, pageSize, totalCount);
    }

    /// <summary>
    /// Processa o job de sincronização pendente mais antigo. Chamado
    /// repetidamente pelo worker em segundo plano (backlog 4.2.4). Devolve
    /// false quando não há nenhum job pendente.
    /// </summary>
    public async Task<bool> ProcessNextPendingJobAsync(CancellationToken ct = default)
    {
        var job = await jobs.Query()
            .Where(j => j.Status == SyncJobStatus.Pendente)
            .OrderBy(j => j.CreatedAt)
            .FirstOrDefaultAsync(ct);

        if (job is null)
            return false;

        job.Status = SyncJobStatus.EmProcessamento;
        job.StartedAt = DateTimeOffset.UtcNow;
        await jobs.UpdateAsync(job, ct);
        await unitOfWork.SaveChangesAsync(ct);

        try
        {
            var request = JsonSerializer.Deserialize<SyncPontosRequest>(job.Payload, SyncJsonOptions.Default)
                ?? throw new InvalidOperationException("Payload do job de sincronização inválido.");

            var resultados = await ProcessPontosAsync(job.LevantamentoId, request.Pontos, ct);

            job.Resultados = JsonSerializer.Serialize(resultados, SyncJsonOptions.Default);
            job.Processados = resultados.Count;
            job.Criados = resultados.Count(r => r.Status == SyncPontoStatus.Created);
            job.Duplicados = resultados.Count(r => r.Status == SyncPontoStatus.Duplicate);
            job.EmConflito = resultados.Count(r => r.Status == SyncPontoStatus.Conflict);
            job.Rejeitados = resultados.Count(r => r.Status == SyncPontoStatus.Rejected);
            job.Status = SyncJobStatus.Concluido;
        }
        catch (Exception ex)
        {
            job.Status = SyncJobStatus.Falhou;
            job.ErroMensagem = ex.Message;
        }

        job.CompletedAt = DateTimeOffset.UtcNow;
        await jobs.UpdateAsync(job, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return true;
    }

    public async Task<PagedResult<SyncConflitoDto>> ListConflictsAsync(
        Guid? levantamentoId, SyncConflitoStatus? status, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = conflitos.Query().Where(c => c.Status == (status ?? SyncConflitoStatus.Pendente));
        if (levantamentoId is not null) query = query.Where(c => c.LevantamentoId == levantamentoId);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderBy(c => c.CreatedAt).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<SyncConflitoDto>(items.Select(ToConflitoDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<SyncConflitoDto>> ResolveConflictAsync(Guid id, ResolveSyncConflitoRequest request, CancellationToken ct = default)
    {
        var conflito = await conflitos.GetByIdAsync(id, ct);
        if (conflito is null)
            return Result.Failure<SyncConflitoDto>(Error.NotFound("SyncConflito.NotFound", $"Conflito '{id}' não encontrado."));

        if (conflito.Status != SyncConflitoStatus.Pendente)
            return Result.Failure<SyncConflitoDto>(Error.Conflict("SyncConflito.AlreadyResolved", "Este conflito já foi resolvido."));

        if (request.AplicarNovo)
        {
            var ponto = await pontos.GetByIdAsync(conflito.PontoLevantamentoId, ct);
            if (ponto is null)
                return Result.Failure<SyncConflitoDto>(Error.NotFound("PontoLevantamento.NotFound", "Ponto associado ao conflito não existe."));

            var item = JsonSerializer.Deserialize<SyncPontoItem>(conflito.DadosIncoming, SyncJsonOptions.Default)
                ?? throw new InvalidOperationException("Dados do conflito inválidos.");

            ApplyIncoming(ponto, item);
            await pontos.UpdateAsync(ponto, ct);
            conflito.Status = SyncConflitoStatus.ResolvidoAplicarNovo;
        }
        else
        {
            conflito.Status = SyncConflitoStatus.ResolvidoManterExistente;
        }

        conflito.ResolvidoPor = currentUser.UtilizadorId;
        conflito.DataResolucao = DateTimeOffset.UtcNow;

        await conflitos.UpdateAsync(conflito, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToConflitoDto(conflito);
    }

    private async Task<List<SyncPontoResult>> ProcessPontosAsync(Guid levantamentoId, IReadOnlyList<SyncPontoItem> items, CancellationToken ct)
    {
        var clientIds = items.Select(p => p.ClientId).ToList();
        var existentes = await pontos.Query()
            .Where(p => clientIds.Contains(p.Id))
            .ToDictionaryAsync(p => p.Id, ct);

        var resultados = new List<SyncPontoResult>();
        var vistosNesteLote = new HashSet<Guid>();

        foreach (var item in items)
        {
            if (!vistosNesteLote.Add(item.ClientId))
            {
                resultados.Add(new SyncPontoResult(item.ClientId, SyncPontoStatus.Duplicate, "Repetido dentro do mesmo lote."));
                continue;
            }

            if (existentes.TryGetValue(item.ClientId, out var existente))
            {
                if (IsSameData(existente, item))
                {
                    resultados.Add(new SyncPontoResult(item.ClientId, SyncPontoStatus.Duplicate, "Já sincronizado anteriormente."));
                }
                else
                {
                    await conflitos.AddAsync(new SyncConflito
                    {
                        LevantamentoId = levantamentoId,
                        PontoLevantamentoId = existente.Id,
                        DadosIncoming = JsonSerializer.Serialize(item, SyncJsonOptions.Default)
                    }, ct);
                    resultados.Add(new SyncPontoResult(item.ClientId, SyncPontoStatus.Conflict, "Dados diferentes do ponto já sincronizado — pendente de resolução."));
                }
                continue;
            }

            var erro = ValidatePonto(item);
            if (erro is not null)
            {
                resultados.Add(new SyncPontoResult(item.ClientId, SyncPontoStatus.Rejected, erro));
                continue;
            }

            await pontos.AddAsync(ToEntity(levantamentoId, item), ct);
            resultados.Add(new SyncPontoResult(item.ClientId, SyncPontoStatus.Created, null));
        }

        await unitOfWork.SaveChangesAsync(ct);
        return resultados;
    }

    private static bool IsSameData(PontoLevantamento existente, SyncPontoItem incoming) =>
        existente.Geometria.EqualsExact(incoming.Geometria)
        && existente.Altitude == incoming.Altitude
        && existente.PrecisaoHorizontal == incoming.PrecisaoHorizontal
        && existente.PrecisaoVertical == incoming.PrecisaoVertical
        && existente.Codigo == incoming.Codigo
        && existente.Observacoes == incoming.Observacoes;

    private static void ApplyIncoming(PontoLevantamento ponto, SyncPontoItem item)
    {
        ponto.Codigo = item.Codigo;
        ponto.Geometria = item.Geometria;
        ponto.Altitude = item.Altitude;
        ponto.PrecisaoHorizontal = item.PrecisaoHorizontal;
        ponto.PrecisaoVertical = item.PrecisaoVertical;
        ponto.Latitude = (decimal)item.Geometria.Y;
        ponto.Longitude = (decimal)item.Geometria.X;
        ponto.SistemaReferencia = item.SistemaReferencia;
        ponto.Operador = item.Operador;
        if (item.DataHora is not null) ponto.DataHora = item.DataHora;
        if (item.Fotografias is not null) ponto.Fotografias = item.Fotografias;
        ponto.Observacoes = item.Observacoes;
    }

    private static PontoLevantamento ToEntity(Guid levantamentoId, SyncPontoItem item) => new()
    {
        Id = item.ClientId,
        LevantamentoId = levantamentoId,
        Codigo = item.Codigo,
        Geometria = item.Geometria,
        Altitude = item.Altitude,
        PrecisaoHorizontal = item.PrecisaoHorizontal,
        PrecisaoVertical = item.PrecisaoVertical,
        Latitude = (decimal)item.Geometria.Y,
        Longitude = (decimal)item.Geometria.X,
        SistemaReferencia = item.SistemaReferencia,
        Operador = item.Operador,
        DataHora = item.DataHora ?? DateTimeOffset.UtcNow,
        Fotografias = item.Fotografias ?? [],
        Observacoes = item.Observacoes,
        Sincronizado = true
    };

    private static string? ValidatePonto(SyncPontoItem item)
    {
        if (!item.Geometria.IsValid)
            return "Geometria inválida.";

        if (item.Geometria.Y is < -90 or > 90)
            return "Latitude fora do intervalo [-90, 90].";

        if (item.Geometria.X is < -180 or > 180)
            return "Longitude fora do intervalo [-180, 180].";

        return null;
    }

    private static Error JobNotFound(Guid id) => Error.NotFound("SyncJob.NotFound", $"Job de sincronização '{id}' não encontrado.");

    private static SyncJobDto ToJobDto(SyncJob j) => new(
        j.Id, j.LevantamentoId, j.Status, j.TotalPontos, j.Processados, j.Criados, j.Duplicados, j.EmConflito, j.Rejeitados,
        j.ErroMensagem,
        j.Resultados is null ? null : JsonSerializer.Deserialize<IReadOnlyList<SyncPontoResult>>(j.Resultados, SyncJsonOptions.Default),
        j.CreatedAt, j.StartedAt, j.CompletedAt);

    private static SyncConflitoDto ToConflitoDto(SyncConflito c) => new(
        c.Id, c.LevantamentoId, c.PontoLevantamentoId, c.Status,
        JsonSerializer.Deserialize<SyncPontoItem>(c.DadosIncoming, SyncJsonOptions.Default)!,
        c.ResolvidoPor, c.DataResolucao, c.CreatedAt);
}
