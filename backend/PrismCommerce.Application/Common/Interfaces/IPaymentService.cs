namespace PrismCommerce.Application.Common.Interfaces;

public record PaymentIntentResult(string PaymentIntentId, string ClientSecret);

public interface IPaymentService
{
    Task<PaymentIntentResult> CreatePaymentIntentAsync(
        decimal amount,
        string currency,
        string orderNumber,
        Dictionary<string, string>? metadata = null,
        CancellationToken cancellationToken = default);
}
