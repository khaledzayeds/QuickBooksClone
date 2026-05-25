namespace Zayed.Api.Contracts.PurchaseReturns;

public sealed record PurchaseReturnListResponse(IReadOnlyList<PurchaseReturnDto> Items, int TotalCount, int Page, int PageSize);
