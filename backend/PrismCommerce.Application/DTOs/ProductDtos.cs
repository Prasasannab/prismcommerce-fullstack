namespace PrismCommerce.Application.DTOs;

public record CategoryDto(
    Guid Id,
    string Name,
    string Slug,
    string? Description,
    string? ImageUrl,
    int ProductCount = 0);

public record ProductVariantDto(
    Guid Id,
    string Sku,
    string Title,
    string? Color,
    string? Size,
    decimal PriceAdjustment,
    decimal FinalPrice,
    int AvailableStock);

public record ProductSummaryDto(
    Guid Id,
    string Name,
    string Slug,
    string Description,
    decimal BasePrice,
    List<string> ImageUrls,
    string CategoryName,
    int VariantCount);

public record ProductDetailDto(
    Guid Id,
    string Name,
    string Slug,
    string Description,
    decimal BasePrice,
    List<string> ImageUrls,
    CategoryDto Category,
    List<ProductVariantDto> Variants);
