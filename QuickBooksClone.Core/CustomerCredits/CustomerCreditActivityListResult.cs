namespace QuickBooksClone.Core.CustomerCredits;

public sealed record CustomerCreditActivityListResult(
    IReadOnlyList<CustomerCreditActivity> Items,
    int TotalCount,
    int Page,
    int PageSize);
