namespace QuickBooksClone.Api.Contracts.PurchaseReturns;

public sealed record CreatePurchaseReturnLineRequest(
    Guid PurchaseBillLineId,
    decimal Quantity,
    decimal? UnitCost);
