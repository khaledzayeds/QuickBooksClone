namespace QuickBooksClone.Api.Contracts.Calendar;

public sealed record CalendarSummaryDto(
    DateOnly FromDate,
    DateOnly ToDate,
    DateOnly Today,
    int TotalEvents,
    int OverdueCount,
    int DueTodayCount,
    int UpcomingCount,
    decimal TotalReceivableDue,
    decimal TotalPayableDue,
    IReadOnlyList<CalendarEventDto> Events);

public sealed record CalendarEventDto(
    Guid Id,
    string SourceType,
    Guid SourceId,
    string DocumentNumber,
    string Title,
    string PartyName,
    DateOnly DocumentDate,
    DateOnly DueDate,
    decimal AmountDue,
    string Status,
    string Severity,
    string Route);
