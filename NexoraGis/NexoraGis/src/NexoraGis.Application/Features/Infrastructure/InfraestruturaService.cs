using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;
using Infraestrutura = NexoraGis.Domain.Entities.Cadastro.Infraestrutura;

namespace NexoraGis.Application.Features.Infrastructure;

public class InfraestruturaService(IRepository<Infraestrutura> infraestruturas, IRepository<Projeto> projetos, IUnitOfWork unitOfWork)
{
    public async Task<Result<InfraestruturaDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var item = await infraestruturas.GetByIdAsync(id, ct);
        return item is null ? Result.Failure<InfraestruturaDto>(NotFound(id)) : ToDto(item);
    }

    public async Task<PagedResult<InfraestruturaDto>> ListAsync(Guid? projetoId, TipoInfraestrutura? tipo, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = infraestruturas.Query();
        if (projetoId is not null) query = query.Where(i => i.ProjetoId == projetoId);
        if (tipo is not null) query = query.Where(i => i.Tipo == tipo);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(i => i.CreatedAt).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<InfraestruturaDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<InfraestruturaDto>> CreateAsync(UpsertInfraestruturaRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Subtipo))
            return Result.Failure<InfraestruturaDto>(Error.Validation("Infraestrutura.Invalid", "Subtipo é obrigatório."));

        if (!await projetos.ExistsAsync(request.ProjetoId, ct))
            return Result.Failure<InfraestruturaDto>(Error.Validation("Infraestrutura.ProjetoNotFound", "Projeto indicado não existe."));

        if (request.Geometria is not null && !request.Geometria.IsValid)
            return Result.Failure<InfraestruturaDto>(Error.Validation("Infraestrutura.InvalidGeometry", "Geometria inválida."));

        var item = new Infraestrutura();
        Apply(item, request);

        await infraestruturas.AddAsync(item, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(item);
    }

    public async Task<Result<InfraestruturaDto>> UpdateAsync(Guid id, UpsertInfraestruturaRequest request, CancellationToken ct = default)
    {
        var item = await infraestruturas.GetByIdAsync(id, ct);
        if (item is null)
            return Result.Failure<InfraestruturaDto>(NotFound(id));

        if (request.Geometria is not null && !request.Geometria.IsValid)
            return Result.Failure<InfraestruturaDto>(Error.Validation("Infraestrutura.InvalidGeometry", "Geometria inválida."));

        Apply(item, request);
        item.UpdatedAt = DateTimeOffset.UtcNow;

        await infraestruturas.UpdateAsync(item, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(item);
    }

    public async Task<Result> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var item = await infraestruturas.GetByIdAsync(id, ct);
        if (item is null)
            return Result.Failure(NotFound(id));

        await infraestruturas.DeleteAsync(item, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success();
    }

    private static void Apply(Infraestrutura item, UpsertInfraestruturaRequest request)
    {
        item.ProjetoId = request.ProjetoId;
        item.Tipo = request.Tipo;
        item.Subtipo = request.Subtipo;
        item.Codigo = request.Codigo;
        item.Designacao = request.Designacao;
        if (request.Geometria is not null) item.Geometria = request.Geometria;
        item.Atributos = request.Atributos;
        item.EstadoConservacao = request.EstadoConservacao;
        item.DataLevantamento = request.DataLevantamento;
    }

    private static Error NotFound(Guid id) => Error.NotFound("Infraestrutura.NotFound", $"Infraestrutura '{id}' não encontrada.");

    private static InfraestruturaDto ToDto(Infraestrutura i) => new(
        i.Id, i.ProjetoId, i.Tipo, i.Subtipo, i.Codigo, i.Designacao, i.Geometria, i.Atributos,
        i.EstadoConservacao, i.DataLevantamento, i.CreatedAt, i.UpdatedAt);
}
