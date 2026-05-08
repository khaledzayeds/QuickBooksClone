using QuickBooksClone.Core.TimeTracking;

namespace QuickBooksClone.Api.Contracts.TimeTracking;

public sealed record TimeEntrySummaryReportDto(
    DateOnly? FromDate,
    DateOnly? ToDate,
    int EntryCount,
    decimal TotalHours,
    decimal BillableHours,
    decimal NonBillableHours,
    decimal BillableNotInvoicedHours,
    IReadOnlyList<TimeEntrySummaryByStatusDto> ByStatus,
    IReadOnlyList<TimeEntrySummaryByPersonDto> ByPerson,
    IReadOnlyList<TimeEntrySummaryByCustomerDto> ByCustomer,
    IReadOnlyList<BillableTimeQueueItemDto> BillableQueue);

public sealed record TimeEntrySummaryByStatusDto(
    TimeEntryStatus Status,
    int EntryCount,
    decimal TotalHours,
    decimal BillableHours);

public sealed record TimeEntrySummaryByPersonDto(
    string PersonName,
    int EntryCount,
    decimal TotalHours,
    decimal BillableHours,
    decimal InvoicedHours);

public sealed record TimeEntrySummaryByCustomerDto(
    Guid? CustomerId,
    string CustomerName,
    int EntryCount,
    decimal TotalHours,
    decimal BillableHours,
    decimal BillableNotInvoicedHours);

public sealed record BillableTimeQueueItemDto(
    Guid Id,
    DateOnly WorkDate,
    string PersonName,
    decimal Hours,
    string Activity,
    Guid CustomerId,
    string CustomerName,
    Guid ServiceItemId,
    string ServiceItemName,
    TimeEntryStatus Status);
