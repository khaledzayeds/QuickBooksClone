namespace QuickBooksClone.Core.Common;

public abstract class SyncDocumentBase : EntityBase, ISyncDocument
{
    protected SyncDocumentBase()
    {
        DeviceId = "LOCAL";
        DocumentNo = string.Empty;
        SyncStatus = SyncStatus.LocalOnly;
    }

    public string DeviceId { get; private set; }
    public string DocumentNo { get; private set; }
    public SyncStatus SyncStatus { get; private set; }
    public DateTimeOffset? LastSyncAt { get; private set; }
    public string? SyncError { get; private set; }

    public void SetSyncIdentity(string deviceId, string documentNo)
    {
        DeviceId = NormalizeRequired(deviceId, nameof(deviceId)).ToUpperInvariant();
        DocumentNo = NormalizeRequired(documentNo, nameof(documentNo)).ToUpperInvariant();
        SyncStatus = SyncStatus.LocalOnly;
        SyncError = null;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkPendingSync()
    {
        EnsureIdentityAssigned();
        SyncStatus = SyncStatus.PendingSync;
        SyncError = null;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkSynced(DateTimeOffset? syncedAt = null)
    {
        EnsureIdentityAssigned();
        SyncStatus = SyncStatus.Synced;
        LastSyncAt = syncedAt ?? DateTimeOffset.UtcNow;
        SyncError = null;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkSyncFailed(string error)
    {
        EnsureIdentityAssigned();
        SyncStatus = SyncStatus.SyncFailed;
        SyncError = NormalizeRequired(error, nameof(error));
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private void EnsureIdentityAssigned()
    {
        _ = NormalizeRequired(DeviceId, nameof(DeviceId));
        _ = NormalizeRequired(DocumentNo, nameof(DocumentNo));
    }

    private static string NormalizeRequired(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        return value.Trim();
    }
}
