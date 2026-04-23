namespace QuickBooksClone.Maui.Services.SalesOrders;

public sealed class SalesOrderFormModel
{
    public Guid CustomerId { get; set; }
    public DateOnly OrderDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public DateOnly ExpectedDate { get; set; } = DateOnly.FromDateTime(DateTime.Today.AddDays(7));
    public SalesOrderSaveMode SaveMode { get; set; } = SalesOrderSaveMode.SaveAsOpen;
    public List<SalesOrderLineFormModel> Lines { get; } = [];
}

public sealed class SalesOrderLineFormModel
{
    public Guid ItemId { get; set; }
    public string? Description { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public sealed record SalesOrderLineDto(
    Guid Id,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal LineTotal);

public sealed record SalesOrderDto(
    Guid Id,
    string OrderNumber,
    Guid CustomerId,
    string? CustomerName,
    DateOnly OrderDate,
    DateOnly ExpectedDate,
    SalesOrderStatus Status,
    decimal TotalAmount,
    DateTimeOffset? OpenedAt,
    DateTimeOffset? ClosedAt,
    DateTimeOffset? CancelledAt,
    IReadOnlyList<SalesOrderLineDto> Lines);

public sealed record SalesOrderListResponse(
    IReadOnlyList<SalesOrderDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
