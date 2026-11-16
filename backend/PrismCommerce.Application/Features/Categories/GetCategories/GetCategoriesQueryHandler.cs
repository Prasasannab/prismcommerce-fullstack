using MediatR;
using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Categories.GetCategories;

public class GetCategoriesQueryHandler : IRequestHandler<GetCategoriesQuery, List<CategoryDto>>
{
    private const string CacheKey = "catalog:categories:all";
    private readonly IApplicationDbContext _context;
    private readonly ICacheService _cacheService;

    public GetCategoriesQueryHandler(IApplicationDbContext context, ICacheService cacheService)
    {
        _context = context;
        _cacheService = cacheService;
    }

    public async Task<List<CategoryDto>> Handle(GetCategoriesQuery request, CancellationToken cancellationToken)
    {
        var cached = await _cacheService.GetAsync<List<CategoryDto>>(CacheKey, cancellationToken);
        if (cached != null)
        {
            return cached;
        }

        var categories = await _context.Categories
            .AsNoTracking()
            .OrderBy(c => c.Name)
            .Select(c => new CategoryDto(
                c.Id,
                c.Name,
                c.Slug,
                c.Description,
                c.ImageUrl,
                c.Products.Count(p => p.IsActive)
            ))
            .ToListAsync(cancellationToken);

        await _cacheService.SetAsync(CacheKey, categories, TimeSpan.FromMinutes(10), cancellationToken);

        return categories;
    }
}
