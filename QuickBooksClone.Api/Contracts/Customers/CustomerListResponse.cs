namespace QuickBooksClone.Api.Contracts.Customers;

public sealed record CustomerListResponse(
    IReadOnlyList<CustomerDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
