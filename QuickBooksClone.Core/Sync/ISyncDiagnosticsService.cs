using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Sync;

public interface ISyncDiagnosticsService
{
    Task<SyncOverview> GetOverviewAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<SyncDocumentSnapshot>> ListDocumentsAsync(
        SyncStatus? status = null,
        string? documentType = null,
        int take = 200,
        CancellationToken cancellationToken = default);
    Task<bool> MarkPendingAsync(string documentType, Guid id, CancellationToken cancellationToken = default);
}

public sealed record SyncOverview(
    DateTimeOffset GeneratedAt,
    IReadOnlyList<SyncDocumentTypeSummary> DocumentTypes,
    int TotalDocuments,
    int LocalOnlyCount,
    int PendingSyncCount,
    int SyncedCount,
    int SyncFailedCount);

public sealed record SyncDocumentTypeSummary(
    string DocumentType,
    int TotalDocuments,
    int LocalOnlyCount,
    int PendingSyncCount,
    int SyncedCount,
    int SyncFailedCount,
    DateTimeOffset? LastModifiedAt);

public sealed record SyncDocumentSnapshot(
    string DocumentType,
    Guid Id,
    string DocumentNo,
    string DeviceId,
    SyncStatus SyncStatus,
    long SyncVersion,
    DateTimeOffset CreatedAt,
    DateTimeOffset LastModifiedAt,
    DateTimeOffset? LastSyncAt,
    string? SyncError);
