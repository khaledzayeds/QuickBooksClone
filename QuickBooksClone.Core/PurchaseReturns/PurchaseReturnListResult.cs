namespace QuickBooksClone.Core.PurchaseReturns;

public sealed record PurchaseReturnListResult(IReadOnlyList<PurchaseReturn> Items, int TotalCount, int Page, int PageSize);
