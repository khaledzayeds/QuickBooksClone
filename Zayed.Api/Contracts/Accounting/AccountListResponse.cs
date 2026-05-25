namespace Zayed.Api.Contracts.Accounting;

public sealed record AccountListResponse(
    IReadOnlyList<AccountDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
