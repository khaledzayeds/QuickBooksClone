namespace Zayed.Core.CustomerCredits;

public sealed record CustomerCreditActivityListResult(
    IReadOnlyList<CustomerCreditActivity> Items,
    int TotalCount,
    int Page,
    int PageSize);
