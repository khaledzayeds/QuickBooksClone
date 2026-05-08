namespace QuickBooksClone.Api.Contracts.Payroll;

public sealed record PayrollSummaryReportDto(
    DateOnly? FromDate,
    DateOnly? ToDate,
    int RunCount,
    int EmployeeCount,
    decimal TotalGrossPay,
    decimal TotalDeductions,
    decimal TotalNetPay,
    IReadOnlyList<PayrollSummaryByStatusDto> ByStatus,
    IReadOnlyList<PayrollSummaryByEmployeeDto> ByEmployee,
    IReadOnlyList<PayrollSummaryRunDto> Runs);

public sealed record PayrollSummaryByStatusDto(
    string Status,
    int RunCount,
    decimal GrossPay,
    decimal Deductions,
    decimal NetPay);

public sealed record PayrollSummaryByEmployeeDto(
    Guid EmployeeId,
    string EmployeeNumber,
    string EmployeeName,
    decimal GrossPay,
    decimal Deductions,
    decimal NetPay);

public sealed record PayrollSummaryRunDto(
    Guid Id,
    string RunNumber,
    DateOnly PeriodStart,
    DateOnly PeriodEnd,
    DateOnly PayDate,
    string Status,
    string Currency,
    int EmployeeCount,
    decimal GrossPay,
    decimal Deductions,
    decimal NetPay,
    Guid? JournalEntryId);
