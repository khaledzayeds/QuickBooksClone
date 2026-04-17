using System.Collections.Concurrent;
using QuickBooksClone.Core.Items;

namespace QuickBooksClone.Infrastructure.Items;

public sealed class InMemoryItemRepository : IItemRepository
{
    private readonly ConcurrentDictionary<Guid, Item> _items = new();

    public InMemoryItemRepository()
    {
        Seed(new Item("Consulting Hour", ItemType.Service, "SERV-001", null, 750, 0, 0, "hour"));
        Seed(new Item("Receipt Printer", ItemType.Inventory, "INV-PRN-001", "622100000001", 4200, 3100, 12, "pcs"));
        Seed(new Item("Setup Fee", ItemType.NonInventory, "FEE-SETUP", null, 1500, 0, 0, "each"));
    }

    public Task<ItemListResult> SearchAsync(ItemSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _items.Values.AsEnumerable();

        if (!search.IncludeInactive)
        {
            query = query.Where(item => item.IsActive);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(item =>
                Contains(item.Name, term) ||
                Contains(item.Sku, term) ||
                Contains(item.Barcode, term) ||
                item.ItemType.ToString().Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query.OrderBy(item => item.Name).ToList();
        var items = ordered.Skip((page - 1) * pageSize).Take(pageSize).ToList();

        return Task.FromResult(new ItemListResult(items, ordered.Count, page, pageSize));
    }

    public Task<Item?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _items.TryGetValue(id, out var item);
        return Task.FromResult(item);
    }

    public Task<bool> NameExistsAsync(string name, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Exists(item => Same(item.Name, name), excludingId));
    }

    public Task<bool> SkuExistsAsync(string sku, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Exists(item => Same(item.Sku, sku), excludingId));
    }

    public Task<bool> BarcodeExistsAsync(string barcode, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Exists(item => Same(item.Barcode, barcode), excludingId));
    }

    public Task<Item> AddAsync(Item item, CancellationToken cancellationToken = default)
    {
        _items[item.Id] = item;
        return Task.FromResult(item);
    }

    public Task<Item?> UpdateAsync(
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
        CancellationToken cancellationToken = default)
    {
        if (!_items.TryGetValue(id, out var item))
        {
            return Task.FromResult<Item?>(null);
        }

        item.Update(name, itemType, sku, barcode, salesPrice, purchasePrice, unit, incomeAccountId, inventoryAssetAccountId, cogsAccountId, expenseAccountId);
        return Task.FromResult<Item?>(item);
    }

    public Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        if (!_items.TryGetValue(id, out var item))
        {
            return Task.FromResult(false);
        }

        item.SetActive(isActive);
        return Task.FromResult(true);
    }

    public Task<bool> AdjustQuantityAsync(Guid id, decimal quantityOnHand, CancellationToken cancellationToken = default)
    {
        if (!_items.TryGetValue(id, out var item))
        {
            return Task.FromResult(false);
        }

        item.AdjustQuantity(quantityOnHand);
        return Task.FromResult(true);
    }

    public Task<bool> DecreaseQuantityAsync(Guid id, decimal quantity, CancellationToken cancellationToken = default)
    {
        if (!_items.TryGetValue(id, out var item))
        {
            return Task.FromResult(false);
        }

        item.DecreaseQuantity(quantity);
        return Task.FromResult(true);
    }

    private static bool Contains(string? value, string term)
    {
        return value?.Contains(term, StringComparison.OrdinalIgnoreCase) == true;
    }

    private bool Exists(Func<Item, bool> predicate, Guid? excludingId)
    {
        return _items.Values.Any(item => item.Id != excludingId && predicate(item));
    }

    private static bool Same(string? left, string right)
    {
        return string.Equals(left?.Trim(), right.Trim(), StringComparison.OrdinalIgnoreCase);
    }

    private void Seed(Item item)
    {
        _items[item.Id] = item;
    }
}
