namespace QuickBooksClone.Api.Contracts.Sync;

public sealed record SyncOverviewDto(
    DateTimeOffset GeneratedAt,
    IReadOnlyList<SyncDocumentTypeSummaryDto> DocumentTypes,
    int TotalDocuments,
    int LocalOnlyCount,
    int PendingSyncCount,
    int SyncedCount,
    int SyncFailedCount);

public sealed record SyncDocumentTypeSummaryDto(
    string DocumentType,
    int TotalDocuments,
    int LocalOnlyCount,
    int PendingSyncCount,
    int SyncedCount,
    int SyncFailedCount,
    DateTimeOffset? LastModifiedAt);
