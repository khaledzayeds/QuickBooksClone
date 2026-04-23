using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Api.Contracts.Sync;

public sealed record SyncDocumentDto(
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
