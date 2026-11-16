using PrismCommerce.Domain.Common;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Domain.Entities;

public class Product : BaseEntity, IAggregateRoot
{
    public Guid CategoryId { get; set; }
    public Category? Category { get; set; }

    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal BasePrice { get; set; }
    public bool IsActive { get; set; } = true;
    public List<string> ImageUrls { get; set; } = new();

    public ICollection<ProductVariant> Variants { get; set; } = new List<ProductVariant>();

    public Product()
    {
    }

    public Product(
        Guid categoryId,
        string name,
        string slug,
        string description,
        decimal basePrice,
        bool isActive = true,
        List<string>? imageUrls = null)
    {
        if (categoryId == Guid.Empty)
            throw new DomainException("Valid category ID is required.");
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("Product name cannot be empty.");
        if (string.IsNullOrWhiteSpace(slug))
            throw new DomainException("Product slug cannot be empty.");
        if (basePrice < 0)
            throw new DomainException("Base price cannot be negative.");

        CategoryId = categoryId;
        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Description = description.Trim();
        BasePrice = basePrice;
        IsActive = isActive;
        ImageUrls = imageUrls ?? new List<string>();
    }
}
