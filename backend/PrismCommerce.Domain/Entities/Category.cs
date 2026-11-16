using PrismCommerce.Domain.Common;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Domain.Entities;

public class Category : BaseEntity, IAggregateRoot
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }

    public ICollection<Product> Products { get; set; } = new List<Product>();

    public Category()
    {
    }

    public Category(string name, string slug, string? description = null, string? imageUrl = null)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("Category name cannot be empty.");
        if (string.IsNullOrWhiteSpace(slug))
            throw new DomainException("Category slug cannot be empty.");

        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Description = description?.Trim();
        ImageUrl = imageUrl?.Trim();
    }
}
