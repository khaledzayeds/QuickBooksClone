namespace QuickBooksClone.Api.Contracts.Estimates;

public sealed record EstimateListResponse(
    IReadOnlyList<EstimateDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
