using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Audit;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Entities.Workflow;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Approvals;

/// <summary>
/// Workflow de aprovação (backlog 6.1): Rascunho → Submetido → Em Análise →
/// Aprovado/Rejeitado/Correção solicitada → Publicado, para qualquer
/// entidade identificada por (EntidadeTipo, EntidadeId) — hoje aplica-se a
/// parcelas e planos. Sincroniza o estado da entidade alvo quando o tipo é
/// conhecido (Parcela.Estado; Plano.DataAprovacao/DataPublicacao).
/// </summary>
public class AprovacaoService(
    IRepository<Aprovacao> aprovacoes,
    IRepository<Projeto> projetos,
    IRepository<Parcela> parcelas,
    IRepository<Plano> planos,
    IRepository<AuditLog> auditLogs,
    ICurrentUserService currentUser,
    IUnitOfWork unitOfWork)
{
    public async Task<Result<AprovacaoDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var aprovacao = await aprovacoes.GetByIdAsync(id, ct);
        return aprovacao is null ? Result.Failure<AprovacaoDto>(NotFound(id)) : ToDto(aprovacao);
    }

    public async Task<PagedResult<AprovacaoDto>> ListAsync(
        Guid? projetoId, string? entidadeTipo, ApprovalStatus? status, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = aprovacoes.Query();
        if (projetoId is not null) query = query.Where(a => a.ProjetoId == projetoId);
        if (!string.IsNullOrWhiteSpace(entidadeTipo)) query = query.Where(a => a.EntidadeTipo == entidadeTipo);
        if (status is not null) query = query.Where(a => a.Status == status);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(a => a.UpdatedAt).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<AprovacaoDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    /// <summary>Fila de trabalho pendente (backlog 6.1.3): tudo à espera de acção humana (não Rascunho nem terminal).</summary>
    public async Task<PagedResult<AprovacaoDto>> ListPendingAsync(Guid? projetoId, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var pendentes = new[] { ApprovalStatus.Submetido, ApprovalStatus.EmAnalise, ApprovalStatus.CorrecaoSolicitada };
        var query = aprovacoes.Query().Where(a => pendentes.Contains(a.Status));
        if (projetoId is not null) query = query.Where(a => a.ProjetoId == projetoId);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderBy(a => a.UpdatedAt).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<AprovacaoDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<AprovacaoDto>> CreateAsync(CreateAprovacaoRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.EntidadeTipo))
            return Result.Failure<AprovacaoDto>(Error.Validation("Aprovacao.Invalid", "Tipo de entidade é obrigatório."));

        if (!await projetos.ExistsAsync(request.ProjetoId, ct))
            return Result.Failure<AprovacaoDto>(Error.Validation("Aprovacao.ProjetoNotFound", "Projeto indicado não existe."));

        var entidadeTipo = request.EntidadeTipo.ToLowerInvariant();
        if (entidadeTipo != "parcela" && entidadeTipo != "plano")
            return Result.Failure<AprovacaoDto>(Error.Validation("Aprovacao.UnsupportedEntidadeTipo", "Só é suportado workflow de aprovação para 'parcela' ou 'plano'."));

        if (entidadeTipo == "parcela" && !await parcelas.ExistsAsync(request.EntidadeId, ct))
            return Result.Failure<AprovacaoDto>(Error.Validation("Aprovacao.EntidadeNotFound", "Parcela indicada não existe."));
        if (entidadeTipo == "plano" && !await planos.ExistsAsync(request.EntidadeId, ct))
            return Result.Failure<AprovacaoDto>(Error.Validation("Aprovacao.EntidadeNotFound", "Plano indicado não existe."));

        if (await aprovacoes.Query().AnyAsync(a =>
                a.EntidadeTipo == entidadeTipo && a.EntidadeId == request.EntidadeId && a.Status != ApprovalStatus.Publicado, ct))
            return Result.Failure<AprovacaoDto>(Error.Conflict("Aprovacao.AlreadyInProgress", "Já existe um workflow de aprovação em curso para esta entidade."));

        var aprovacao = new Aprovacao
        {
            EntidadeTipo = entidadeTipo,
            EntidadeId = request.EntidadeId,
            ProjetoId = request.ProjetoId,
            Status = ApprovalStatus.Rascunho,
            RequisitadoPor = currentUser.UtilizadorId
        };

        await aprovacoes.AddAsync(aprovacao, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(aprovacao);
    }

    public Task<Result<AprovacaoDto>> SubmeterAsync(Guid id, CancellationToken ct = default) =>
        TransitionAsync(id, ApprovalStatus.Submetido, a => a.DataSubmissao = DateTimeOffset.UtcNow, ct);

    public Task<Result<AprovacaoDto>> IniciarAnaliseAsync(Guid id, CancellationToken ct = default) =>
        TransitionAsync(id, ApprovalStatus.EmAnalise, a =>
        {
            a.VerificadoPor = currentUser.UtilizadorId;
            a.DataAnalise = DateTimeOffset.UtcNow;
        }, ct);

    public Task<Result<AprovacaoDto>> PedirCorrecaoAsync(Guid id, PedirCorrecaoRequest request, CancellationToken ct = default) =>
        TransitionAsync(id, ApprovalStatus.CorrecaoSolicitada, a => a.Observacoes = request.Observacoes, ct);

    public Task<Result<AprovacaoDto>> AprovarAsync(Guid id, CancellationToken ct = default) =>
        TransitionAsync(id, ApprovalStatus.Aprovado, a =>
        {
            a.AprovadoPor = currentUser.UtilizadorId;
            a.DataAprovacao = DateTimeOffset.UtcNow;
        }, ct);

    public Task<Result<AprovacaoDto>> RejeitarAsync(Guid id, RejeitarRequest request, CancellationToken ct = default) =>
        TransitionAsync(id, ApprovalStatus.Rejeitado, a => a.MotivoRejeicao = request.MotivoRejeicao, ct);

    public Task<Result<AprovacaoDto>> PublicarAsync(Guid id, CancellationToken ct = default) =>
        TransitionAsync(id, ApprovalStatus.Publicado, a => a.DataPublicacao = DateTimeOffset.UtcNow, ct);

    public Task<Result<AprovacaoDto>> ReabrirAsync(Guid id, CancellationToken ct = default) =>
        TransitionAsync(id, ApprovalStatus.Rascunho, a => a.MotivoRejeicao = null, ct);

    private async Task<Result<AprovacaoDto>> TransitionAsync(Guid id, ApprovalStatus novoStatus, Action<Aprovacao> apply, CancellationToken ct)
    {
        var aprovacao = await aprovacoes.GetByIdAsync(id, ct);
        if (aprovacao is null)
            return Result.Failure<AprovacaoDto>(NotFound(id));

        if (!AprovacaoStatusWorkflow.CanTransition(aprovacao.Status, novoStatus))
            return Result.Failure<AprovacaoDto>(Error.Validation(
                "Aprovacao.InvalidTransition", $"Transição de '{aprovacao.Status}' para '{novoStatus}' não é permitida."));

        apply(aprovacao);
        aprovacao.Status = novoStatus;
        aprovacao.Versao += 1;
        aprovacao.UpdatedAt = DateTimeOffset.UtcNow;

        await aprovacoes.UpdateAsync(aprovacao, ct);
        await SyncEntidadeEstadoAsync(aprovacao, novoStatus, ct);
        await auditLogs.AddAsync(new AuditLog
        {
            UtilizadorId = currentUser.UtilizadorId,
            Operacao = ToOperacaoAuditoria(novoStatus),
            EntidadeTipo = aprovacao.EntidadeTipo,
            EntidadeId = aprovacao.EntidadeId,
            ProjetoId = aprovacao.ProjetoId,
            DadosNovos = $"{{\"status\":\"{novoStatus}\"}}"
        }, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(aprovacao);
    }

    private static TipoOperacaoAuditoria ToOperacaoAuditoria(ApprovalStatus status) => status switch
    {
        ApprovalStatus.Aprovado => TipoOperacaoAuditoria.Aprovacao,
        ApprovalStatus.Rejeitado => TipoOperacaoAuditoria.Rejeicao,
        ApprovalStatus.Publicado => TipoOperacaoAuditoria.Publicacao,
        _ => TipoOperacaoAuditoria.Update
    };

    private async Task SyncEntidadeEstadoAsync(Aprovacao aprovacao, ApprovalStatus status, CancellationToken ct)
    {
        if (aprovacao.EntidadeTipo == "parcela")
        {
            var parcela = await parcelas.GetByIdAsync(aprovacao.EntidadeId, ct);
            if (parcela is null) return;

            parcela.Estado = status;
            parcela.UpdatedAt = DateTimeOffset.UtcNow;
            await parcelas.UpdateAsync(parcela, ct);
        }
        else if (aprovacao.EntidadeTipo == "plano")
        {
            var plano = await planos.GetByIdAsync(aprovacao.EntidadeId, ct);
            if (plano is null) return;

            if (status == ApprovalStatus.Aprovado) plano.DataAprovacao = DateOnly.FromDateTime(DateTime.UtcNow);
            if (status == ApprovalStatus.Publicado) plano.DataPublicacao = DateOnly.FromDateTime(DateTime.UtcNow);
            plano.UpdatedAt = DateTimeOffset.UtcNow;
            await planos.UpdateAsync(plano, ct);
        }
    }

    private static Error NotFound(Guid id) => Error.NotFound("Aprovacao.NotFound", $"Workflow de aprovação '{id}' não encontrado.");

    private static AprovacaoDto ToDto(Aprovacao a) => new(
        a.Id, a.EntidadeTipo, a.EntidadeId, a.ProjetoId, a.Status, a.RequisitadoPor, a.VerificadoPor, a.AprovadoPor,
        a.DataSubmissao, a.DataAnalise, a.DataAprovacao, a.DataPublicacao, a.MotivoRejeicao, a.Observacoes,
        a.Versao, a.CreatedAt, a.UpdatedAt);
}
