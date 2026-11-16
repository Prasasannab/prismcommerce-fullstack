using MediatR;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Products.GetProducts;

public record GetProductsQuery(
    Guid? CategoryId = null,
    string? SearchTerm = null,
    string? SortBy = null,
    int PageNumber = 1,
    int PageSize = 20) : IRequest<List<ProductSummaryDto>>;
