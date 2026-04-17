namespace QuickBooksClone.Core.Accounting;

public sealed record AccountingTransactionSearch(
    string? Search,
    string? SourceEntityType = null,
    Guid? SourceEntityId = null,
    bool IncludeVoided = false,
    int Page = 1,
    int PageSize = 50);
