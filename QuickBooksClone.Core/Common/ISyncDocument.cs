namespace QuickBooksClone.Core.Common;

public interface ISyncDocument
{
    string DeviceId { get; }
    string DocumentNo { get; }
    SyncStatus SyncStatus { get; }
    DateTimeOffset LastModifiedAt { get; }
    long SyncVersion { get; }
    DateTimeOffset? LastSyncAt { get; }
    string? SyncError { get; }
}
