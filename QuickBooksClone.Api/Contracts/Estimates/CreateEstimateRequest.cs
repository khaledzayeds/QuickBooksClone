using QuickBooksClone.Core.Estimates;

namespace QuickBooksClone.Api.Contracts.Estimates;

public sealed record CreateEstimateRequest(
    Guid CustomerId,
    DateOnly EstimateDate,
    DateOnly ExpirationDate,
    EstimateSaveMode SaveMode,
    IReadOnlyList<CreateEstimateLineRequest> Lines);
