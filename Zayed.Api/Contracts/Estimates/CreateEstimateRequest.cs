using Zayed.Core.Estimates;

namespace Zayed.Api.Contracts.Estimates;

public sealed record CreateEstimateRequest(
    Guid CustomerId,
    DateOnly EstimateDate,
    DateOnly ExpirationDate,
    EstimateSaveMode SaveMode,
    IReadOnlyList<CreateEstimateLineRequest> Lines);
