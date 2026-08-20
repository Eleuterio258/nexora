using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Infrastructure;

public class EquipamentoService(IRepository<Equipamento> equipamentos, IRepository<Projeto> projetos, IUnitOfWork unitOfWork)
{
    public async Task<Result<EquipamentoDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var item = await equipamentos.GetByIdAsync(id, ct);
        return item is null ? Result.Failure<EquipamentoDto>(NotFound(id)) : ToDto(item);
    }

    public async Task<PagedResult<EquipamentoDto>> ListAsync(Guid? projetoId, string? tipo, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = equipamentos.Query();
        if (projetoId is not null) query = query.Where(e => e.ProjetoId == projetoId);
        if (!string.IsNullOrWhiteSpace(tipo)) query = query.Where(e => e.Tipo == tipo);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderBy(e => e.Nome).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<EquipamentoDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<EquipamentoDto>> CreateAsync(UpsertEquipamentoRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Nome) || string.IsNullOrWhiteSpace(request.Tipo))
            return Result.Failure<EquipamentoDto>(Error.Validation("Equipamento.Invalid", "Nome e tipo são obrigatórios."));

        if (!await projetos.ExistsAsync(request.ProjetoId, ct))
            return Result.Failure<EquipamentoDto>(Error.Validation("Equipamento.ProjetoNotFound", "Projeto indicado não existe."));

        var item = new Equipamento();
        Apply(item, request);

        await equipamentos.AddAsync(item, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(item);
    }

    public async Task<Result<EquipamentoDto>> UpdateAsync(Guid id, UpsertEquipamentoRequest request, CancellationToken ct = default)
    {
        var item = await equipamentos.GetByIdAsync(id, ct);
        if (item is null)
            return Result.Failure<EquipamentoDto>(NotFound(id));

        Apply(item, request);
        item.UpdatedAt = DateTimeOffset.UtcNow;

        await equipamentos.UpdateAsync(item, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(item);
    }

    public async Task<Result> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var item = await equipamentos.GetByIdAsync(id, ct);
        if (item is null)
            return Result.Failure(NotFound(id));

        await equipamentos.DeleteAsync(item, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success();
    }

    private static void Apply(Equipamento item, UpsertEquipamentoRequest request)
    {
        item.ProjetoId = request.ProjetoId;
        item.Tipo = request.Tipo;
        item.Codigo = request.Codigo;
        item.Nome = request.Nome;
        if (request.Geometria is not null) item.Geometria = request.Geometria;
        item.Morada = request.Morada;
        item.Contacto = request.Contacto;
        item.HorarioFuncionamento = request.HorarioFuncionamento;
        item.Capacidade = request.Capacidade;
        item.Atributos = request.Atributos;
        item.Ativo = request.Ativo;
    }

    private static Error NotFound(Guid id) => Error.NotFound("Equipamento.NotFound", $"Equipamento '{id}' não encontrado.");

    private static EquipamentoDto ToDto(Equipamento e) => new(
        e.Id, e.ProjetoId, e.Tipo, e.Codigo, e.Nome, e.Geometria, e.Morada, e.Contacto,
        e.HorarioFuncionamento, e.Capacidade, e.Atributos, e.Ativo, e.CreatedAt, e.UpdatedAt);
}
