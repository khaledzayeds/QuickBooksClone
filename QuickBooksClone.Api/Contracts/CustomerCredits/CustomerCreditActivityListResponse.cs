namespace QuickBooksClone.Api.Contracts.CustomerCredits;

public sealed record CustomerCreditActivityListResponse(
    IReadOnlyList<CustomerCreditActivityDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
