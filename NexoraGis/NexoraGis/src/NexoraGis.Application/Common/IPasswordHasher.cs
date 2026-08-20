namespace NexoraGis.Application.Common;

public interface IPasswordHasher
{
    string Hash(string password);

    /// <summary>True se a password corresponde ao hash guardado.</summary>
    bool Verify(string hashedPassword, string providedPassword);
}
