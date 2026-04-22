namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record BalanceSheetSectionDto(
    string Key,
    string Title,
    IReadOnlyList<BalanceSheetRowDto> Items,
    decimal Total);
