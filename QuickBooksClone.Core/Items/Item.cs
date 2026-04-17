using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Items;

public sealed class Item : EntityBase, ITenantEntity
{
    public Item(
        string name,
        ItemType itemType,
        string? sku,
        string? barcode,
        decimal salesPrice,
        decimal purchasePrice,
        decimal quantityOnHand,
        string unit,
        Guid? incomeAccountId = null,
        Guid? inventoryAssetAccountId = null,
        Guid? cogsAccountId = null,
        Guid? expenseAccountId = null,
        Guid? companyId = null)
    {
        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        Name = NormalizeRequired(name, nameof(name));
        ItemType = itemType;
        Sku = NormalizeOptional(sku);
        Barcode = NormalizeOptional(barcode);
        SalesPrice = salesPrice;
        PurchasePrice = purchasePrice;
        QuantityOnHand = quantityOnHand;
        Unit = string.IsNullOrWhiteSpace(unit) ? "pcs" : unit.Trim();
        IncomeAccountId = incomeAccountId;
        InventoryAssetAccountId = inventoryAssetAccountId;
        CogsAccountId = cogsAccountId;
        ExpenseAccountId = expenseAccountId;
        IsActive = true;
    }

    public Guid CompanyId { get; }
    public string Name { get; private set; }
    public ItemType ItemType { get; private set; }
    public string? Sku { get; private set; }
    public string? Barcode { get; private set; }
    public decimal SalesPrice { get; private set; }
    public decimal PurchasePrice { get; private set; }
    public decimal QuantityOnHand { get; private set; }
    public string Unit { get; private set; }
    public Guid? IncomeAccountId { get; private set; }
    public Guid? InventoryAssetAccountId { get; private set; }
    public Guid? CogsAccountId { get; private set; }
    public Guid? ExpenseAccountId { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(
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
        Guid? expenseAccountId)
    {
        Name = NormalizeRequired(name, nameof(name));
        ItemType = itemType;
        Sku = NormalizeOptional(sku);
        Barcode = NormalizeOptional(barcode);
        SalesPrice = salesPrice;
        PurchasePrice = purchasePrice;
        Unit = string.IsNullOrWhiteSpace(unit) ? "pcs" : unit.Trim();
        IncomeAccountId = incomeAccountId;
        InventoryAssetAccountId = inventoryAssetAccountId;
        CogsAccountId = cogsAccountId;
        ExpenseAccountId = expenseAccountId;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetAccountLinks(Guid? incomeAccountId, Guid? inventoryAssetAccountId, Guid? cogsAccountId, Guid? expenseAccountId)
    {
        IncomeAccountId = incomeAccountId;
        InventoryAssetAccountId = inventoryAssetAccountId;
        CogsAccountId = cogsAccountId;
        ExpenseAccountId = expenseAccountId;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void AdjustQuantity(decimal quantityOnHand)
    {
        if (quantityOnHand < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(quantityOnHand), "Quantity cannot be negative.");
        }

        QuantityOnHand = quantityOnHand;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void DecreaseQuantity(decimal quantity)
    {
        if (quantity <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(quantity), "Quantity must be greater than zero.");
        }

        if (QuantityOnHand < quantity)
        {
            throw new InvalidOperationException("Not enough quantity on hand.");
        }

        QuantityOnHand -= quantity;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private static string NormalizeRequired(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        return value.Trim();
    }

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
