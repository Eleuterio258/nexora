using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Inspections;

/// <summary>
/// Fiscalização territorial (backlog 8.3): registo de ocorrências em campo
/// (fotografia, coordenada, descrição) e workflow simples de resolução
/// (aberto → em_analise → resolvido), tal como já modelado em
/// Fiscalizacao.Estado desde a Fase 1.
/// </summary>
public class FiscalizacaoService(
    IRepository<Fiscalizacao> fiscalizacoes,
    IRepository<Projeto> projetos,
    IRepository<Parcela> parcelas,
    ICurrentUserService currentUser,
    IUnitOfWork unitOfWork)
{
    private static readonly string[] EstadosValidos = ["aberto", "em_analise", "resolvido"];

    public async Task<Result<FiscalizacaoDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var fiscalizacao = await fiscalizacoes.GetByIdAsync(id, ct);
        return fiscalizacao is null ? Result.Failure<FiscalizacaoDto>(NotFound(id)) : ToDto(fiscalizacao);
    }

    public async Task<PagedResult<FiscalizacaoDto>> ListAsync(
        Guid? projetoId, Guid? parcelaId, string? estado, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = fiscalizacoes.Query();
        if (projetoId is not null) query = query.Where(f => f.ProjetoId == projetoId);
        if (parcelaId is not null) query = query.Where(f => f.ParcelaId == parcelaId);
        if (!string.IsNullOrWhiteSpace(estado)) query = query.Where(f => f.Estado == estado);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(f => f.DataOcorrencia).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<FiscalizacaoDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<FiscalizacaoDto>> CreateAsync(CreateFiscalizacaoRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Descricao))
            return Result.Failure<FiscalizacaoDto>(Error.Validation("Fiscalizacao.Invalid", "Descrição é obrigatória."));

        if (!await projetos.ExistsAsync(request.ProjetoId, ct))
            return Result.Failure<FiscalizacaoDto>(Error.Validation("Fiscalizacao.ProjetoNotFound", "Projeto indicado não existe."));

        if (request.ParcelaId is not null && !await parcelas.ExistsAsync(request.ParcelaId.Value, ct))
            return Result.Failure<FiscalizacaoDto>(Error.Validation("Fiscalizacao.ParcelaNotFound", "Parcela indicada não existe."));

        var fiscalizacao = new Fiscalizacao
        {
            ProjetoId = request.ProjetoId,
            ParcelaId = request.ParcelaId,
            FiscalId = currentUser.UtilizadorId,
            Coordenadas = request.Coordenadas,
            Descricao = request.Descricao,
            Fotografias = request.Fotografias ?? [],
            AcaoNecessaria = request.AcaoNecessaria,
            Estado = "aberto"
        };

        await fiscalizacoes.AddAsync(fiscalizacao, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(fiscalizacao);
    }

    public async Task<Result<FiscalizacaoDto>> UpdateEstadoAsync(Guid id, UpdateFiscalizacaoEstadoRequest request, CancellationToken ct = default)
    {
        var fiscalizacao = await fiscalizacoes.GetByIdAsync(id, ct);
        if (fiscalizacao is null)
            return Result.Failure<FiscalizacaoDto>(NotFound(id));

        if (!EstadosValidos.Contains(request.Estado))
            return Result.Failure<FiscalizacaoDto>(Error.Validation(
                "Fiscalizacao.InvalidEstado", $"Estado tem de ser um de: {string.Join(", ", EstadosValidos)}."));

        fiscalizacao.Estado = request.Estado;
        if (request.AcaoNecessaria is not null) fiscalizacao.AcaoNecessaria = request.AcaoNecessaria;
        fiscalizacao.Responsavel = currentUser.UtilizadorId;
        fiscalizacao.DataResolucao = request.Estado == "resolvido" ? DateTimeOffset.UtcNow : null;
        fiscalizacao.UpdatedAt = DateTimeOffset.UtcNow;

        await fiscalizacoes.UpdateAsync(fiscalizacao, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(fiscalizacao);
    }

    private static Error NotFound(Guid id) => Error.NotFound("Fiscalizacao.NotFound", $"Ocorrência de fiscalização '{id}' não encontrada.");

    private static FiscalizacaoDto ToDto(Fiscalizacao f) => new(
        f.Id, f.ProjetoId, f.ParcelaId, f.FiscalId, f.DataOcorrencia, f.Coordenadas, f.Descricao, f.Fotografias,
        f.Estado, f.AcaoNecessaria, f.Responsavel, f.DataResolucao, f.CreatedAt, f.UpdatedAt);
}
