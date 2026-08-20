using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Entities;

public class EntidadeService(
    IRepository<Entidade> entidades,
    IRepository<Parcela> parcelas,
    IRepository<ParcelaEntidade> parcelaEntidades,
    ICurrentUserService currentUser,
    IUnitOfWork unitOfWork)
{
    public async Task<Result<EntidadeDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var entidade = await entidades.GetByIdAsync(id, ct);
        return entidade is null ? Result.Failure<EntidadeDto>(NotFound(id)) : ToDto(entidade);
    }

    public async Task<PagedResult<EntidadeDto>> ListAsync(TipoEntidade? tipo, string? nome, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = entidades.Query();
        if (tipo is not null) query = query.Where(e => e.Tipo == tipo);
        if (!string.IsNullOrWhiteSpace(nome)) query = query.Where(e => e.Nome.Contains(nome));

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderBy(e => e.Nome).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<EntidadeDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    /// <summary>
    /// Vista para o WebGIS público (§6, §35): só entidades marcadas AcessoPublico,
    /// e mesmo essas sem contactos, documentos de identificação ou NUIT.
    /// </summary>
    public async Task<PagedResult<EntidadePublicaDto>> ListPublicAsync(int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = entidades.Query().Where(e => e.AcessoPublico);
        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderBy(e => e.Nome).Skip((page - 1) * pageSize).Take(pageSize)
            .Select(e => new EntidadePublicaDto(e.Id, e.Tipo, e.Nome))
            .ToListAsync(ct);

        return new PagedResult<EntidadePublicaDto>(items, page, pageSize, totalCount);
    }

    public async Task<Result<EntidadeDto>> CreateAsync(UpsertEntidadeRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Nome))
            return Result.Failure<EntidadeDto>(Error.Validation("Entidade.Invalid", "Nome é obrigatório."));

        if (currentUser.OrganizacaoId is null)
            return Result.Failure<EntidadeDto>(Error.Validation("Entidade.NoOrganizacao", "Utilizador autenticado sem organização associada."));

        var entidade = new Entidade { OrganizacaoId = currentUser.OrganizacaoId.Value };
        Apply(entidade, request);

        await entidades.AddAsync(entidade, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(entidade);
    }

    public async Task<Result<EntidadeDto>> UpdateAsync(Guid id, UpsertEntidadeRequest request, CancellationToken ct = default)
    {
        var entidade = await entidades.GetByIdAsync(id, ct);
        if (entidade is null)
            return Result.Failure<EntidadeDto>(NotFound(id));

        if (string.IsNullOrWhiteSpace(request.Nome))
            return Result.Failure<EntidadeDto>(Error.Validation("Entidade.Invalid", "Nome é obrigatório."));

        Apply(entidade, request);
        entidade.UpdatedAt = DateTimeOffset.UtcNow;

        await entidades.UpdateAsync(entidade, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(entidade);
    }

    public async Task<Result> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var entidade = await entidades.GetByIdAsync(id, ct);
        if (entidade is null)
            return Result.Failure(NotFound(id));

        await entidades.DeleteAsync(entidade, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success();
    }

    public async Task<Result<IReadOnlyList<ParcelaEntidadeDto>>> ListForParcelaAsync(Guid parcelaId, CancellationToken ct = default)
    {
        if (!await parcelas.ExistsAsync(parcelaId, ct))
            return Result.Failure<IReadOnlyList<ParcelaEntidadeDto>>(Error.NotFound("Parcela.NotFound", $"Parcela '{parcelaId}' não encontrada."));

        var links = await parcelaEntidades.Query()
            .Where(pe => pe.ParcelaId == parcelaId && pe.Ativo)
            .Include(pe => pe.Entidade)
            .ToListAsync(ct);

        return Result.Success<IReadOnlyList<ParcelaEntidadeDto>>(
            links.Select(l => new ParcelaEntidadeDto(l.Id, l.ParcelaId, l.EntidadeId, l.Entidade.Nome, l.TipoRelacao, l.DataInicio, l.DataFim, l.Ativo)).ToList());
    }

    public async Task<Result<ParcelaEntidadeDto>> LinkAsync(Guid parcelaId, LinkParcelaEntidadeRequest request, CancellationToken ct = default)
    {
        if (!await parcelas.ExistsAsync(parcelaId, ct))
            return Result.Failure<ParcelaEntidadeDto>(Error.NotFound("Parcela.NotFound", $"Parcela '{parcelaId}' não encontrada."));

        var entidade = await entidades.GetByIdAsync(request.EntidadeId, ct);
        if (entidade is null)
            return Result.Failure<ParcelaEntidadeDto>(Error.Validation("ParcelaEntidade.EntidadeNotFound", "Entidade indicada não existe."));

        var existente = await parcelaEntidades.Query()
            .FirstOrDefaultAsync(pe => pe.ParcelaId == parcelaId && pe.EntidadeId == request.EntidadeId && pe.TipoRelacao == request.TipoRelacao && pe.Ativo, ct);

        if (existente is not null)
            return Result.Failure<ParcelaEntidadeDto>(Error.Conflict("ParcelaEntidade.AlreadyLinked", "Já existe esta relação ativa entre a parcela e a entidade."));

        var link = new ParcelaEntidade
        {
            ParcelaId = parcelaId,
            EntidadeId = request.EntidadeId,
            TipoRelacao = request.TipoRelacao,
            DataInicio = request.DataInicio,
            DataFim = request.DataFim
        };

        await parcelaEntidades.AddAsync(link, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return new ParcelaEntidadeDto(link.Id, link.ParcelaId, link.EntidadeId, entidade.Nome, link.TipoRelacao, link.DataInicio, link.DataFim, link.Ativo);
    }

    public async Task<Result> UnlinkAsync(Guid parcelaId, Guid parcelaEntidadeId, CancellationToken ct = default)
    {
        var link = await parcelaEntidades.GetByIdAsync(parcelaEntidadeId, ct);
        if (link is null || link.ParcelaId != parcelaId || !link.Ativo)
            return Result.Failure(Error.NotFound("ParcelaEntidade.NotFound", "Relação ativa não encontrada."));

        link.Ativo = false;
        link.DataFim ??= DateOnly.FromDateTime(DateTime.UtcNow);
        await parcelaEntidades.UpdateAsync(link, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success();
    }

    private static void Apply(Entidade entidade, UpsertEntidadeRequest request)
    {
        entidade.Tipo = request.Tipo;
        entidade.Nome = request.Nome;
        entidade.DocumentoIdentificacao = request.DocumentoIdentificacao;
        entidade.Nuit = request.Nuit;
        entidade.Morada = request.Morada;
        entidade.Telefone = request.Telefone;
        entidade.Email = request.Email;
        entidade.DadosPessoais = request.DadosPessoais;
        entidade.AcessoPublico = request.AcessoPublico;
    }

    private static Error NotFound(Guid id) => Error.NotFound("Entidade.NotFound", $"Entidade '{id}' não encontrada.");

    private static EntidadeDto ToDto(Entidade e) => new(
        e.Id, e.Tipo, e.Nome, e.DocumentoIdentificacao, e.Nuit, e.Morada, e.Telefone, e.Email,
        e.DadosPessoais, e.AcessoPublico, e.CreatedAt, e.UpdatedAt);
}
