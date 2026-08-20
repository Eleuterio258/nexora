using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Plans;

public class PlanoService(IRepository<Plano> planos, IRepository<Projeto> projetos, IUnitOfWork unitOfWork)
{
    public async Task<Result<PlanoDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var plano = await planos.GetByIdAsync(id, ct);
        return plano is null ? Result.Failure<PlanoDto>(NotFound(id)) : ToDto(plano);
    }

    public async Task<PagedResult<PlanoDto>> ListAsync(
        Guid? projetoId, string? codigo, bool? ativo, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = planos.Query();
        if (projetoId is not null) query = query.Where(p => p.ProjetoId == projetoId);
        if (!string.IsNullOrWhiteSpace(codigo)) query = query.Where(p => p.Codigo == codigo);
        if (ativo is not null) query = query.Where(p => p.Ativo == ativo);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(p => p.CreatedAt).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<PlanoDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    /// <summary>Todas as versões (mesmo Código/Projeto) do plano indicado, da mais antiga à mais recente — backlog 5.1.2.</summary>
    public async Task<Result<IReadOnlyList<PlanoDto>>> ListVersionsAsync(Guid id, CancellationToken ct = default)
    {
        var plano = await planos.GetByIdAsync(id, ct);
        if (plano is null)
            return Result.Failure<IReadOnlyList<PlanoDto>>(NotFound(id));

        var versoes = await planos.Query()
            .Where(p => p.ProjetoId == plano.ProjetoId && p.Codigo == plano.Codigo)
            .OrderBy(p => p.CreatedAt)
            .ToListAsync(ct);

        return Result.Success<IReadOnlyList<PlanoDto>>(versoes.Select(ToDto).ToList());
    }

    public async Task<Result<PlanoDto>> CreateAsync(CreatePlanoRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo) || string.IsNullOrWhiteSpace(request.Designacao))
            return Result.Failure<PlanoDto>(Error.Validation("Plano.Invalid", "Código e designação são obrigatórios."));

        if (!await projetos.ExistsAsync(request.ProjetoId, ct))
            return Result.Failure<PlanoDto>(Error.Validation("Plano.ProjetoNotFound", "Projeto indicado não existe."));

        var versao = string.IsNullOrWhiteSpace(request.Versao) ? "1.0" : request.Versao;

        if (await ExistsVersionAsync(request.ProjetoId, request.Codigo, versao, ct))
            return Result.Failure<PlanoDto>(DuplicateVersion(request.Codigo, versao));

        var plano = new Plano
        {
            ProjetoId = request.ProjetoId,
            Codigo = request.Codigo,
            Designacao = request.Designacao,
            Versao = versao
        };

        await planos.AddAsync(plano, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(plano);
    }

    public async Task<Result<PlanoDto>> UpdateAsync(Guid id, UpdatePlanoRequest request, CancellationToken ct = default)
    {
        var plano = await planos.GetByIdAsync(id, ct);
        if (plano is null)
            return Result.Failure<PlanoDto>(NotFound(id));

        if (string.IsNullOrWhiteSpace(request.Designacao))
            return Result.Failure<PlanoDto>(Error.Validation("Plano.Invalid", "Designação é obrigatória."));

        plano.Designacao = request.Designacao;
        plano.Ativo = request.Ativo;
        plano.UpdatedAt = DateTimeOffset.UtcNow;

        await planos.UpdateAsync(plano, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(plano);
    }

    /// <summary>Cria uma nova versão do plano e marca a origem como inativa — backlog 5.1.2.</summary>
    public async Task<Result<PlanoDto>> CreateVersionAsync(Guid id, CreatePlanoVersionRequest request, CancellationToken ct = default)
    {
        var origem = await planos.GetByIdAsync(id, ct);
        if (origem is null)
            return Result.Failure<PlanoDto>(NotFound(id));

        if (string.IsNullOrWhiteSpace(request.NovaVersao))
            return Result.Failure<PlanoDto>(Error.Validation("Plano.Invalid", "A nova versão é obrigatória."));

        if (await ExistsVersionAsync(origem.ProjetoId, origem.Codigo, request.NovaVersao, ct))
            return Result.Failure<PlanoDto>(DuplicateVersion(origem.Codigo, request.NovaVersao));

        var novaVersao = new Plano
        {
            ProjetoId = origem.ProjetoId,
            Codigo = origem.Codigo,
            Designacao = origem.Designacao,
            Versao = request.NovaVersao
        };

        origem.Ativo = false;
        origem.UpdatedAt = DateTimeOffset.UtcNow;

        await planos.AddAsync(novaVersao, ct);
        await planos.UpdateAsync(origem, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(novaVersao);
    }

    private Task<bool> ExistsVersionAsync(Guid projetoId, string codigo, string versao, CancellationToken ct) =>
        planos.Query().AnyAsync(p => p.ProjetoId == projetoId && p.Codigo == codigo && p.Versao == versao, ct);

    private static Error DuplicateVersion(string codigo, string versao) =>
        Error.Conflict("Plano.DuplicateVersion", $"Já existe a versão '{versao}' do plano '{codigo}' neste projeto.");

    private static Error NotFound(Guid id) => Error.NotFound("Plano.NotFound", $"Plano '{id}' não encontrado.");

    private static PlanoDto ToDto(Plano p) => new(
        p.Id, p.ProjetoId, p.Codigo, p.Designacao, p.Versao, p.DataAprovacao, p.DataPublicacao, p.Ativo, p.CreatedAt, p.UpdatedAt);
}
