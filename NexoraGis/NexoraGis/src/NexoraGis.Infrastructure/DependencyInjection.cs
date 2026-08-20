using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Repositories;
using NexoraGis.Infrastructure.Persistence;
using NexoraGis.Infrastructure.Repositories;
using NexoraGis.Infrastructure.Services;

namespace NexoraGis.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Default")
            ?? throw new InvalidOperationException("Connection string 'Default' não configurada.");

        services.AddSingleton(_ =>
            new NpgsqlDataSourceBuilder(connectionString).MapNexoraGisEnums().Build());

        services.AddDbContext<AppDbContext>((sp, options) =>
        {
            var dataSource = sp.GetRequiredService<NpgsqlDataSource>();
            options.UseNpgsql(dataSource, npgsql => npgsql.UseNetTopologySuite())
                   .UseSnakeCaseNamingConvention();
        });

        services.AddScoped(typeof(IRepository<>), typeof(EfRepository<>));
        services.AddScoped<IUnitOfWork, EfUnitOfWork>();

        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
        services.AddSingleton<IPasswordHasher, Pbkdf2PasswordHasher>();
        services.AddSingleton<IJwtTokenGenerator, JwtTokenGenerator>();
        services.AddSingleton<IReportGenerator, QuestPdfReportGenerator>();

        services.Configure<GeoServerOptions>(configuration.GetSection(GeoServerOptions.SectionName));
        services.AddHttpClient<IGeoServerPublisher, GeoServerPublisher>((sp, client) =>
        {
            var geoServerOptions = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<GeoServerOptions>>().Value;
            client.BaseAddress = new Uri(geoServerOptions.BaseUrl.TrimEnd('/') + "/");
            client.Timeout = TimeSpan.FromSeconds(15);
        });

        return services;
    }
}
