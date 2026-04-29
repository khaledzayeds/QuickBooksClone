using QuickBooksClone.Core.Estimates;

namespace QuickBooksClone.Api.Contracts.Estimates;

public sealed record EstimateDto(
    Guid Id,
    string EstimateNumber,
    Guid CustomerId,
    string? CustomerName,
    DateOnly EstimateDate,
    DateOnly ExpirationDate,
    EstimateStatus Status,
    decimal Subtotal,
    decimal TaxAmount,
    decimal TotalAmount,
    DateTimeOffset? SentAt,
    DateTimeOffset? AcceptedAt,
    DateTimeOffset? DeclinedAt,
    DateTimeOffset? CancelledAt,
    IReadOnlyList<EstimateLineDto> Lines);
