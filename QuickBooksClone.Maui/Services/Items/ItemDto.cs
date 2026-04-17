namespace QuickBooksClone.Maui.Services.Items;

public sealed record ItemDto(
    Guid Id,
    string Name,
    ItemType ItemType,
    string? Sku,
    string? Barcode,
    decimal SalesPrice,
    decimal PurchasePrice,
    decimal QuantityOnHand,
    string Unit,
    Guid? IncomeAccountId,
    Guid? InventoryAssetAccountId,
    Guid? CogsAccountId,
    Guid? ExpenseAccountId,
    bool IsActive);
