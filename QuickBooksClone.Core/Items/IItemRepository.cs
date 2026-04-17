namespace QuickBooksClone.Core.Items;

public interface IItemRepository
{
    Task<ItemListResult> SearchAsync(ItemSearch search, CancellationToken cancellationToken = default);
    Task<Item?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Item> AddAsync(Item item, CancellationToken cancellationToken = default);
    Task<Item?> UpdateAsync(
        Guid id,
        string name,
        ItemType itemType,
        string? sku,
        string? barcode,
        decimal salesPrice,
        decimal purchasePrice,
        string unit,
        Guid? incomeAccountId,
        Guid? inventoryAssetAccountId,
        Guid? cogsAccountId,
        Guid? expenseAccountId,
        CancellationToken cancellationToken = default);
    Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default);
    Task<bool> AdjustQuantityAsync(Guid id, decimal quantityOnHand, CancellationToken cancellationToken = default);
}
