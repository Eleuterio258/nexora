namespace NexoraGis.Infrastructure.Services;

public class GeoServerOptions
{
    public const string SectionName = "GeoServer";

    public string BaseUrl { get; set; } = "http://localhost:8600/geoserver/rest";
    public string Username { get; set; } = "admin";
    public string Password { get; set; } = string.Empty;
    public string Workspace { get; set; } = "nexoragis";

    /// <summary>Parâmetros de ligação PostGIS do datastore criado no GeoServer — a mesma BD da aplicação.</summary>
    public string DbHost { get; set; } = "db";
    public int DbPort { get; set; } = 5432;
    public string DbName { get; set; } = "nexoragis";
    public string DbUser { get; set; } = "nexoragis";
    public string DbPassword { get; set; } = string.Empty;
    public string DbSchema { get; set; } = "cadastro";
    public string DataStore { get; set; } = "nexoragis_postgis";
}
