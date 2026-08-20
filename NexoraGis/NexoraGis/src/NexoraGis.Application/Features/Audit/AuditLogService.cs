using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Entities.Audit;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Audit;

/// <summary>
/// Consulta de auditoria (backlog 6.2.4). A recolha (6.2.3) já acontece
/// desde a Fase 1 via triggers de BD (audit.log_changes) em parcela,
/// edificacao, zona, infraestrutura e divisao_administrativa, mais as
/// entradas que a Application escreve explicitamente (ex: AprovacaoService).
/// Nota: entradas de trigger não têm Utilizador/Projeto resolvidos (a BD não
/// conhece o utilizador do pedido HTTP), por isso o filtro multi-tenant só
/// deixa ver essas entradas para divisao_administrativa (dado partilhado);
/// as restantes só aparecem quando o Projeto ou Utilizador é conhecido.
/// </summary>
public class AuditLogService(IRepository<AuditLog> logs)
{
    public async Task<PagedResult<AuditLogDto>> ListAsync(
        string? entidadeTipo, Guid? entidadeId, Guid? projetoId, Guid? utilizadorId, TipoOperacaoAuditoria? operacao,
        DateTimeOffset? dataInicio, DateTimeOffset? dataFim, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = logs.Query();
        if (!string.IsNullOrWhiteSpace(entidadeTipo)) query = query.Where(l => l.EntidadeTipo == entidadeTipo);
        if (entidadeId is not null) query = query.Where(l => l.EntidadeId == entidadeId);
        if (projetoId is not null) query = query.Where(l => l.ProjetoId == projetoId);
        if (utilizadorId is not null) query = query.Where(l => l.UtilizadorId == utilizadorId);
        if (operacao is not null) query = query.Where(l => l.Operacao == operacao);
        if (dataInicio is not null) query = query.Where(l => l.DataHora >= dataInicio);
        if (dataFim is not null) query = query.Where(l => l.DataHora <= dataFim);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(l => l.DataHora).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<AuditLogDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    private static AuditLogDto ToDto(AuditLog l) => new(
        l.Id, l.UtilizadorId, l.UtilizadorNome, l.Operacao, l.EntidadeTipo, l.EntidadeId, l.ProjetoId,
        l.DadosAnteriores, l.DadosNovos, l.DataHora);
}
