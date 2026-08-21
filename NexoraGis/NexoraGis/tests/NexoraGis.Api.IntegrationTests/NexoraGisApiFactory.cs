using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

namespace NexoraGis.Api.IntegrationTests;

/// <summary>
/// Arranca a API em memória. A base de dados aponta de propósito para uma porta
/// que recusa ligação: nada no arranque precisa dela (as migrations só correm
/// com Database__MigrateOnStartup e o BootstrapSeeder sai logo sem
/// Bootstrap__AdminPassword), e assim dá para verificar que a sonda de
/// prontidão relata mesmo o estado da base em vez de responder OK às cegas.
/// </summary>
public class NexoraGisApiFactory : WebApplicationFactory<Program>
{
    public const string UnreachableDatabase =
        "Host=127.0.0.1;Port=1;Database=nexoragis;Username=postgres;Password=x;Timeout=1;Command Timeout=2";

    protected override IHost CreateHost(IHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureHostConfiguration(config => config.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["ConnectionStrings:Default"] = UnreachableDatabase,
            ["Jwt:SigningKey"] = "chave-de-teste-chave-de-teste-32-chars",
            ["Jwt:Issuer"] = "NexoraGis.Api",
            ["Jwt:Audience"] = "NexoraGis.Client",
            ["GeoServer:BaseUrl"] = "http://localhost:8600/geoserver/rest",
            ["Database:MigrateOnStartup"] = "false"
        }));

        return base.CreateHost(builder);
    }
}
