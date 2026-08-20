using System.Text;

namespace NexoraGis.Infrastructure.Services;

public static class JwtSigningKeyFactory
{
    /// <summary>Aceita a chave em texto simples (dev) e garante o tamanho mínimo exigido por HS256 (32 bytes).</summary>
    public static byte[] GetKeyBytes(string key)
    {
        var bytes = Encoding.UTF8.GetBytes(key);
        if (bytes.Length >= 32)
            return bytes;

        Array.Resize(ref bytes, 32);
        return bytes;
    }
}
