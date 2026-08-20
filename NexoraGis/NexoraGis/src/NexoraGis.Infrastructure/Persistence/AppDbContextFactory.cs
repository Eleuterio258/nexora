using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Npgsql;

namespace NexoraGis.Infrastructure.Persistence;

/// <summary>
/// Usada apenas por ferramentas de design-time (`dotnet ef migrations add`,
/// `dotnet ef database update`), fora do pipeline normal de DI da API.
/// </summary>
public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("NEXORAGIS_CONNECTION_STRING")
            ?? "Host=127.0.0.1;Port=5434;Database=nexoragis;Username=nexoragis;Password=nexoragis_dev_pw;SSL Mode=Disable";

        var dataSource = new NpgsqlDataSourceBuilder(connectionString).MapNexoraGisEnums().Build();

        var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
        optionsBuilder.UseNpgsql(dataSource, npgsql => npgsql.UseNetTopologySuite())
                      .UseSnakeCaseNamingConvention();

        return new AppDbContext(optionsBuilder.Options);
    }
}
