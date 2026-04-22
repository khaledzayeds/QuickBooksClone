namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record ProfitAndLossSectionDto(
    string Key,
    string Title,
    IReadOnlyList<ProfitAndLossRowDto> Items,
    decimal Total);
