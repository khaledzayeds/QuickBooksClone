using QuickBooksClone.Core.TimeTracking;

namespace QuickBooksClone.Api.Contracts.TimeTracking;

public sealed record TimeEntryDto(
    Guid Id,
    DateOnly WorkDate,
    string PersonName,
    decimal Hours,
    string Activity,
    string? Notes,
    Guid? CustomerId,
    string? CustomerName,
    Guid? ServiceItemId,
    string? ServiceItemName,
    bool IsBillable,
    TimeEntryStatus Status,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);

public sealed record TimeEntryListResponse(
    IReadOnlyList<TimeEntryDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    decimal TotalHours,
    decimal BillableHours,
    decimal NonBillableHours);

public sealed record CreateTimeEntryRequest(
    DateOnly WorkDate,
    string PersonName,
    decimal Hours,
    string Activity,
    string? Notes,
    Guid? CustomerId,
    Guid? ServiceItemId,
    bool IsBillable);

public sealed record UpdateTimeEntryRequest(
    DateOnly WorkDate,
    string PersonName,
    decimal Hours,
    string Activity,
    string? Notes,
    Guid? CustomerId,
    Guid? ServiceItemId,
    bool IsBillable);
