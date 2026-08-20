namespace NexoraGis.Domain.Common;

public class DomainException : Exception
{
    public DomainException(string message) : base(message) { }

    public DomainException(string message, Exception innerException)
        : base(message, innerException) { }
}

public class NotFoundException : DomainException
{
    public NotFoundException(string entityName, object key)
        : base($"Entity '{entityName}' with key '{key}' was not found.") { }
}

public class DomainValidationException : DomainException
{
    public IReadOnlyCollection<string> Errors { get; }

    public DomainValidationException(string message)
        : base(message)
    {
        Errors = new[] { message };
    }

    public DomainValidationException(IEnumerable<string> errors)
        : base(string.Join("; ", errors))
    {
        Errors = errors.ToList().AsReadOnly();
    }
}
