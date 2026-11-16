using MediatR;

namespace PrismCommerce.Application.Features.Webhooks.ProcessStripeWebhook;

public record ProcessStripeWebhookCommand(string Payload, string? SignatureHeader) : IRequest<bool>;
