using MediatR;
using Microsoft.AspNetCore.Mvc;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Application.Features.Categories.GetCategories;

namespace PrismCommerce.Api.Controllers;

public class CategoriesController : BaseApiController
{
    public CategoriesController(ISender mediator) : base(mediator)
    {
    }

    [HttpGet]
    [ProducesResponseType(typeof(List<CategoryDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<List<CategoryDto>>> GetCategories(CancellationToken cancellationToken = default)
    {
        var query = new GetCategoriesQuery();
        var categories = await Mediator.Send(query, cancellationToken);
        return Ok(categories);
    }
}
