using MediatR;
using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Domain.Entities;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Application.Features.Products.GetProductById;

public class GetProductByIdQueryHandler : IRequestHandler<GetProductByIdQuery, ProductDetailDto>
{
    private readonly IApplicationDbContext _context;

    public GetProductByIdQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ProductDetailDto> Handle(GetProductByIdQuery request, CancellationToken cancellationToken)
    {
        var product = await _context.Products
            .AsNoTracking()
            .Include(p => p.Category)
            .Include(p => p.Variants)
                .ThenInclude(v => v.Inventory)
            .FirstOrDefaultAsync(p => p.Id == request.Id && p.IsActive, cancellationToken);

        if (product == null)
        {
            throw new EntityNotFoundException(nameof(Product), request.Id);
        }

        var categoryDto = new CategoryDto(
            product.Category?.Id ?? product.CategoryId,
            product.Category?.Name ?? string.Empty,
            product.Category?.Slug ?? string.Empty,
            product.Category?.Description,
            product.Category?.ImageUrl);

        var variantDtos = product.Variants.Select(v => new ProductVariantDto(
            v.Id,
            v.Sku,
            v.Title,
            v.Color,
            v.Size,
            v.PriceAdjustment,
            product.BasePrice + v.PriceAdjustment,
            v.Inventory?.AvailableStock ?? 0
        )).ToList();

        return new ProductDetailDto(
            product.Id,
            product.Name,
            product.Slug,
            product.Description,
            product.BasePrice,
            product.ImageUrls,
            categoryDto,
            variantDtos);
    }
}
