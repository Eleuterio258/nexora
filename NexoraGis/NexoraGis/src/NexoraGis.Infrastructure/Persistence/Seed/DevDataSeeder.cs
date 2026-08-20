using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Infrastructure.Persistence.Seed;

/// <summary>
/// Cria uma organização e um utilizador administrador de desenvolvimento, se
/// ainda não existir nenhuma organização. Apenas para ambientes de Development
/// — nunca correr contra produção.
/// </summary>
public static class DevDataSeeder
{
    public static async Task SeedAsync(AppDbContext db, IPasswordHasher passwordHasher, CancellationToken ct = default)
    {
        if (await db.Organizacoes.AnyAsync(ct))
            return;

        var organizacao = new Organizacao
        {
            Codigo = "DEV",
            Designacao = "Organização de Desenvolvimento",
            Tipo = "instituicao"
        };
        db.Organizacoes.Add(organizacao);

        var admin = new Utilizador
        {
            OrganizacaoId = organizacao.Id,
            Organizacao = organizacao,
            Username = "admin",
            Email = "admin@nexoragis.local",
            PasswordHash = passwordHasher.Hash("Admin@123"),
            NomeCompleto = "Administrador NexoraGis",
            Perfil = PerfilUtilizador.Administrador
        };
        db.Utilizadores.Add(admin);

        await db.SaveChangesAsync(ct);
    }
}
