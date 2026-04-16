namespace QuickBooksClone.Core.Customers;

public sealed record CustomerListResult(
    IReadOnlyList<Customer> Items,
    int TotalCount,
    int Page,
    int PageSize);
