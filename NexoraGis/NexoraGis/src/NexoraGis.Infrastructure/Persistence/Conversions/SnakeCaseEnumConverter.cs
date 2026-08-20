using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Infrastructure.Persistence.Conversions;

/// <summary>
/// Guarda enums do domínio como texto em snake_case (ex: TipoDivisao.DistritoMunicipal
/// -> "distrito_municipal"), a mesma convenção usada pelos scripts de seed em
/// SQL puro e pelo claim "perfil" do JWT.
/// </summary>
public class SnakeCaseEnumConverter<TEnum>() : ValueConverter<TEnum, string>(
    v => EnumWireFormat.ToSnakeCase(v.ToString()!),
    v => Enum.Parse<TEnum>(EnumWireFormat.FromSnakeCase(v), ignoreCase: true))
    where TEnum : struct, Enum;
