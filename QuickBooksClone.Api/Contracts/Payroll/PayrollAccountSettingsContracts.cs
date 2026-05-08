namespace QuickBooksClone.Api.Contracts.Payroll;

public sealed record PayrollAccountSettingsDto(
    Guid SettingsId,
    Guid? PayrollExpenseAccountId,
    string? PayrollExpenseAccountName,
    Guid? PayrollPayableAccountId,
    string? PayrollPayableAccountName,
    Guid? PayrollTaxPayableAccountId,
    string? PayrollTaxPayableAccountName,
    bool IsConfigured);

public sealed record UpdatePayrollAccountSettingsRequest(
    Guid? PayrollExpenseAccountId,
    Guid? PayrollPayableAccountId,
    Guid? PayrollTaxPayableAccountId);
