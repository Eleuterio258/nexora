using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Conflicts;

/// <summary>
/// Motor de conflitos territoriais (backlog 5.4): permite registar conflitos
/// manualmente (ex: fiscalização de campo) e deteta automaticamente uso
/// incompatível (5.4.1) e construções sobre condicionantes restritivas
/// (5.4.2). A regra de 5.4.1 espelha a função SQL
/// territorial.detectar_conflito_uso já existente desde a Fase 1, reescrita
/// em C# para ficar testável e composta com o resto da Application.
/// </summary>
public class ConflitoService(
    IRepository<Conflito> conflitos,
    IRepository<Parcela> parcelas,
    IRepository<Edificacao> edificacoes,
    IRepository<Condicionante> condicionantes,
    IRepository<Projeto> projetos,
    ICurrentUserService currentUser,
    IUnitOfWork unitOfWork)
{
    public async Task<Result<ConflitoDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var conflito = await conflitos.GetByIdAsync(id, ct);
        return conflito is null ? Result.Failure<ConflitoDto>(NotFound(id)) : ToDto(conflito);
    }

    public async Task<PagedResult<ConflitoDto>> ListAsync(
        Guid? projetoId, TipoConflito? tipo, bool? resolvido, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = conflitos.Query();
        if (projetoId is not null) query = query.Where(c => c.ProjetoId == projetoId);
        if (tipo is not null) query = query.Where(c => c.Tipo == tipo);
        if (resolvido is not null) query = query.Where(c => c.Resolvido == resolvido);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(c => c.DataDetecao).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<ConflitoDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<ConflitoDto>> CreateAsync(CreateConflitoRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Descricao))
            return Result.Failure<ConflitoDto>(Error.Validation("Conflito.Invalid", "Descrição é obrigatória."));

        if (!await projetos.ExistsAsync(request.ProjetoId, ct))
            return Result.Failure<ConflitoDto>(Error.Validation("Conflito.ProjetoNotFound", "Projeto indicado não existe."));

        var conflito = new Conflito
        {
            ProjetoId = request.ProjetoId,
            Tipo = request.Tipo,
            Descricao = request.Descricao,
            EntidadeTipo = request.EntidadeTipo,
            EntidadeId = request.EntidadeId,
            Detalhes = request.Detalhes
        };

        await conflitos.AddAsync(conflito, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(conflito);
    }

    public async Task<Result<ConflitoDto>> ResolveAsync(Guid id, CancellationToken ct = default)
    {
        var conflito = await conflitos.GetByIdAsync(id, ct);
        if (conflito is null)
            return Result.Failure<ConflitoDto>(NotFound(id));

        if (conflito.Resolvido)
            return Result.Failure<ConflitoDto>(Error.Conflict("Conflito.AlreadyResolved", "Este conflito já está resolvido."));

        conflito.Resolvido = true;
        conflito.DataResolucao = DateTimeOffset.UtcNow;
        conflito.ResolvidoPor = currentUser.UtilizadorId;

        await conflitos.UpdateAsync(conflito, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(conflito);
    }

    /// <summary>Corre os detetores automáticos (5.4.1 + 5.4.2) sobre um projeto e regista os conflitos novos.</summary>
    public async Task<Result<IReadOnlyList<ConflitoDto>>> DetectAllAsync(Guid projetoId, CancellationToken ct = default)
    {
        if (!await projetos.ExistsAsync(projetoId, ct))
            return Result.Failure<IReadOnlyList<ConflitoDto>>(Error.Validation("Conflito.ProjetoNotFound", "Projeto indicado não existe."));

        var usoIncompativel = await DetectUsoIncompativelAsync(projetoId, ct);
        var infracoes = await DetectInfracaoCondicionanteAsync(projetoId, ct);

        return Result.Success<IReadOnlyList<ConflitoDto>>(usoIncompativel.Concat(infracoes).ToList());
    }

    /// <summary>Uso atual vs. uso previsto (backlog 5.4.1).</summary>
    private async Task<List<ConflitoDto>> DetectUsoIncompativelAsync(Guid projetoId, CancellationToken ct)
    {
        var existentesIds = await ExistingUnresolvedEntityIdsAsync(projetoId, TipoConflito.UsoIncompativel, "parcela", ct);

        var candidatas = await parcelas.Query()
            .Where(p => p.ProjetoId == projetoId && p.UsoPrevisto != null && p.UsoAtual != p.UsoPrevisto)
            .Select(p => new { p.Id, p.CodigoCadastral, p.UsoAtual, p.UsoPrevisto, p.Geometria })
            .ToListAsync(ct);

        var novos = candidatas
            .Where(p => !existentesIds.Contains(p.Id))
            .Select(p => new Conflito
            {
                ProjetoId = projetoId,
                Tipo = TipoConflito.UsoIncompativel,
                Descricao = $"Parcela {p.CodigoCadastral}: uso atual ({p.UsoAtual}) difere do uso previsto ({p.UsoPrevisto}).",
                EntidadeTipo = "parcela",
                EntidadeId = p.Id,
                Geometria = p.Geometria
            })
            .ToList();

        if (novos.Count > 0)
        {
            foreach (var c in novos) await conflitos.AddAsync(c, ct);
            await unitOfWork.SaveChangesAsync(ct);
        }

        return novos.Select(ToDto).ToList();
    }

    /// <summary>Edificações cuja geometria interseta uma condicionante restritiva (backlog 5.4.2).</summary>
    private async Task<List<ConflitoDto>> DetectInfracaoCondicionanteAsync(Guid projetoId, CancellationToken ct)
    {
        var existentesIds = await ExistingUnresolvedEntityIdsAsync(projetoId, TipoConflito.InfracaoCondicionante, "edificacao", ct);

        var infracoes = await (
            from e in edificacoes.Query()
            where e.Parcela.ProjetoId == projetoId && e.Geometria != null
            from c in condicionantes.Query()
            where c.ProjetoId == projetoId && c.Restritivo && c.Geometria != null && c.Geometria!.Intersects(e.Geometria!)
            select new { EdificacaoId = e.Id, EdificacaoCodigo = e.Codigo, EdificacaoGeometria = e.Geometria, CondicionanteNome = c.Designacao ?? c.Tipo }
        ).ToListAsync(ct);

        var novos = infracoes
            .Where(x => !existentesIds.Contains(x.EdificacaoId))
            .GroupBy(x => x.EdificacaoId)
            // Sem esta ordenação, qual condicionante fica reportada (quando uma
            // edificação interseta mais do que uma) dependia da ordem de
            // devolução do SQL — não determinística entre execuções.
            .Select(g => g.OrderBy(x => x.CondicionanteNome, StringComparer.Ordinal).First())
            .Select(x => new Conflito
            {
                ProjetoId = projetoId,
                Tipo = TipoConflito.InfracaoCondicionante,
                Descricao = $"Edificação {x.EdificacaoCodigo} interseta a condicionante '{x.CondicionanteNome}'.",
                EntidadeTipo = "edificacao",
                EntidadeId = x.EdificacaoId,
                Geometria = x.EdificacaoGeometria
            })
            .ToList();

        if (novos.Count > 0)
        {
            foreach (var c in novos) await conflitos.AddAsync(c, ct);
            await unitOfWork.SaveChangesAsync(ct);
        }

        return novos.Select(ToDto).ToList();
    }

    private async Task<HashSet<Guid>> ExistingUnresolvedEntityIdsAsync(Guid projetoId, TipoConflito tipo, string entidadeTipo, CancellationToken ct)
    {
        var ids = await conflitos.Query()
            .Where(c => c.ProjetoId == projetoId && c.Tipo == tipo && c.EntidadeTipo == entidadeTipo && !c.Resolvido)
            .Select(c => c.EntidadeId)
            .ToListAsync(ct);

        return ids.Where(id => id.HasValue).Select(id => id!.Value).ToHashSet();
    }

    private static Error NotFound(Guid id) => Error.NotFound("Conflito.NotFound", $"Conflito '{id}' não encontrado.");

    private static ConflitoDto ToDto(Conflito c) => new(
        c.Id, c.ProjetoId, c.Tipo, c.Descricao, c.EntidadeTipo, c.EntidadeId, c.Geometria,
        c.Resolvido, c.DataDetecao, c.DataResolucao, c.ResolvidoPor);
}
