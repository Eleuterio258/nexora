using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Surveys;

public class LevantamentoService(
    IRepository<Levantamento> levantamentos,
    IRepository<Projeto> projetos,
    IRepository<Utilizador> utilizadores,
    IRepository<PontoLevantamento> pontos,
    IUnitOfWork unitOfWork)
{
    public async Task<Result<LevantamentoDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var levantamento = await levantamentos.GetByIdAsync(id, ct);
        if (levantamento is null)
            return Result.Failure<LevantamentoDto>(NotFound(id));

        var total = await pontos.Query().CountAsync(p => p.LevantamentoId == id, ct);
        return ToDto(levantamento, total);
    }

    public async Task<PagedResult<LevantamentoDto>> ListAsync(Guid? projetoId, string? status, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = levantamentos.Query();
        if (projetoId is not null) query = query.Where(l => l.ProjetoId == projetoId);
        if (!string.IsNullOrWhiteSpace(status)) query = query.Where(l => l.Status == status);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(l => l.CreatedAt).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        var counts = await pontos.Query()
            .Where(p => items.Select(l => l.Id).Contains(p.LevantamentoId))
            .GroupBy(p => p.LevantamentoId)
            .Select(g => new { LevantamentoId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.LevantamentoId, g => g.Count, ct);

        var dtos = items.Select(l => ToDto(l, counts.GetValueOrDefault(l.Id))).ToList();
        return new PagedResult<LevantamentoDto>(dtos, page, pageSize, totalCount);
    }

    public async Task<Result<LevantamentoDto>> CreateAsync(CreateLevantamentoRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo))
            return Result.Failure<LevantamentoDto>(Error.Validation("Levantamento.Invalid", "Código é obrigatório."));

        if (!await projetos.ExistsAsync(request.ProjetoId, ct))
            return Result.Failure<LevantamentoDto>(Error.Validation("Levantamento.ProjetoNotFound", "Projeto indicado não existe."));

        if (request.ResponsavelId is not null && !await utilizadores.ExistsAsync(request.ResponsavelId.Value, ct))
            return Result.Failure<LevantamentoDto>(Error.Validation("Levantamento.ResponsavelNotFound", "Responsável indicado não existe."));

        if (await levantamentos.Query().AnyAsync(l => l.Codigo == request.Codigo, ct))
            return Result.Failure<LevantamentoDto>(Error.Conflict("Levantamento.DuplicateCodigo", $"Já existe um levantamento com o código '{request.Codigo}'."));

        var levantamento = new Levantamento
        {
            ProjetoId = request.ProjetoId,
            Codigo = request.Codigo,
            Designacao = request.Designacao,
            ResponsavelId = request.ResponsavelId,
            Tipo = request.Tipo,
            EquipamentoUtilizado = request.EquipamentoUtilizado,
            Metodo = request.Metodo,
            DataInicio = request.DataInicio ?? DateTimeOffset.UtcNow,
            Status = "em_curso",
            Observacoes = request.Observacoes
        };

        await levantamentos.AddAsync(levantamento, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(levantamento, 0);
    }

    public async Task<Result<LevantamentoDto>> UpdateStatusAsync(Guid id, UpdateLevantamentoStatusRequest request, CancellationToken ct = default)
    {
        var levantamento = await levantamentos.GetByIdAsync(id, ct);
        if (levantamento is null)
            return Result.Failure<LevantamentoDto>(NotFound(id));

        if (string.IsNullOrWhiteSpace(request.Status))
            return Result.Failure<LevantamentoDto>(Error.Validation("Levantamento.Invalid", "Estado é obrigatório."));

        levantamento.Status = request.Status;
        if (request.DataFim is not null) levantamento.DataFim = request.DataFim;
        if (request.Observacoes is not null) levantamento.Observacoes = request.Observacoes;
        levantamento.UpdatedAt = DateTimeOffset.UtcNow;

        await levantamentos.UpdateAsync(levantamento, ct);
        await unitOfWork.SaveChangesAsync(ct);

        var total = await pontos.Query().CountAsync(p => p.LevantamentoId == id, ct);
        return ToDto(levantamento, total);
    }

    public async Task<Result<IReadOnlyList<PontoLevantamentoDto>>> ListPointsAsync(Guid levantamentoId, CancellationToken ct = default)
    {
        if (!await levantamentos.ExistsAsync(levantamentoId, ct))
            return Result.Failure<IReadOnlyList<PontoLevantamentoDto>>(NotFound(levantamentoId));

        var items = await pontos.Query()
            .Where(p => p.LevantamentoId == levantamentoId)
            .OrderByDescending(p => p.DataHora)
            .ToListAsync(ct);

        return Result.Success<IReadOnlyList<PontoLevantamentoDto>>(items.Select(ToPointDto).ToList());
    }

    private static Error NotFound(Guid id) => Error.NotFound("Levantamento.NotFound", $"Levantamento '{id}' não encontrado.");

    private static PontoLevantamentoDto ToPointDto(PontoLevantamento p) => new(
        p.Id, p.LevantamentoId, p.Codigo, p.Geometria, p.Altitude, p.PrecisaoHorizontal, p.PrecisaoVertical,
        p.Latitude, p.Longitude, p.SistemaReferencia, p.Operador, p.DataHora, p.Fotografias, p.Observacoes,
        p.Sincronizado, p.CreatedAt);

    private static LevantamentoDto ToDto(Levantamento l, int totalPontos) => new(
        l.Id, l.ProjetoId, l.Codigo, l.Designacao, l.ResponsavelId, l.Tipo, l.EquipamentoUtilizado, l.Metodo,
        l.DataInicio, l.DataFim, l.Status, l.Observacoes, totalPontos, l.CreatedAt, l.UpdatedAt);
}
