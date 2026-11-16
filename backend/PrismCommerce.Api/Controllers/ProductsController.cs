using MediatR;
using Microsoft.AspNetCore.Mvc;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Application.Features.Products.GetProductById;
using PrismCommerce.Application.Features.Products.GetProducts;

namespace PrismCommerce.Api.Controllers;

public class ProductsController : BaseApiController
{
    public ProductsController(ISender mediator) : base(mediator)
    {
    }

    [HttpGet]
    [ProducesResponseType(typeof(List<ProductSummaryDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<List<ProductSummaryDto>>> GetProducts(
        [FromQuery] Guid? categoryId = null,
        [FromQuery] string? searchTerm = null,
        [FromQuery] string? sortBy = null,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var query = new GetProductsQuery(categoryId, searchTerm, sortBy, pageNumber, pageSize);
        var products = await Mediator.Send(query, cancellationToken);
        return Ok(products);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ProductDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductDetailDto>> GetProductById(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var query = new GetProductByIdQuery(id);
        var product = await Mediator.Send(query, cancellationToken);
        return Ok(product);
    }
}
