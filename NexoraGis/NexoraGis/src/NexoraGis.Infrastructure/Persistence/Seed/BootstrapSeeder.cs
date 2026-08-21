using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Infrastructure.Persistence.Seed;

/// <summary>
/// Cria a organização inicial e o primeiro administrador em ambientes não-Development
/// (ex.: o container em produção), a partir da secção de configuração "Bootstrap".
///
/// Só actua quando <c>Bootstrap:AdminPassword</c> está definida e a base ainda não
/// tem nenhuma organização — nunca inventa uma palavra-passe por omissão, para não
/// deixar um administrador com credenciais conhecidas exposto na Internet.
/// </summary>
public static class BootstrapSeeder
{
    public const string SectionName = "Bootstrap";

    public static async Task SeedAsync(
        AppDbContext db,
        IPasswordHasher passwordHasher,
        IConfiguration configuration,
        ILogger? logger = null,
        CancellationToken ct = default)
    {
        var section = configuration.GetSection(SectionName);
        var password = section["AdminPassword"];

        if (string.IsNullOrWhiteSpace(password))
            return;

        if (await db.Organizacoes.AnyAsync(ct))
        {
            logger?.LogInformation("Bootstrap ignorado: já existe pelo menos uma organização.");
            return;
        }

        var organizacao = new Organizacao
        {
            Codigo = section["OrganizacaoCodigo"] ?? "NEXORAGIS",
            Designacao = section["OrganizacaoDesignacao"] ?? "Organização NexoraGis",
            Tipo = section["OrganizacaoTipo"] ?? "instituicao"
        };
        db.Organizacoes.Add(organizacao);

        var admin = new Utilizador
        {
            OrganizacaoId = organizacao.Id,
            Organizacao = organizacao,
            Username = section["AdminUsername"] ?? "admin",
            Email = section["AdminEmail"] ?? "admin@nexoragis.local",
            PasswordHash = passwordHasher.Hash(password),
            NomeCompleto = section["AdminNome"] ?? "Administrador NexoraGis",
            Perfil = PerfilUtilizador.Administrador
        };
        db.Utilizadores.Add(admin);

        // Sem esta linha o RBAC (territorial.permissao) fica vazio e o próprio
        // administrador leva 403 em todos os endpoints — o handler só autoriza
        // o que estiver na tabela. O claim "perfil" vai em snake_case.
        if (!await db.Permissoes.AnyAsync(ct))
        {
            db.Permissoes.Add(new Permissao
            {
                Perfil = PerfilUtilizador.Administrador.ToWireString(),
                Recurso = "*",
                Acao = "*"
            });
        }

        await db.SaveChangesAsync(ct);
        logger?.LogInformation(
            "Bootstrap concluído: organização {Codigo} e administrador {Username} criados.",
            organizacao.Codigo, admin.Username);
    }
}
