namespace QuickBooksClone.Api.Contracts.Items;

public sealed record BulkPriceChangeRequest(
    List<Guid> ItemIds,
    PriceChangeTarget Target,   // SalesPrice | PurchasePrice | Both
    PriceChangeMode Mode,       // SetFixed | IncreaseByAmount | IncreaseByPercent | DecreaseByAmount | DecreaseByPercent
    decimal Value);

public enum PriceChangeTarget { SalesPrice = 1, PurchasePrice = 2, Both = 3 }
public enum PriceChangeMode   { SetFixed = 1, IncreaseByAmount = 2, IncreaseByPercent = 3, DecreaseByAmount = 4, DecreaseByPercent = 5 }

public sealed record BulkPriceChangeResponse(int UpdatedCount, List<string> Errors);
