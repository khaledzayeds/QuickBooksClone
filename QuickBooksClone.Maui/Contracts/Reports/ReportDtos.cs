namespace QuickBooksClone.Maui.Contracts.Reports;

public sealed record TrialBalanceReportDto(
    DateOnly AsOfDate,
    IReadOnlyList<TrialBalanceRowDto> Items,
    decimal TotalDebit,
    decimal TotalCredit);

public sealed record TrialBalanceRowDto(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    string AccountType,
    decimal TotalDebit,
    decimal TotalCredit,
    decimal ClosingDebit,
    decimal ClosingCredit);

public sealed record BalanceSheetReportDto(
    DateOnly AsOfDate,
    IReadOnlyList<BalanceSheetSectionDto> Sections,
    decimal TotalAssets,
    decimal TotalLiabilities,
    decimal TotalEquity,
    decimal TotalLiabilitiesAndEquity);

public sealed record BalanceSheetSectionDto(
    string Key,
    string Title,
    IReadOnlyList<BalanceSheetRowDto> Items,
    decimal Total);

public sealed record BalanceSheetRowDto(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    string AccountType,
    decimal Amount);

public sealed record ProfitAndLossReportDto(
    DateOnly FromDate,
    DateOnly ToDate,
    IReadOnlyList<ProfitAndLossSectionDto> Sections,
    decimal TotalIncome,
    decimal TotalCostOfGoodsSold,
    decimal GrossProfit,
    decimal TotalExpenses,
    decimal NetProfit);

public sealed record ProfitAndLossSectionDto(
    string Key,
    string Title,
    IReadOnlyList<ProfitAndLossRowDto> Items,
    decimal Total);

public sealed record ProfitAndLossRowDto(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    string AccountType,
    decimal Amount);

public sealed record AccountsReceivableAgingReportDto(
    DateOnly AsOfDate,
    IReadOnlyList<AccountsReceivableAgingRowDto> Items,
    decimal Current,
    decimal Days1To30,
    decimal Days31To60,
    decimal Days61To90,
    decimal Over90,
    decimal Total);

public sealed record AccountsReceivableAgingRowDto(
    Guid CustomerId,
    string CustomerName,
    string Currency,
    decimal Current,
    decimal Days1To30,
    decimal Days31To60,
    decimal Days61To90,
    decimal Over90,
    decimal Total,
    decimal CreditBalance,
    int OpenInvoiceCount);

public sealed record AccountsPayableAgingReportDto(
    DateOnly AsOfDate,
    IReadOnlyList<AccountsPayableAgingRowDto> Items,
    decimal Current,
    decimal Days1To30,
    decimal Days31To60,
    decimal Days61To90,
    decimal Over90,
    decimal Total);

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

public sealed record InventoryValuationReportDto(
    DateOnly FromDate,
    DateOnly ToDate,
    IReadOnlyList<InventoryValuationRowDto> Items,
    decimal TotalOpeningQuantity,
    decimal TotalQuantityIn,
    decimal TotalQuantityOut,
    decimal TotalClosingQuantity,
    decimal TotalOpeningValue,
    decimal TotalQuantityInValue,
    decimal TotalQuantityOutValue,
    decimal TotalClosingValue);

public sealed record InventoryValuationRowDto(
    Guid ItemId,
    string ItemName,
    string? Sku,
    string Unit,
    decimal UnitCost,
    decimal OpeningQuantity,
    decimal QuantityIn,
    decimal QuantityOut,
    decimal ClosingQuantity,
    decimal OpeningValue,
    decimal QuantityInValue,
    decimal QuantityOutValue,
    decimal ClosingValue);
