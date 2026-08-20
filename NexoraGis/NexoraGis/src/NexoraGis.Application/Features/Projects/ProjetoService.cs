using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Projects;

public class ProjetoService(
    IRepository<Projeto> projetos,
    IRepository<DivisaoAdministrativa> divisoes,
    IRepository<Utilizador> utilizadores,
    IRepository<ProjetoEquipa> equipas,
    ICurrentUserService currentUser,
    IUnitOfWork unitOfWork)
{
    public async Task<Result<ProjetoDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var projeto = await projetos.GetByIdAsync(id, ct);
        return projeto is null ? Result.Failure<ProjetoDto>(NotFound(id)) : ToDto(projeto);
    }

    public async Task<PagedResult<ProjetoDto>> ListAsync(
        ProjectStatus? status, Guid? divisaoAdministrativaId, string? tipo,
        int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = projetos.Query();

        if (status is not null) query = query.Where(p => p.Status == status);
        if (divisaoAdministrativaId is not null) query = query.Where(p => p.DivisaoAdministrativaId == divisaoAdministrativaId);
        if (!string.IsNullOrWhiteSpace(tipo)) query = query.Where(p => p.Tipo == tipo);

        var totalCount = await query.CountAsync(ct);
        var items = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return new PagedResult<ProjetoDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<ProjetoDto>> CreateAsync(CreateProjetoRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo) || string.IsNullOrWhiteSpace(request.Designacao) || string.IsNullOrWhiteSpace(request.Tipo))
            return Result.Failure<ProjetoDto>(Error.Validation("Projeto.Invalid", "Código, designação e tipo são obrigatórios."));

        if (currentUser.OrganizacaoId is null)
            return Result.Failure<ProjetoDto>(Error.Validation("Projeto.NoOrganizacao", "Utilizador autenticado sem organização associada."));

        var organizacaoId = currentUser.OrganizacaoId.Value;

        if (await projetos.Query().AnyAsync(p => p.Codigo == request.Codigo, ct))
            return Result.Failure<ProjetoDto>(Error.Conflict("Projeto.DuplicateCodigo", $"Já existe um projeto com o código '{request.Codigo}'."));

        if (request.DivisaoAdministrativaId is not null && !await divisoes.ExistsAsync(request.DivisaoAdministrativaId.Value, ct))
            return Result.Failure<ProjetoDto>(Error.Validation("Projeto.DivisaoNotFound", "Divisão administrativa indicada não existe."));

        if (request.ResponsavelTecnicoId is not null && !await utilizadores.ExistsAsync(request.ResponsavelTecnicoId.Value, ct))
            return Result.Failure<ProjetoDto>(Error.Validation("Projeto.ResponsavelNotFound", "Responsável técnico indicado não existe."));

        var projeto = new Projeto
        {
            OrganizacaoId = organizacaoId,
            Codigo = request.Codigo,
            Designacao = request.Designacao,
            Descricao = request.Descricao,
            Cliente = request.Cliente,
            Tipo = request.Tipo,
            Localizacao = request.Localizacao,
            DivisaoAdministrativaId = request.DivisaoAdministrativaId,
            AreaIntervencao = request.AreaIntervencao as NetTopologySuite.Geometries.MultiPolygon,
            SistemaReferencia = string.IsNullOrWhiteSpace(request.SistemaReferencia) ? "WGS84 / UTM 36S / 37S" : request.SistemaReferencia,
            ResponsavelTecnicoId = request.ResponsavelTecnicoId,
            DataInicio = request.DataInicio,
            DataPrevistaConclusao = request.DataPrevistaConclusao,
            Status = ProjectStatus.Rascunho,
            CreatedBy = currentUser.UtilizadorId
        };

        await projetos.AddAsync(projeto, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(projeto);
    }

    public async Task<Result<ProjetoDto>> UpdateAsync(Guid id, UpdateProjetoRequest request, CancellationToken ct = default)
    {
        var projeto = await projetos.GetByIdAsync(id, ct);
        if (projeto is null)
            return Result.Failure<ProjetoDto>(NotFound(id));

        if (string.IsNullOrWhiteSpace(request.Designacao))
            return Result.Failure<ProjetoDto>(Error.Validation("Projeto.Invalid", "Designação é obrigatória."));

        if (request.DivisaoAdministrativaId is not null && !await divisoes.ExistsAsync(request.DivisaoAdministrativaId.Value, ct))
            return Result.Failure<ProjetoDto>(Error.Validation("Projeto.DivisaoNotFound", "Divisão administrativa indicada não existe."));

        if (request.ResponsavelTecnicoId is not null && !await utilizadores.ExistsAsync(request.ResponsavelTecnicoId.Value, ct))
            return Result.Failure<ProjetoDto>(Error.Validation("Projeto.ResponsavelNotFound", "Responsável técnico indicado não existe."));

        projeto.Designacao = request.Designacao;
        projeto.Descricao = request.Descricao;
        projeto.Cliente = request.Cliente;
        projeto.Localizacao = request.Localizacao;
        projeto.DivisaoAdministrativaId = request.DivisaoAdministrativaId;
        if (request.AreaIntervencao is NetTopologySuite.Geometries.MultiPolygon area)
            projeto.AreaIntervencao = area;
        projeto.ResponsavelTecnicoId = request.ResponsavelTecnicoId;
        projeto.DataInicio = request.DataInicio;
        projeto.DataPrevistaConclusao = request.DataPrevistaConclusao;
        projeto.UpdatedAt = DateTimeOffset.UtcNow;

        await projetos.UpdateAsync(projeto, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(projeto);
    }

    public async Task<Result<ProjetoDto>> ChangeStatusAsync(Guid id, ChangeProjetoStatusRequest request, CancellationToken ct = default)
    {
        var projeto = await projetos.GetByIdAsync(id, ct);
        if (projeto is null)
            return Result.Failure<ProjetoDto>(NotFound(id));

        if (!ProjetoStatusWorkflow.CanTransition(projeto.Status, request.NovoStatus))
            return Result.Failure<ProjetoDto>(Error.Validation(
                "Projeto.InvalidTransition",
                $"Transição de '{projeto.Status}' para '{request.NovoStatus}' não é permitida."));

        projeto.Status = request.NovoStatus;
        projeto.UpdatedAt = DateTimeOffset.UtcNow;

        await projetos.UpdateAsync(projeto, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(projeto);
    }

    public async Task<Result<IReadOnlyList<ProjetoEquipaDto>>> ListTeamAsync(Guid projetoId, CancellationToken ct = default)
    {
        if (!await projetos.ExistsAsync(projetoId, ct))
            return Result.Failure<IReadOnlyList<ProjetoEquipaDto>>(NotFound(projetoId));

        var membros = await equipas.Query()
            .Where(e => e.ProjetoId == projetoId && e.Ativo)
            .Include(e => e.Utilizador)
            .OrderBy(e => e.Utilizador.NomeCompleto)
            .ToListAsync(ct);

        return Result.Success<IReadOnlyList<ProjetoEquipaDto>>(
            membros.Select(m => new ProjetoEquipaDto(m.Id, m.UtilizadorId, m.Utilizador.NomeCompleto, m.Funcao, m.Ativo, m.CreatedAt)).ToList());
    }

    public async Task<Result<ProjetoEquipaDto>> AddTeamMemberAsync(Guid projetoId, AddTeamMemberRequest request, CancellationToken ct = default)
    {
        if (!await projetos.ExistsAsync(projetoId, ct))
            return Result.Failure<ProjetoEquipaDto>(NotFound(projetoId));

        var utilizador = await utilizadores.GetByIdAsync(request.UtilizadorId, ct);
        if (utilizador is null)
            return Result.Failure<ProjetoEquipaDto>(Error.Validation("ProjetoEquipa.UtilizadorNotFound", "Utilizador indicado não existe."));

        var existente = await equipas.Query()
            .FirstOrDefaultAsync(e => e.ProjetoId == projetoId && e.UtilizadorId == request.UtilizadorId, ct);

        if (existente is not null)
        {
            if (existente.Ativo)
                return Result.Failure<ProjetoEquipaDto>(
                    Error.Conflict("ProjetoEquipa.AlreadyMember", "Utilizador já faz parte da equipa do projeto."));

            existente.Ativo = true;
            existente.Funcao = request.Funcao;
            await equipas.UpdateAsync(existente, ct);
            await unitOfWork.SaveChangesAsync(ct);
            return new ProjetoEquipaDto(existente.Id, existente.UtilizadorId, utilizador.NomeCompleto, existente.Funcao, existente.Ativo, existente.CreatedAt);
        }

        var membro = new ProjetoEquipa { ProjetoId = projetoId, UtilizadorId = request.UtilizadorId, Funcao = request.Funcao };
        await equipas.AddAsync(membro, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return new ProjetoEquipaDto(membro.Id, membro.UtilizadorId, utilizador.NomeCompleto, membro.Funcao, membro.Ativo, membro.CreatedAt);
    }

    public async Task<Result> RemoveTeamMemberAsync(Guid projetoId, Guid utilizadorId, CancellationToken ct = default)
    {
        var membro = await equipas.Query()
            .FirstOrDefaultAsync(e => e.ProjetoId == projetoId && e.UtilizadorId == utilizadorId && e.Ativo, ct);

        if (membro is null)
            return Result.Failure(Error.NotFound("ProjetoEquipa.NotFound", "Utilizador não faz parte da equipa ativa do projeto."));

        membro.Ativo = false;
        await equipas.UpdateAsync(membro, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return Result.Success();
    }

    private static Error NotFound(Guid id) => Error.NotFound("Projeto.NotFound", $"Projeto '{id}' não encontrado.");

    private static ProjetoDto ToDto(Projeto p) => new(
        p.Id, p.OrganizacaoId, p.Codigo, p.Designacao, p.Descricao, p.Cliente, p.Tipo, p.Localizacao,
        p.DivisaoAdministrativaId, p.AreaIntervencao, p.SistemaReferencia, p.ResponsavelTecnicoId,
        p.DataInicio, p.DataPrevistaConclusao, p.Status, p.CreatedAt, p.UpdatedAt);
}
