namespace NexoraGis.Domain.Enums;

public static class PerfilUtilizadorExtensions
{
    /// <summary>
    /// Forma canónica em snake_case (ex: GestorPlano -> "gestor_plano"), usada
    /// tanto no claim "perfil" do JWT como em territorial.permissao.perfil —
    /// as duas pontas têm de usar exatamente a mesma convenção.
    /// </summary>
    public static string ToWireString(this PerfilUtilizador perfil) => EnumWireFormat.ToSnakeCase(perfil.ToString());
}
