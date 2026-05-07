namespace QuickBooksClone.Api.Contracts.Payroll;

public sealed record PayrollRunListResponse(
    IReadOnlyList<PayrollRunSummaryDto> Items,
    int TotalCount,
    decimal TotalGrossPay,
    decimal TotalDeductions,
    decimal TotalNetPay);

public sealed record PayrollRunSummaryDto(
    Guid Id,
    string RunNumber,
    DateOnly PeriodStart,
    DateOnly PeriodEnd,
    DateOnly PayDate,
    string PaySchedule,
    string Currency,
    string Status,
    Guid? JournalEntryId,
    int EmployeeCount,
    decimal TotalGrossPay,
    decimal TotalDeductions,
    decimal TotalNetPay,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);

public sealed record PayrollRunDetailsDto(
    Guid Id,
    string RunNumber,
    DateOnly PeriodStart,
    DateOnly PeriodEnd,
    DateOnly PayDate,
    string PaySchedule,
    string Currency,
    string Status,
    Guid? JournalEntryId,
    decimal RegularHoursPerEmployee,
    decimal OvertimeHoursPerEmployee,
    decimal TaxWithholdingRate,
    int EmployeeCount,
    decimal TotalGrossPay,
    decimal TotalDeductions,
    decimal TotalNetPay,
    IReadOnlyList<PayrollRunLineDto> Lines,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);

public sealed record PayrollRunLineDto(
    Guid Id,
    Guid EmployeeId,
    string EmployeeNumber,
    string EmployeeName,
    decimal RegularHours,
    decimal OvertimeHours,
    decimal HourlyRate,
    decimal GrossPay,
    decimal Deductions,
    decimal NetPay);

public sealed record CreatePayrollRunRequest(
    DateOnly PeriodStart,
    DateOnly PeriodEnd,
    DateOnly PayDate,
    string PaySchedule,
    decimal RegularHoursPerEmployee,
    decimal OvertimeHoursPerEmployee,
    decimal TaxWithholdingRate);
