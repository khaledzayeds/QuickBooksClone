namespace QuickBooksClone.Maui.Services.PurchaseReturns;

public sealed record PurchaseReturnListResponse(IReadOnlyList<PurchaseReturnDto> Items, int TotalCount, int Page, int PageSize);
