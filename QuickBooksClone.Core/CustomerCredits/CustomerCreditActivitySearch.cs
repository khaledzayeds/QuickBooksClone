namespace QuickBooksClone.Core.CustomerCredits;

public sealed record CustomerCreditActivitySearch(
    string? Search = null,
    Guid? CustomerId = null,
    CustomerCreditAction? Action = null,
    bool IncludeVoid = false,
    int Page = 1,
    int PageSize = 25);
