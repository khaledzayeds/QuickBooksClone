namespace QuickBooksClone.Core.Common;

public enum SyncStatus
{
    LocalOnly = 0,
    PendingSync = 1,
    Synced = 2,
    SyncFailed = 3
}
