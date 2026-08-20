using Microsoft.Extensions.DependencyInjection;
using NexoraGis.Application.Features.AdministrativeDivisions;
using NexoraGis.Application.Features.Approvals;
using NexoraGis.Application.Features.Audit;
using NexoraGis.Application.Features.Auth;
using NexoraGis.Application.Features.Conflicts;
using NexoraGis.Application.Features.Entities;
using NexoraGis.Application.Features.Export;
using NexoraGis.Application.Features.Gis;
using NexoraGis.Application.Features.Infrastructure;
using NexoraGis.Application.Features.Inspections;
using NexoraGis.Application.Features.Parcels;
using NexoraGis.Application.Features.Plans;
using NexoraGis.Application.Features.Projects;
using NexoraGis.Application.Features.Reports;
using NexoraGis.Application.Features.Spatial;
using NexoraGis.Application.Features.Surveys;
using NexoraGis.Application.Features.Versioning;
using NexoraGis.Application.Features.Zoning;

namespace NexoraGis.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<AuthService>();
        services.AddScoped<AdministrativeDivisionService>();
        services.AddScoped<ProjetoService>();
        services.AddScoped<ParcelaService>();
        services.AddScoped<LoteService>();
        services.AddScoped<EdificacaoService>();
        services.AddScoped<EntidadeService>();
        services.AddScoped<InfraestruturaService>();
        services.AddScoped<EquipamentoService>();
        services.AddScoped<LevantamentoService>();
        services.AddScoped<SyncService>();
        services.AddScoped<CamadaService>();
        services.AddScoped<PlanoService>();
        services.AddScoped<ZonaService>();
        services.AddScoped<ConflitoService>();
        services.AddScoped<SpatialAnalysisService>();
        services.AddScoped<AprovacaoService>();
        services.AddScoped<VersioningService>();
        services.AddScoped<AuditLogService>();
        services.AddScoped<FiscalizacaoService>();
        services.AddScoped<ExportService>();
        services.AddScoped<ReportService>();
        return services;
    }
}
