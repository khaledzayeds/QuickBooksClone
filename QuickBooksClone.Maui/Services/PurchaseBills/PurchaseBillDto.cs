namespace QuickBooksClone.Maui.Services.PurchaseBills;

public sealed record PurchaseBillDto(
    Guid Id,
    string BillNumber,
    Guid VendorId,
    string? VendorName,
    DateOnly BillDate,
    DateOnly DueDate,
    PurchaseBillStatus Status,
    decimal TotalAmount,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt,
    IReadOnlyList<PurchaseBillLineDto> Lines);
