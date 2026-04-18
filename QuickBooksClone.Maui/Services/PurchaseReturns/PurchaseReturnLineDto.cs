namespace QuickBooksClone.Maui.Services.PurchaseReturns;

public sealed record PurchaseReturnLineDto(Guid Id, Guid PurchaseBillLineId, Guid ItemId, string Description, decimal Quantity, decimal UnitCost, decimal LineTotal);
