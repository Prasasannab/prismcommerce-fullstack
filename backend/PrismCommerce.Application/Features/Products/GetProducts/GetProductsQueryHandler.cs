using MediatR;
using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Products.GetProducts;

public class GetProductsQueryHandler : IRequestHandler<GetProductsQuery, List<ProductSummaryDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICacheService _cacheService;

    public GetProductsQueryHandler(IApplicationDbContext context, ICacheService cacheService)
    {
        _context = context;
        _cacheService = cacheService;
    }

    public async Task<List<ProductSummaryDto>> Handle(GetProductsQuery request, CancellationToken cancellationToken)
    {
        var cacheKey = $"catalog:products:cat_{request.CategoryId}:search_{request.SearchTerm?.ToLowerInvariant()}:sort_{request.SortBy?.ToLowerInvariant()}:p_{request.PageNumber}:s_{request.PageSize}";

        var cached = await _cacheService.GetAsync<List<ProductSummaryDto>>(cacheKey, cancellationToken);
        if (cached != null)
        {
            return cached;
        }

        var query = _context.Products
            .AsNoTracking()
            .Where(p => p.IsActive);

        if (request.CategoryId.HasValue && request.CategoryId.Value != Guid.Empty)
        {
            query = query.Where(p => p.CategoryId == request.CategoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(request.SearchTerm))
        {
            var term = request.SearchTerm.Trim().ToLower();
            query = query.Where(p => p.Name.ToLower().Contains(term) || p.Description.ToLower().Contains(term));
        }

        query = request.SortBy?.ToLowerInvariant() switch
        {
            "price_asc" => query.OrderBy(p => p.BasePrice),
            "price_desc" => query.OrderByDescending(p => p.BasePrice),
            "newest" => query.OrderByDescending(p => p.CreatedAt),
            "name" => query.OrderBy(p => p.Name),
            _ => query.OrderBy(p => p.Name)
        };

        var skip = (request.PageNumber - 1) * request.PageSize;

        var products = await query
            .Include(p => p.Category)
            .Include(p => p.Variants)
            .Skip(skip)
            .Take(request.PageSize)
            .ToListAsync(cancellationToken);

        var productDtos = products.Select(p => new ProductSummaryDto(
            p.Id,
            p.Name,
            p.Slug,
            p.Description,
            p.BasePrice,
            p.ImageUrls,
            p.Category != null ? p.Category.Name : string.Empty,
            p.Variants.Count
        )).ToList();

        await _cacheService.SetAsync(cacheKey, productDtos, TimeSpan.FromMinutes(10), cancellationToken);

        return productDtos;
    }
}
