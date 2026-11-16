using Microsoft.AspNetCore.Mvc;

namespace PrismCommerce.Api.Controllers;

[ApiController]
public class HealthController : ControllerBase
{
    [HttpGet("health")]
    [HttpGet("api/v1/health")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult CheckHealth()
    {
        return Ok(new
        {
            status = "Healthy",
            timestamp = DateTime.UtcNow,
            service = "PrismCommerce API",
            version = "1.0.0"
        });
    }
}
