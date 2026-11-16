namespace PrismCommerce.Domain.Exceptions;

/// <summary>
/// Exception thrown when an expected domain entity cannot be found.
/// </summary>
public class EntityNotFoundException : DomainException
{
    public string EntityName { get; }
    public object Key { get; }

    public EntityNotFoundException(string entityName, object key)
        : base($"Entity '{entityName}' with key '{key}' was not found.")
    {
        EntityName = entityName;
        Key = key;
    }

    public EntityNotFoundException(string message) : base(message)
    {
        EntityName = string.Empty;
        Key = string.Empty;
    }
}
