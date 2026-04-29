namespace QuickBooksClone.Core.Taxes;

public enum TaxCodeScope
{
    Sales = 1,
    Purchase = 2,
    Both = 3
}

public enum TaxTransactionType
{
    Sales = 1,
    Purchase = 2
}

public enum TaxRoundingMode
{
    PerLine = 1,
    PerDocument = 2
}
