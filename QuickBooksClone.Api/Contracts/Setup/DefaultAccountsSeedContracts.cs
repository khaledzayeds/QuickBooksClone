namespace QuickBooksClone.Api.Contracts.Setup;

public sealed record DefaultAccountsSeedResponse(
    int CreatedCount,
    int SkippedCount,
    IReadOnlyList<string> CreatedCodes,
    IReadOnlyList<string> SkippedCodes);
