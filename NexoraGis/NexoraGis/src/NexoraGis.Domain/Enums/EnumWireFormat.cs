using System.Text;

namespace NexoraGis.Domain.Enums;

/// <summary>
/// Forma canónica "wire" (snake_case) dos enums do domínio — usada tanto nas
/// colunas da BD (para bater certo com os scripts de seed em SQL puro, que já
/// usam esta convenção) como em qualquer outro sítio que precise do mesmo
/// valor textual em ambas as pontas (ex: claims do JWT).
/// </summary>
public static class EnumWireFormat
{
    public static string ToSnakeCase(string pascalCase)
    {
        var sb = new StringBuilder(pascalCase.Length + 4);

        for (var i = 0; i < pascalCase.Length; i++)
        {
            if (i > 0 && char.IsUpper(pascalCase[i]))
                sb.Append('_');

            sb.Append(char.ToLowerInvariant(pascalCase[i]));
        }

        return sb.ToString();
    }

    public static string FromSnakeCase(string snakeCase)
    {
        var sb = new StringBuilder(snakeCase.Length);
        var capitalizeNext = true;

        foreach (var c in snakeCase)
        {
            if (c == '_')
            {
                capitalizeNext = true;
                continue;
            }

            sb.Append(capitalizeNext ? char.ToUpperInvariant(c) : c);
            capitalizeNext = false;
        }

        return sb.ToString();
    }
}
