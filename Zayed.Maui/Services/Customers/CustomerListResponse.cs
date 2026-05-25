namespace Zayed.Maui.Services.Customers;

public sealed record CustomerListResponse(
    IReadOnlyList<CustomerDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
