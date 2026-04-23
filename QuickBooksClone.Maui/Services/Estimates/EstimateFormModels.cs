namespace QuickBooksClone.Maui.Services.Estimates;

public sealed class EstimateFormModel
{
    public Guid CustomerId { get; set; }
    public DateOnly EstimateDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public DateOnly ExpirationDate { get; set; } = DateOnly.FromDateTime(DateTime.Today.AddDays(14));
    public EstimateSaveMode SaveMode { get; set; } = EstimateSaveMode.SaveAsSent;
    public List<EstimateLineFormModel> Lines { get; } = [];
}

public sealed class EstimateLineFormModel
{
    public Guid ItemId { get; set; }
    public string? Description { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public sealed record EstimateLineDto(
    Guid Id,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal LineTotal);

public sealed record EstimateDto(
    Guid Id,
    string EstimateNumber,
    Guid CustomerId,
    string? CustomerName,
    DateOnly EstimateDate,
    DateOnly ExpirationDate,
    EstimateStatus Status,
    decimal TotalAmount,
    DateTimeOffset? SentAt,
    DateTimeOffset? AcceptedAt,
    DateTimeOffset? DeclinedAt,
    DateTimeOffset? CancelledAt,
    IReadOnlyList<EstimateLineDto> Lines);

public sealed record EstimateListResponse(
    IReadOnlyList<EstimateDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
