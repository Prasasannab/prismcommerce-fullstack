using MediatR;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Products.GetProductById;

public record GetProductByIdQuery(Guid Id) : IRequest<ProductDetailDto>;
