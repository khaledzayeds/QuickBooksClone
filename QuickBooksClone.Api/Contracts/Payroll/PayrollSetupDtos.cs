namespace QuickBooksClone.Api.Contracts.Payroll;

public sealed record PayrollSetupDto(
    PayrollSettingsDto Settings,
    IReadOnlyList<PayrollEmployeeDto> Employees,
    IReadOnlyList<PayrollEarningTypeDto> EarningTypes,
    IReadOnlyList<PayrollDeductionTypeDto> DeductionTypes,
    int ActiveEmployeeCount,
    int PayScheduleCount);

public sealed record PayrollSettingsDto(
    Guid Id,
    string DefaultPaySchedule,
    string DefaultCurrency,
    int WorkWeekHours,
    bool IsPayrollEnabled,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);

public sealed record UpdatePayrollSettingsRequest(
    string DefaultPaySchedule,
    string DefaultCurrency,
    int WorkWeekHours,
    bool IsPayrollEnabled);

public sealed record PayrollEmployeeDto(
    Guid Id,
    string EmployeeNumber,
    string DisplayName,
    string? Email,
    string PaySchedule,
    decimal DefaultHourlyRate,
    string Currency,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);

public sealed record CreatePayrollEmployeeRequest(
    string EmployeeNumber,
    string DisplayName,
    string? Email,
    string PaySchedule,
    decimal DefaultHourlyRate,
    string Currency,
    bool IsActive);

public sealed record PayrollEarningTypeDto(
    Guid Id,
    string Code,
    string Name,
    bool IsTaxable,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);

public sealed record CreatePayrollEarningTypeRequest(
    string Code,
    string Name,
    bool IsTaxable,
    bool IsActive);

public sealed record PayrollDeductionTypeDto(
    Guid Id,
    string Code,
    string Name,
    bool IsPreTax,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);

public sealed record CreatePayrollDeductionTypeRequest(
    string Code,
    string Name,
    bool IsPreTax,
    bool IsActive);
