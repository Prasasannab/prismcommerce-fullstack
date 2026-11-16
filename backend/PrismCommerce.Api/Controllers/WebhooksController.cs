using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrismCommerce.Application.Features.Webhooks.ProcessStripeWebhook;
using Stripe;

namespace PrismCommerce.Api.Controllers;

[AllowAnonymous]
public class WebhooksController : BaseApiController
{
    public WebhooksController(ISender mediator) : base(mediator)
    {
    }

    [HttpPost("stripe")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> StripeWebhook(CancellationToken cancellationToken)
    {
        string json;
        using (var reader = new StreamReader(Request.Body))
        {
            json = await reader.ReadToEndAsync(cancellationToken);
        }

        var signatureHeader = Request.Headers["Stripe-Signature"].ToString();

        try
        {
            var command = new ProcessStripeWebhookCommand(json, signatureHeader);
            await Mediator.Send(command, cancellationToken);
            return Ok(new { received = true });
        }
        catch (StripeException ex)
        {
            return BadRequest(new ProblemDetails
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "Invalid Webhook Signature",
                Detail = ex.Message,
                Instance = HttpContext.Request.Path
            });
        }
    }
}
