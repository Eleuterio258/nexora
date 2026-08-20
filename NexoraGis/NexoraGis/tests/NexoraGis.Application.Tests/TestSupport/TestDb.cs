using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Infrastructure.Persistence;

namespace NexoraGis.Application.Tests.TestSupport;

/// <summary>
/// Constrói um AppDbContext real (mesmas entidades/configurações/filtros de
/// tenant) sobre o provider InMemory do EF Core, para testar os services da
/// Application sem precisar de um Postgres/PostGIS real.
///
/// Cada chamada a <see cref="Create"/> abre um DbContext NOVO — tal como em
/// produção, onde cada pedido HTTP (ou cada tick do worker em segundo plano)
/// recebe um DbContext próprio via DI scope. Para simular vários "pedidos"
/// sobre os mesmos dados, gera um nome de base de dados com
/// <see cref="NewDatabaseName"/> e reutiliza-o em chamadas sucessivas a
/// <see cref="Create"/> — reutilizar a MESMA instância de DbContext entre
/// "pedidos" diferentes esconderia bugs de tracking que nunca aconteceriam
/// em produção (entidades reconsultadas via AsNoTracking colidem com
/// entidades já rastreadas de um passo anterior no mesmo contexto).
/// </summary>
public static class TestDb
{
    public static string NewDatabaseName() => Guid.NewGuid().ToString();

    public static AppDbContext Create(string? databaseName = null, ICurrentUserService? currentUser = null)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName ?? NewDatabaseName())
            .Options;

        return new AppDbContext(options, currentUser);
    }
}
