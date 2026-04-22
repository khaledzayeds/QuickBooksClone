namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record AccountsPayableAgingRowDto(
    Guid VendorId,
    string VendorName,
    string Currency,
    decimal Current,
    decimal Days1To30,
    decimal Days31To60,
    decimal Days61To90,
    decimal Over90,
    decimal Total,
    decimal CreditBalance,
    int OpenBillCount);
