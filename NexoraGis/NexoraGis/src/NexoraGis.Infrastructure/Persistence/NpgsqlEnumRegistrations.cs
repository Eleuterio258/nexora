using Npgsql;

namespace NexoraGis.Infrastructure.Persistence;

/// <summary>
/// Extensões ao NpgsqlDataSourceBuilder partilhadas entre o arranque normal da
/// API e a factory de design-time (migrations), para que ambos vejam o mesmo
/// modelo de tipos.
/// </summary>
public static class NpgsqlEnumRegistrations
{
    public static NpgsqlDataSourceBuilder MapNexoraGisEnums(this NpgsqlDataSourceBuilder builder)
    {
        builder.UseNetTopologySuite();
        return builder;
    }
}
