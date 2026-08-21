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

    /// <summary>
    /// Garante a regra ('administrador','*','*'). Devolve true se a acrescentou
    /// (por gravar). O claim "perfil" do JWT vai em snake_case, daí o ToWireString().
    /// </summary>
    private static async Task<bool> EnsurePermissaoAdministradorAsync(AppDbContext db, CancellationToken ct)
    {
        var perfil = PerfilUtilizador.Administrador.ToWireString();

        if (await db.Permissoes.AnyAsync(p => p.Perfil == perfil || p.Perfil == "*", ct))
            return false;

        db.Permissoes.Add(new Permissao { Perfil = perfil, Recurso = "*", Acao = "*" });
        return true;
    }

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

        // A permissão é semeada à parte da organização de propósito: uma base
        // que já tenha organização mas ainda não tenha regras deixaria o RBAC
        // vazio, e o PermissionAuthorizationHandler falha fechado — 403 em todos
        // os endpoints, incluindo ao administrador, sem forma de corrigir pela
        // aplicação (não há endpoint de gestão de permissões).
        var permissaoSemeada = await EnsurePermissaoAdministradorAsync(db, ct);

        if (await db.Organizacoes.AnyAsync(ct))
        {
            if (permissaoSemeada)
            {
                await db.SaveChangesAsync(ct);
                logger?.LogInformation("Bootstrap: permissão de administrador em falta foi semeada.");
            }
            else
            {
                logger?.LogInformation("Bootstrap ignorado: já existe pelo menos uma organização.");
            }

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

        await db.SaveChangesAsync(ct);
        logger?.LogInformation(
            "Bootstrap concluído: organização {Codigo} e administrador {Username} criados.",
            organizacao.Codigo, admin.Username);
    }
}
