using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.Common.Models;
using PrismCommerce.Domain.Entities;
using PrismCommerce.Domain.Enums;
using Stripe;

namespace PrismCommerce.Application.Features.Webhooks.ProcessStripeWebhook;

public class ProcessStripeWebhookCommandHandler : IRequestHandler<ProcessStripeWebhookCommand, bool>
{
    private readonly IApplicationDbContext _context;
    private readonly ICacheService _cacheService;
    private readonly StripeSettings _stripeSettings;
    private readonly ILogger<ProcessStripeWebhookCommandHandler> _logger;

    public ProcessStripeWebhookCommandHandler(
        IApplicationDbContext context,
        ICacheService cacheService,
        IOptions<StripeSettings> stripeOptions,
        ILogger<ProcessStripeWebhookCommandHandler> logger)
    {
        _context = context;
        _cacheService = cacheService;
        _stripeSettings = stripeOptions.Value;
        _logger = logger;
    }

    public async Task<bool> Handle(ProcessStripeWebhookCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.SignatureHeader))
        {
            _logger.LogWarning("Stripe webhook received without Stripe-Signature header.");
            throw new StripeException("Missing Stripe-Signature header.");
        }

        if (string.IsNullOrWhiteSpace(_stripeSettings.WebhookSecret))
        {
            _logger.LogError("Stripe WebhookSecret is not configured in application settings.");
            throw new InvalidOperationException("Stripe WebhookSecret is not configured.");
        }

        // 1. HMAC-SHA256 signature verification via Stripe EventUtility.ConstructEvent
        Event stripeEvent;
        try
        {
            stripeEvent = EventUtility.ConstructEvent(
                request.Payload,
                request.SignatureHeader,
                _stripeSettings.WebhookSecret,
                throwOnApiVersionMismatch: false);
        }
        catch (StripeException ex)
        {
            _logger.LogWarning(ex, "Stripe signature verification failed: {Message}", ex.Message);
            throw;
        }

        _logger.LogInformation("Processing validated Stripe webhook event {EventId} of type {EventType}.",
            stripeEvent.Id, stripeEvent.Type);

        // 2. Process specific event types
        return stripeEvent.Type switch
        {
            "payment_intent.succeeded" => await HandlePaymentIntentSucceededAsync(stripeEvent, cancellationToken),
            "payment_intent.payment_failed" => await HandlePaymentIntentPaymentFailedAsync(stripeEvent, cancellationToken),
            _ => HandleUnhandledEvent(stripeEvent)
        };
    }

    private async Task<bool> HandlePaymentIntentSucceededAsync(Event stripeEvent, CancellationToken cancellationToken)
    {
        if (stripeEvent.Data.Object is not PaymentIntent paymentIntent)
        {
            _logger.LogWarning("Webhook event {EventId} object is not a PaymentIntent.", stripeEvent.Id);
            return true;
        }

        var order = await FindOrderForPaymentIntentAsync(paymentIntent, cancellationToken);
        if (order == null)
        {
            _logger.LogWarning("No matching order found for successful PaymentIntent {PaymentIntentId}.", paymentIntent.Id);
            return true;
        }

        // Idempotency check: if order is already Paid/Succeeded, ignore
        if (order.PaymentStatus == PaymentStatus.Succeeded || order.Status == OrderStatus.Paid)
        {
            _logger.LogInformation("Order {OrderNumber} is already marked as Paid. Webhook event skipped idempotently.",
                order.OrderNumber);
            return true;
        }

        using var transaction = await _context.BeginTransactionAsync(cancellationToken);

        // Transition order status
        order.MarkAsPaid(paymentIntent.Id);

        // Fulfill reserved stock permanently
        var variantIds = order.Items.Select(i => i.ProductVariantId).Distinct().ToList();
        var inventoryRecords = await _context.GetInventoryForUpdateAsync(variantIds, cancellationToken);
        var inventoryMap = inventoryRecords.ToDictionary(i => i.ProductVariantId);

        foreach (var item in order.Items)
        {
            if (inventoryMap.TryGetValue(item.ProductVariantId, out var inventory))
            {
                inventory.DeductStock(item.Quantity);
            }
            else
            {
                _logger.LogWarning("Inventory record for variant {VariantId} not found during fulfillment of order {OrderNumber}.",
                    item.ProductVariantId, order.OrderNumber);
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        // Invalidate catalog cache
        await _cacheService.RemoveByPrefixAsync("catalog:products", cancellationToken);

        _logger.LogInformation("Order {OrderNumber} successfully fulfilled: marked as Paid and reserved stock permanently deducted.",
            order.OrderNumber);

        return true;
    }

    private async Task<bool> HandlePaymentIntentPaymentFailedAsync(Event stripeEvent, CancellationToken cancellationToken)
    {
        if (stripeEvent.Data.Object is not PaymentIntent paymentIntent)
        {
            _logger.LogWarning("Webhook event {EventId} object is not a PaymentIntent.", stripeEvent.Id);
            return true;
        }

        var order = await FindOrderForPaymentIntentAsync(paymentIntent, cancellationToken);
        if (order == null)
        {
            _logger.LogWarning("No matching order found for failed PaymentIntent {PaymentIntentId}.", paymentIntent.Id);
            return true;
        }

        // Idempotency check: if already cancelled/failed, ignore
        if (order.Status == OrderStatus.Cancelled || order.PaymentStatus == PaymentStatus.Failed)
        {
            _logger.LogInformation("Order {OrderNumber} is already cancelled. Webhook event skipped idempotently.",
                order.OrderNumber);
            return true;
        }

        using var transaction = await _context.BeginTransactionAsync(cancellationToken);

        // Transition order status to Cancelled and PaymentStatus to Failed
        order.CancelOrder();
        order.PaymentStatus = PaymentStatus.Failed;

        // Release reserved stock back to available pool
        var variantIds = order.Items.Select(i => i.ProductVariantId).Distinct().ToList();
        var inventoryRecords = await _context.GetInventoryForUpdateAsync(variantIds, cancellationToken);
        var inventoryMap = inventoryRecords.ToDictionary(i => i.ProductVariantId);

        foreach (var item in order.Items)
        {
            if (inventoryMap.TryGetValue(item.ProductVariantId, out var inventory))
            {
                inventory.ReleaseReservation(item.Quantity);
            }
            else
            {
                _logger.LogWarning("Inventory record for variant {VariantId} not found while releasing reserved stock for order {OrderNumber}.",
                    item.ProductVariantId, order.OrderNumber);
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        // Invalidate catalog cache
        await _cacheService.RemoveByPrefixAsync("catalog:products", cancellationToken);

        _logger.LogInformation("Order {OrderNumber} cancelled and reserved inventory released back due to payment failure.",
            order.OrderNumber);

        return true;
    }

    private async Task<Order?> FindOrderForPaymentIntentAsync(PaymentIntent paymentIntent, CancellationToken cancellationToken)
    {
        // Try looking up by StripePaymentIntentId
        var order = await _context.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.StripePaymentIntentId == paymentIntent.Id, cancellationToken);

        if (order != null)
        {
            return order;
        }

        // Fallback to metadata
        if (paymentIntent.Metadata != null)
        {
            if (paymentIntent.Metadata.TryGetValue("OrderId", out var orderIdStr) && Guid.TryParse(orderIdStr, out var orderId))
            {
                order = await _context.Orders
                    .Include(o => o.Items)
                    .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

                if (order != null) return order;
            }

            if (paymentIntent.Metadata.TryGetValue("OrderNumber", out var orderNumber) && !string.IsNullOrWhiteSpace(orderNumber))
            {
                order = await _context.Orders
                    .Include(o => o.Items)
                    .FirstOrDefaultAsync(o => o.OrderNumber == orderNumber, cancellationToken);

                if (order != null) return order;
            }
        }

        return null;
    }

    private bool HandleUnhandledEvent(Event stripeEvent)
    {
        _logger.LogInformation("Unhandled Stripe webhook event type {EventType} received and acknowledged.", stripeEvent.Type);
        return true;
    }
}
