using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace PrismCommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public abstract class BaseApiController : ControllerBase
{
    protected readonly ISender Mediator;

    protected BaseApiController(ISender mediator)
    {
        Mediator = mediator;
    }
}
