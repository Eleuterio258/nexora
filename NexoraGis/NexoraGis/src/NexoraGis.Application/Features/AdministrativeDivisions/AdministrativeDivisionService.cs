using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.AdministrativeDivisions;

public class AdministrativeDivisionService(
    IRepository<DivisaoAdministrativa> divisoes,
    IUnitOfWork unitOfWork)
{
    public async Task<Result<DivisaoAdministrativaDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var divisao = await divisoes.GetByIdAsync(id, ct);
        return divisao is null
            ? Result.Failure<DivisaoAdministrativaDto>(NotFound(id))
            : ToDto(divisao);
    }

    public async Task<PagedResult<DivisaoAdministrativaDto>> ListAsync(
        TipoDivisao? tipo, bool? zonaUrbana, Guid? parentId, bool? ativo,
        int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = divisoes.Query();

        if (tipo is not null) query = query.Where(d => d.Tipo == tipo);
        if (zonaUrbana is not null) query = query.Where(d => d.ZonaUrbana == zonaUrbana);
        if (parentId is not null) query = query.Where(d => d.ParentId == parentId);
        if (ativo is not null) query = query.Where(d => d.Ativo == ativo);

        var totalCount = await query.CountAsync(ct);
        var items = await query
            .OrderBy(d => d.NivelHierarquico).ThenBy(d => d.Nome)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return new PagedResult<DivisaoAdministrativaDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<IReadOnlyList<DivisaoAdministrativaDto>>> GetChildrenAsync(Guid id, CancellationToken ct = default)
    {
        if (!await divisoes.ExistsAsync(id, ct))
            return Result.Failure<IReadOnlyList<DivisaoAdministrativaDto>>(NotFound(id));

        var filhos = await divisoes.Query()
            .Where(d => d.ParentId == id)
            .OrderBy(d => d.Nome)
            .ToListAsync(ct);

        return Result.Success<IReadOnlyList<DivisaoAdministrativaDto>>(filhos.Select(ToDto).ToList());
    }

    /// <summary>Caminho hierárquico completo, da raiz até à divisão pedida (inclusive).</summary>
    public async Task<Result<IReadOnlyList<DivisaoAdministrativaPathNodeDto>>> GetPathAsync(Guid id, CancellationToken ct = default)
    {
        var path = new List<DivisaoAdministrativaPathNodeDto>();
        Guid? currentId = id;
        var guard = 0;

        while (currentId is not null && guard++ < 32)
        {
            var node = await divisoes.GetByIdAsync(currentId.Value, ct);
            if (node is null)
                return path.Count == 0
                    ? Result.Failure<IReadOnlyList<DivisaoAdministrativaPathNodeDto>>(NotFound(id))
                    : Result.Failure<IReadOnlyList<DivisaoAdministrativaPathNodeDto>>(
                        Error.NotFound("DivisaoAdministrativa.BrokenParentChain", $"Divisão pai '{currentId}' não encontrada."));

            path.Insert(0, new DivisaoAdministrativaPathNodeDto(node.Id, node.Tipo, node.Codigo, node.Nome));
            currentId = node.ParentId;
        }

        return Result.Success<IReadOnlyList<DivisaoAdministrativaPathNodeDto>>(path);
    }

    public async Task<Result<DivisaoAdministrativaDto>> CreateAsync(CreateDivisaoAdministrativaRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo) || string.IsNullOrWhiteSpace(request.Nome))
            return Result.Failure<DivisaoAdministrativaDto>(
                Error.Validation("DivisaoAdministrativa.Invalid", "Código e nome são obrigatórios."));

        if (await divisoes.Query().AnyAsync(d => d.Codigo == request.Codigo, ct))
            return Result.Failure<DivisaoAdministrativaDto>(
                Error.Conflict("DivisaoAdministrativa.DuplicateCodigo", $"Já existe uma divisão com o código '{request.Codigo}'."));

        var nivelHierarquico = request.NivelHierarquico;

        if (request.ParentId is not null)
        {
            var parent = await divisoes.GetByIdAsync(request.ParentId.Value, ct);
            if (parent is null)
                return Result.Failure<DivisaoAdministrativaDto>(
                    Error.Validation("DivisaoAdministrativa.ParentNotFound", "Divisão pai indicada não existe."));

            nivelHierarquico = parent.NivelHierarquico + 1;
        }

        var divisao = new DivisaoAdministrativa
        {
            ParentId = request.ParentId,
            Tipo = request.Tipo,
            Codigo = request.Codigo,
            Nome = request.Nome,
            NomeNormalizado = request.NomeNormalizado,
            ZonaUrbana = request.ZonaUrbana,
            NivelHierarquico = nivelHierarquico,
            EntidadeResponsavel = request.EntidadeResponsavel,
            CodigoIne = request.CodigoIne,
            Geometria = request.Geometria as NetTopologySuite.Geometries.MultiPolygon,
            Metadados = request.Metadados
        };

        await divisoes.AddAsync(divisao, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(divisao);
    }

    public async Task<Result<DivisaoAdministrativaDto>> UpdateAsync(Guid id, UpdateDivisaoAdministrativaRequest request, CancellationToken ct = default)
    {
        var divisao = await divisoes.GetByIdAsync(id, ct);
        if (divisao is null)
            return Result.Failure<DivisaoAdministrativaDto>(NotFound(id));

        if (string.IsNullOrWhiteSpace(request.Nome))
            return Result.Failure<DivisaoAdministrativaDto>(
                Error.Validation("DivisaoAdministrativa.Invalid", "Nome é obrigatório."));

        divisao.Nome = request.Nome;
        divisao.NomeNormalizado = request.NomeNormalizado;
        divisao.ZonaUrbana = request.ZonaUrbana;
        divisao.EntidadeResponsavel = request.EntidadeResponsavel;
        divisao.CodigoIne = request.CodigoIne;
        if (request.Geometria is NetTopologySuite.Geometries.MultiPolygon geometria)
            divisao.Geometria = geometria;
        divisao.Ativo = request.Ativo;
        divisao.Metadados = request.Metadados;
        divisao.UpdatedAt = DateTimeOffset.UtcNow;

        await divisoes.UpdateAsync(divisao, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(divisao);
    }

    /// <summary>Desativação lógica — divisões administrativas nunca são apagadas fisicamente.</summary>
    public async Task<Result> DeactivateAsync(Guid id, CancellationToken ct = default)
    {
        var divisao = await divisoes.GetByIdAsync(id, ct);
        if (divisao is null)
            return Result.Failure(NotFound(id));

        divisao.Ativo = false;
        divisao.UpdatedAt = DateTimeOffset.UtcNow;
        await divisoes.UpdateAsync(divisao, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return Result.Success();
    }

    private static Error NotFound(Guid id) =>
        Error.NotFound("DivisaoAdministrativa.NotFound", $"Divisão administrativa '{id}' não encontrada.");

    private static DivisaoAdministrativaDto ToDto(DivisaoAdministrativa d) => new(
        d.Id, d.ParentId, d.Tipo, d.Codigo, d.Nome, d.NomeNormalizado, d.ZonaUrbana, d.NivelHierarquico,
        d.EntidadeResponsavel, d.CodigoIne, d.Geometria, d.AreaCalculada, d.Ativo, d.CreatedAt, d.UpdatedAt);
}
