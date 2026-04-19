using Microsoft.AspNetCore.Http;

namespace QuickBooksClone.Api.Contracts.Database;

public sealed class ImportDatabaseBackupRequest
{
    public IFormFile? File { get; init; }
    public string? Label { get; init; }
    public string? RequestedBy { get; init; }
    public string? Reason { get; init; }
}
