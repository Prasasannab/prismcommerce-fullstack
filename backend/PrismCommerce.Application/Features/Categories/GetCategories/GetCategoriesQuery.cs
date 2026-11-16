using MediatR;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Categories.GetCategories;

public record GetCategoriesQuery : IRequest<List<CategoryDto>>;
